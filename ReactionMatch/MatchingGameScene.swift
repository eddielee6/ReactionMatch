//
//  GameScene.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 18/01/2016.
//  Copyright (c) 2016 Eddie Lee. All rights reserved.
//

import SpriteKit
import GameKit
import CoreImage

struct MatchingGameSettings {
    enum GameMode {
        case ExactMatch // Match Colour and Shape
        case ColorMatch // Match Colour Only (all squares)
        case ShapeMatch // Match Shape, Ignore Colour
    }
    
    var gameType: GameType = .V2
    var gameMode: GameMode = .ShapeMatch // How accuratly should shapes be matched
    var soundsEnabled = true
    var minNumberOfTargets: Int = 2 // Starting number of targets on screen
    var maxNumberOfTargets: Int = 8 // Cap on how many targets per game
    var newTargetAfterTurn: Int = 5 // Turns between new targets being added
    var newTargetIncrement: Int = 2 // Number of targets to add each increment
}

class MatchingGameScene: SKScene {
    
    private enum NodeStackingOrder: CGFloat {
        case BackgroundImage
        case Target
        case PlayerTarget
        case TimerIndicator
        case Interface
        case GameOverInterface
    }

    var settings: MatchingGameSettings = MatchingGameSettings()
    
    // MARK: Constants
    private let scoreManager = ScoreManager.sharedInstance
    
    private let successAnimationDuration: Double = 0.25 // Time taken to animate to new levels
    private let setupNewGameAnimationDuration: Double = 0.25 // Time taken to animate to game start
    
    private var centerPoint: CGPoint {
        return CGPoint(x: size.width/2, y: size.height/2)
    }
    private let targetDistanceFromCenterPoint: CGFloat = 110 // Distance away from center targets are placed
    private let maxPlayerDistanceFromCenterPoint: CGFloat = 130 // Max distance away from center player can move
    
    
    // MARK: Actions
    private let successSoundAction = SKAction.playSoundFileNamed("success.mp3", waitForCompletion: false)
    private let failSoundAction = SKAction.playSoundFileNamed("fail.mp3", waitForCompletion: false)
    
    
    // MARK: Game State
    private var hasStartedFirstLevel: Bool = false
    private var isPlayingLevel: Bool = false
    private var isGameOver: Bool = false
    
    // MARK: Score
    private var levelsPlayed: Int = 0
    private var timeForCurrentLevel: NSTimeInterval = 0 { didSet { updateTimeIndicator() } }
    private var timeRemainingForCurrentLevel: NSTimeInterval = 0 { didSet { updateTimeIndicator() } }
    private var pointsRemainingForCurrentLevel: Int {
        return Int(ceil((timeRemainingForCurrentLevel / timeForCurrentLevel) * 10))
    }
    
    private var score: Int64 = 0 { didSet { updateScoreLabel(score, oldScore: oldValue) } }
    
    private func updateScoreLabel(score: Int64, oldScore: Int64) {
        // Fade in on first score
        if score > 0 && oldScore <= 0 {
            if let fadeInAction = scoreLabel.userData?.objectForKey("fadeInAction") as? SKAction {
                scoreLabel.runAction(fadeInAction)
            } else {
                let fadeInAction = SKAction.fadeInWithDuration(0.25)
                fadeInAction.timingMode = .EaseIn
                scoreLabel.runAction(fadeInAction)
                
                scoreLabel.userData?.setObject(fadeInAction, forKey: "fadeInAction")
            }
        }
        
        // Fade out when set to 0
        if score <= 0 && oldScore > 0 {
            if let fadeOutAction = scoreLabel.userData?.objectForKey("fadeOutAction") as? SKAction {
                scoreLabel.runAction(fadeOutAction)
            } else {
                let fadeOutAction = SKAction.fadeOutWithDuration(0.25)
                fadeOutAction.timingMode = .EaseIn
                scoreLabel.runAction(fadeOutAction)
                
                scoreLabel.userData?.setObject(fadeOutAction, forKey: "fadeOutAction")
            }
        }
        
        // Pulse when score increases
        if score > oldScore {
            if let pulseAction = scoreLabel.userData?.objectForKey("pulseAction") as? SKAction {
                scoreLabel.runAction(pulseAction)
            } else {
                let growAction = SKAction.scaleBy(1.25, duration: 0.15)
                let pulseAction = SKAction.sequence([
                    growAction,
                    growAction.reversedAction()
                ])
                pulseAction.timingMode = .EaseInEaseOut
                scoreLabel.runAction(pulseAction)
                
                scoreLabel.userData?.setObject(pulseAction, forKey: "pulseAction")
            }
        }
        
        scoreLabel.text = "Score \(score)"
    }
    
    
    // MARK: Game Nodes
    private let gameAreaNode = SKNode()
    
    private let playerNodeName: String = "player"
    private var playerNode: TargetShapeNode? {
        return gameAreaNode.childNodeWithName(playerNodeName) as? TargetShapeNode
    }
    
    private let incorrectTargetNodeName: String = "target-incorrect"
    private var incorrectTargets: [TargetShapeNode] {
        var incorrectTargetNodes = [TargetShapeNode]()
        gameAreaNode.enumerateChildNodesWithName(incorrectTargetNodeName) { node, _ in
            incorrectTargetNodes.append(node as! TargetShapeNode)
        }
        return incorrectTargetNodes
    }

    private let correctTargetNodeName: String = "target-correct"
    private var correctTarget: TargetShapeNode? {
        return gameAreaNode.childNodeWithName(correctTargetNodeName) as? TargetShapeNode
    }
    
    
    // MARK: Hud Nodes
    private let scoreLabel = SKLabelNode()
    
    private let timeIndicator = TimeIndicatorNode()
    
    
    // MARK: Interface Setup
    override func didMoveToView(view: SKView) {
        addChild(gameAreaNode)
        
        setupBackground()
        setupScoreLabel()
        setupTimeIndicator()
        
        startPuzzle()
    }
    
    private func setupBackground() {
        backgroundColor = SKColor.whiteColor()
        let backgroundNode = SKSpriteNode(texture: Textures.getMenuScreenTexture(size))
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.zPosition = NodeStackingOrder.BackgroundImage.rawValue
        gameAreaNode.addChild(backgroundNode)
    }
    
    private func setupTimeIndicator() {
        timeIndicator.indicatorStrokeColor = SKColor(red: 49/255, green: 71/255, blue: 215/255, alpha: 0.75)
        timeIndicator.indicatorStrokeWidth = 4
        timeIndicator.size = CGSizeMake(size.width, size.width)
        timeIndicator.position = centerPoint
        timeIndicator.zPosition = NodeStackingOrder.TimerIndicator.rawValue
        gameAreaNode.addChild(timeIndicator)
    }
    
    private func setupScoreLabel() {
        var scoreLabelPosition: CGPoint {
            let distanceFromGameArea: CGFloat = 100
            return centerPoint + CGPointMake(0, maxPlayerDistanceFromCenterPoint + distanceFromGameArea)
        }
        
        scoreLabel.text = "Score \(score)"
        scoreLabel.alpha = 0
        scoreLabel.horizontalAlignmentMode = .Center
        scoreLabel.fontSize = 45
        scoreLabel.fontColor = SKColor.blackColor()
        scoreLabel.position = scoreLabelPosition
        scoreLabel.zPosition = NodeStackingOrder.Interface.rawValue
        
        gameAreaNode.addChild(scoreLabel)
    }
    
    
    // MARK: Level Setup
    private func startPuzzle() {
        levelsPlayed += 1
        drawPuzzleForLevel(levelsPlayed)
    }
    
    private func getTimeForLevel(level: Int) -> NSTimeInterval {
        let maxTimeForLevel: NSTimeInterval = 1.2 // Starting time allowed for per level
        let minTimeForLevel: NSTimeInterval = 0.4 // Cap on minimum amount of time per level
        
        var timeForLevel = maxTimeForLevel - Double(level / 5) * 0.1
        if timeForLevel < minTimeForLevel {
            timeForLevel = minTimeForLevel
        }
        
        return timeForLevel
    }
    
    private func getNewPlayerNode() -> TargetShapeNode {
        let newPlayer = settings.gameMode == .ColorMatch ? TargetShapeNode(targetShape: TargetShape.Square) : TargetShapeNode.randomShapeNode()
        newPlayer.name = playerNodeName
        newPlayer.position = centerPoint
        newPlayer.alpha = 0
        newPlayer.setScale(0)
        newPlayer.zPosition = NodeStackingOrder.PlayerTarget.rawValue
        
        let showAction = SKAction.group([
            SKAction.fadeInWithDuration(setupNewGameAnimationDuration),
            SKAction.scaleTo(1.0, duration: setupNewGameAnimationDuration)
        ])
        showAction.timingMode = .EaseIn
        
        newPlayer.runAction(showAction)
        
        return newPlayer
    }
    
    private func drawPuzzleForLevel(level: Int) {
        // Create Player
        let newPlayer = getNewPlayerNode()
        gameAreaNode.addChild(newPlayer)
        
        // Create Targets
        let numberOfTargets = getNumberOfTargetsForLevelsPlayed(levelsPlayed)
        setupTargetsFor(newPlayer, numberOfTargets: numberOfTargets)
        
        // Set Timer
        timeForCurrentLevel = getTimeForLevel(level)
        timeRemainingForCurrentLevel = timeForCurrentLevel
        
        timeIndicator.percent = 0
        timeIndicator.runAction(SKAction.fadeInWithDuration(setupNewGameAnimationDuration))
        
        runAction(SKAction.sequence([
            SKAction.waitForDuration(setupNewGameAnimationDuration * 1.5),
            SKAction.runBlock({
                if self.hasStartedFirstLevel {
                    self.startLevel()
                } else {
                    self.showGameGuidance()
                }
            })
        ]))
    }
    
    private func startLevel() {
        isPlayingLevel = true
    }
    
    private func getNumberOfTargetsForLevelsPlayed(levelsPlayed: Int) -> Int {
        var bonusTargets = 0
        if settings.newTargetIncrement > 0 && settings.newTargetAfterTurn > 0 {
            bonusTargets = Int(floor(Double(levelsPlayed / settings.newTargetAfterTurn))) * settings.newTargetIncrement
        }
        var numberOfTargets = settings.minNumberOfTargets + bonusTargets
        numberOfTargets = numberOfTargets > settings.maxNumberOfTargets ? settings.maxNumberOfTargets : numberOfTargets
        return numberOfTargets
    }
    
    private func setupTargetsFor(playerTargetNode: TargetShapeNode, numberOfTargets: Int) {
        
        // Get new target positions
        let targetPositions = calculatePositionForTargets(quantity: numberOfTargets)
        
        // Pick winning target
        let random = GKRandomDistribution(lowestValue: 0, highestValue: targetPositions.count - 1)
        let winningTargetIndex = random.nextInt()
        
        // Create targets
        var newTargets = [TargetShapeNode]()
        for (i, position) in targetPositions.enumerate() {
            
            let targetNode = getTargetShapeNodeFor(playerTargetNode.targetColor, playerNodeShape: playerTargetNode.targetShape, isWinning: i == winningTargetIndex)
            
            // Invisible in center
            targetNode.alpha = 0
            targetNode.setScale(0)
            targetNode.position = centerPoint
            targetNode.zPosition = NodeStackingOrder.Target.rawValue
            
            // Animate
            let showAnimation = SKAction.group([
                SKAction.fadeInWithDuration(setupNewGameAnimationDuration),
                SKAction.moveTo(position, duration: setupNewGameAnimationDuration),
                SKAction.scaleTo(1.0, duration: setupNewGameAnimationDuration)
            ])
            showAnimation.timingMode = .EaseIn
            targetNode.runAction(showAnimation)
            
            newTargets.append(targetNode)
        }
        
        // Add targets to screen
        for newTarget in newTargets {
            gameAreaNode.addChild(newTarget)
        }
    }
    
    private func getTargetShapeNodeFor(playerNodeColor: TargetColor, playerNodeShape: TargetShape, isWinning: Bool) -> TargetShapeNode {
        var targetColor: TargetColor
        var targetShape: TargetShape
        
        if isWinning {
            switch settings.gameMode {
            case .ColorMatch:
                targetColor = playerNodeColor
                targetShape = TargetShape.Square
            case .ShapeMatch:
                targetColor = TargetColor.random(not: playerNodeColor)
                targetShape = playerNodeShape
            case .ExactMatch:
                targetColor = playerNodeColor
                targetShape = playerNodeShape
            }
        } else {
            switch settings.gameMode {
            case .ColorMatch:
                targetColor = TargetColor.random(not: playerNodeColor)
                targetShape = TargetShape.Square
            case .ShapeMatch:
                targetColor = TargetColor.random()
                targetShape = TargetShape.random(not: playerNodeShape)
            case .ExactMatch:
                targetColor = TargetColor.random(not: playerNodeColor)
                targetShape = TargetShape.random(not: playerNodeShape)
            }
        }
        
        let targetNode = TargetShapeNode(targetColor: targetColor, targetShape: targetShape)
        
        if isWinning {
            targetNode.name = correctTargetNodeName
        } else {
            targetNode.name = incorrectTargetNodeName
        }
        
        return targetNode
    }
    
    private func calculatePositionForTargets(quantity numberOfTargets: Int) -> [CGPoint] {
        var targetPositions = [CGPoint]()
        
        let degreesBetweenTargets = 360 / numberOfTargets
        
        for degrees in 0.stride(to: 360, by: degreesBetweenTargets) {
            let radians = Double(degrees) * M_PI / 180.0
            
            let targetX = CGFloat(cos(radians)) * targetDistanceFromCenterPoint + centerPoint.x;
            let targetY = CGFloat(sin(radians)) * targetDistanceFromCenterPoint + centerPoint.y;
            
            targetPositions.append(CGPoint(x: targetX, y: targetY))
        }
        
        return targetPositions
    }
    
    
    
    // MARK: Gameplay
    private var lastUpdateTime: NSTimeInterval = 0
    override func update(currentTime: NSTimeInterval) {
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime
        
        if isPlayingLevel {
            updateLevelWithDeltaTime(deltaTime)
        }
    }
    
    private func updateLevelWithDeltaTime(deltaTime: NSTimeInterval) {
        timeRemainingForCurrentLevel -= deltaTime
        
        if timeRemainingForCurrentLevel <= 0 {
            let collisionState = getCollisionStateForPlayer(playerNode!, withCorrectTarget: correctTarget!, andIncorrectTargets: incorrectTargets)
            if collisionState == .CorrectTarget {
                player(playerNode!, didSelectCorrectTarget: correctTarget!, withIncorrectTargets: incorrectTargets)
            } else {
                timeIndicator.percent = 100
                gameOver("Times Up")
            }
        }
    }
    
    private func updateTimeIndicator() {
        timeIndicator.percent = ((timeForCurrentLevel - timeRemainingForCurrentLevel) / timeForCurrentLevel) * 100
    }
    
    private func playSound(soundAction: SKAction) {
        if settings.soundsEnabled {
            runAction(soundAction)
        }
    }
    
    private func player(playerNode: TargetShapeNode, didSelectCorrectTarget correctTarget: TargetShapeNode, withIncorrectTargets incorrectTargets: [TargetShapeNode]) {
        isPlayingLevel = false
        
        // Update score
        let pointsGained = pointsRemainingForCurrentLevel
        score += pointsGained
        
        playSound(successSoundAction)
        
        // Display points gained
        correctTarget.setPointsGained(pointsGained)
        
        // Grow winning target
        let growAction = SKAction.scaleTo(2, duration: successAnimationDuration)
        growAction.timingMode = .EaseIn
        correctTarget.runAction(SKAction.sequence([
            growAction,
            SKAction.removeFromParent()
        ]))
        
        // Fade out incorrect targets
        let shrinkAction = SKAction.scaleTo(1, duration: successAnimationDuration)
        shrinkAction.timingMode = .EaseIn
        incorrectTargets.forEach({
            $0.runAction(SKAction.sequence([
                shrinkAction,
                SKAction.removeFromParent()
            ]))
        })
        
        // Fade out timer
        timeIndicator.runAction(SKAction.fadeOutWithDuration(successAnimationDuration))
        
        // Animate removal of current player node
        playerNode.runAction(SKAction.sequence([
            SKAction.group([
                SKAction.fadeInWithDuration(successAnimationDuration),
                SKAction.scaleTo(0, duration: successAnimationDuration)
            ]),
            SKAction.removeFromParent(),
            
            // Draw new puzzle
            SKAction.runBlock({
                self.startPuzzle()
            })
        ]))
    }
    
    private func playerDidSelectIncorrectTarget() {
        gameOver("Incorrect")
    }
    
    private func returnPlayerToCenterPoint(playerNode: TargetShapeNode) {
        let returnAction = SKAction.moveTo(centerPoint, duration: NSTimeInterval(0.15))
        returnAction.timingMode = .EaseInEaseOut
        playerNode.runAction(returnAction, withKey: "Return")
    }
    
    private func movePlayerNode(playerNode: TargetShapeNode, withVector vector: CGPoint) {
        // Remove position actions
        removeGameGuidance()
        playerNode.removeActionForKey("Return")
        
        var newPlayerNodePosition = playerNode.position + vector
        
        // Bounds check player
        let distance = (newPlayerNodePosition - centerPoint).length()
        if distance > maxPlayerDistanceFromCenterPoint {
            let offset = newPlayerNodePosition - centerPoint
            let direction = offset.normalized()
            let cappedPosition = (direction * maxPlayerDistanceFromCenterPoint) + centerPoint
            newPlayerNodePosition = cappedPosition
        }
        
        // Move to new position
        playerNode.position = newPlayerNodePosition
    }
    
    private enum PlayerCollisionState {
        case CorrectTarget
        case IncorrectTarget
        case NoTarget
    }
    
    private func getCollisionStateForPlayer(playerNode: TargetShapeNode, withCorrectTarget correctTarget: TargetShapeNode, andIncorrectTargets incorrectTargets: [TargetShapeNode]) -> PlayerCollisionState {
        
        // Check for correct selection
        if playerNode.intersectsNode(correctTarget) {
            return .CorrectTarget
        }
        
        // Check for incorrect selection
        let playerIntersectsIncorrectTarget = incorrectTargets
            .map({ playerNode.intersectsNode($0) })
            .reduce(false, combine: { $0 || $1 })
        
        if playerIntersectsIncorrectTarget {
            return .IncorrectTarget
        }
        
        return .NoTarget
    }
    
    private func player(playerNode: TargetShapeNode, didEndMoveWithCorrectTarget correctTarget: TargetShapeNode, andIncorrectTargets incorrectTargets: [TargetShapeNode]) {
        let collisionState = getCollisionStateForPlayer(playerNode, withCorrectTarget: correctTarget, andIncorrectTargets: incorrectTargets)
        switch(collisionState) {
        case .CorrectTarget:
            player(playerNode, didSelectCorrectTarget: correctTarget, withIncorrectTargets: incorrectTargets)
        case .IncorrectTarget:
            playerDidSelectIncorrectTarget()
        case .NoTarget:
            returnPlayerToCenterPoint(playerNode)
        }
    }
}



// MARK: Game Over
extension MatchingGameScene {
    private func gameOver(reason: String) {
        isPlayingLevel = false
        isGameOver = true
        
        print("Game Over: \(reason)")
        
        playSound(failSoundAction)
        
        let currentHighScore = scoreManager.getHighScoreForGameType(settings.gameType)
        scoreManager.recordNewScore(score, forGameType: settings.gameType)
        
        runAction(SKAction.sequence([
            SKAction.waitForDuration(0.1),
            SKAction.runBlock({ [ unowned scope = self ] in
                scope.blurScene()
            }),
            SKAction.waitForDuration(0.25),
            SKAction.runBlock({ [ unowned scope = self ] in
                scope.showHighScoreLabel(scope.score, isHighScore: scope.score > currentHighScore)
                scope.showNewGameButton()
                scope.showReturnToMenuButton()
            })
        ]))
    }
    
    private func blurScene() {
        let blurNode = SKEffectNode()
        blurNode.filter = CIFilter(name: "CIGaussianBlur", withInputParameters: ["inputRadius": 10.0])!
        blurNode.shouldRasterize = true
        blurNode.runAction(SKAction.fadeAlphaTo(0.45, duration: 0.5))
        
        addChild(blurNode)
        
        gameAreaNode.removeFromParent()
        blurNode.addChild(gameAreaNode)
    }
    
    private func showHighScoreLabel(score: Int64, isHighScore: Bool) {
        let scoreLabel = SKLabelNode()
        scoreLabel.text = isHighScore ? "New High Score" : "Score \(score)"
        scoreLabel.alpha = 0
        scoreLabel.horizontalAlignmentMode = .Center
        scoreLabel.fontSize = 45
        scoreLabel.fontColor = SKColor.blackColor()
        scoreLabel.position = centerPoint + CGPoint(x: 0, y: 175)
        scoreLabel.zPosition = NodeStackingOrder.Interface.rawValue
        
        scoreLabel.runAction(SKAction.fadeInWithDuration(0.5))
        addChild(scoreLabel)
        
        let highScoreLabel = SKLabelNode()
        highScoreLabel.text = "High Score \(scoreManager.getHighScoreForGameType(settings.gameType))"
        highScoreLabel.alpha = 0
        highScoreLabel.horizontalAlignmentMode = .Center
        highScoreLabel.fontSize = 30
        highScoreLabel.fontColor = SKColor.blackColor()
        highScoreLabel.position = centerPoint + CGPoint(x: 0, y: 135)
        highScoreLabel.zPosition = NodeStackingOrder.Interface.rawValue
        
        highScoreLabel.runAction(SKAction.fadeInWithDuration(0.5))
        addChild(highScoreLabel)
    }
    
    private func showNewGameButton() {
        let playAgainLabel = SKLabelNode()
        playAgainLabel.text = "Tap to Play Again"
        playAgainLabel.fontSize = 35
        playAgainLabel.fontColor = SKColor.blackColor()
        playAgainLabel.verticalAlignmentMode = .Center
        playAgainLabel.alpha = 0
        playAgainLabel.position = centerPoint
        playAgainLabel.zPosition = NodeStackingOrder.GameOverInterface.rawValue
        addChild(playAgainLabel)
        
        playAgainLabel.runAction(SKAction.group([
            SKAction.fadeInWithDuration(0.5),
            SKAction.repeatActionForever(SKAction.sequence([
                SKAction.scaleBy(1.2, duration: 0.4),
                SKAction.scaleBy(0.8333, duration: 0.4)
            ]))
        ]))
    }
    
    private func restartGame() {
        let newGameScene = MatchingGameScene(size: self.size)
        newGameScene.settings = settings
        self.view?.presentScene(newGameScene)
    }
}



// MARK: Game Guidance
extension MatchingGameScene {
    private func showGameGuidance() {
        showGuidanceLabel()
        playHintAnimationForPlayer(playerNode!, toNode: correctTarget!)
    }
    
    private func removeGameGuidance() {
        playerNode?.removeActionForKey("Hint")
        if let guidanceLabel = gameAreaNode.childNodeWithName("guidance-label") {
            guidanceLabel.removeFromParent()
        }
    }
    
    private func playHintAnimationForPlayer(playerNode: TargetShapeNode, toNode targetNode: TargetShapeNode) {
        let hintPoint = (centerPoint + targetNode.position) / 2
        
        let hintAction = SKAction.sequence([
            SKAction.moveTo(hintPoint, duration: 0.3),
            SKAction.moveTo(centerPoint, duration: 0.3)])
        hintAction.timingMode = .EaseInEaseOut
        
        playerNode.runAction(SKAction.sequence([
            SKAction.waitForDuration(0.5),
            SKAction.repeatActionForever(SKAction.sequence([
                SKAction.waitForDuration(1.25),
                hintAction
            ]))
        ]), withKey: "Hint")
    }
    
    private func showGuidanceLabel() {
        var guidanceLabelPosition: CGPoint {
            let distanceFromGameArea: CGFloat = 60
            return centerPoint + CGPointMake(0, maxPlayerDistanceFromCenterPoint + distanceFromGameArea)
        }
        
        let guidanceLabel = SKLabelNode()
        guidanceLabel.text = settings.gameMode == .ColorMatch ? "Match the Colour" : "Match the Shape"
        guidanceLabel.horizontalAlignmentMode = .Center
        guidanceLabel.fontSize = 35
        guidanceLabel.fontColor = SKColor.blackColor()
        guidanceLabel.position = guidanceLabelPosition
        guidanceLabel.zPosition = NodeStackingOrder.Interface.rawValue
        guidanceLabel.name = "guidance-label"
        
        // Blink label
        guidanceLabel.runAction(SKAction.repeatActionForever(SKAction.sequence([
            SKAction.waitForDuration(0.25),
            SKAction.fadeAlphaTo(0.75, duration: 0.5),
            SKAction.fadeAlphaTo(1, duration: 0.5)
        ])))
        
        gameAreaNode.addChild(guidanceLabel)
    }
}



// MARK: Handle input
extension MatchingGameScene {
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if isGameOver {
            restartGame()
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.locationInNode(self)
        let previousLocation = touch.previousLocationInNode(self)
        
        // Start initial game after initial move
        if !hasStartedFirstLevel {
            hasStartedFirstLevel = true
            startLevel()
        }
        
        if isPlayingLevel {
            movePlayerNode(playerNode!, withVector: touchLocation - previousLocation)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard isPlayingLevel else {
            return
        }
        
        player(playerNode!, didEndMoveWithCorrectTarget: correctTarget!, andIncorrectTargets: incorrectTargets)
    }
}