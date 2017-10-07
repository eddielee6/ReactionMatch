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
        case exactMatch // Match Colour and Shape
        case colorMatch // Match Colour Only (all squares)
        case shapeMatch // Match Shape, Ignore Colour
    }

    var gameType: GameType = .v2Mode
    var gameMode: GameMode = .shapeMatch // How accuratly should shapes be matched
    var soundsEnabled = true
    var minNumberOfTargets: Int = 2 // Starting number of targets on screen
    var maxNumberOfTargets: Int = 8 // Cap on how many targets per game
    var newTargetAfterTurn: Int = 5 // Turns between new targets being added
    var newTargetIncrement: Int = 2 // Number of targets to add each increment
}

// swiftlint:disable:next type_body_length
class MatchingGameScene: SKScene {

    fileprivate enum NodeStackingOrder: CGFloat {
        case backgroundImage
        case timerIndicator
        case target
        case playerTarget
        case effects
        case interface
        case gameOverInterface
    }

    var settings: MatchingGameSettings = MatchingGameSettings()

    // MARK: Constants
    fileprivate let scoreManager = ScoreManager.sharedInstance

    fileprivate var currentHighScore: Int64 {
        return scoreManager.getHighScoreForGameType(settings.gameType)
    }

    fileprivate let successAnimationDuration: Double = 0.25 // Time taken to animate to new levels
    fileprivate let setupNewGameAnimationDuration: Double = 0.25 // Time taken to animate to game start

    fileprivate var centerPoint: CGPoint {
        return CGPoint(x: size.width/2, y: size.height/2)
    }
    fileprivate let targetDistanceFromCenterPoint: CGFloat = 110 // Distance away from center targets are placed
    fileprivate let maxPlayerDistanceFromCenterPoint: CGFloat = 130 // Max distance away from center player can move
    fileprivate var targetSize: CGSize {
        let targetSizeCap: CGFloat = 40
        let desiredDimention = size.width/9.37
        let dimention = desiredDimention < targetSizeCap ? desiredDimention : targetSizeCap
        return CGSize(width: dimention, height: dimention)
    }
    fileprivate var timeIndicatorDiamiter: CGFloat {
        let desiredTimeIndicatorDiamiter: CGFloat = 375.0
        let timeIndicatorDiamiterCap: CGFloat = size.width * 0.975

        return desiredTimeIndicatorDiamiter < timeIndicatorDiamiterCap
            ? desiredTimeIndicatorDiamiter : timeIndicatorDiamiterCap
    }
    fileprivate var topLabelPosition: CGPoint {
        let timeIndicatorRadius = timeIndicatorDiamiter / 2
        let freeSpace = size.height/2 - timeIndicatorRadius
        return centerPoint + CGPoint(x: 0, y: timeIndicatorRadius + (freeSpace/2))
    }

    // MARK: Actions
    fileprivate let successSoundAction = SKAction.playSoundFileNamed("success.mp3", waitForCompletion: false)
    fileprivate let failSoundAction = SKAction.playSoundFileNamed("fail.mp3", waitForCompletion: false)

    // MARK: Game State
    fileprivate var hasStartedFirstLevel: Bool = false
    fileprivate var isPlayingLevel: Bool = false
    fileprivate var isGameOver: Bool = false

    // MARK: Score
    fileprivate var levelsPlayed: Int = 0
    fileprivate var timeForCurrentLevel: TimeInterval = 0 { didSet { updateTimeIndicator() } }
    fileprivate var timeRemainingForCurrentLevel: TimeInterval = 0 { didSet { updateTimeIndicator() } }
    fileprivate var pointsRemainingForCurrentLevel: Int64 {
        return Int64(ceil((timeRemainingForCurrentLevel / timeForCurrentLevel) * 10))
    }

    fileprivate var hasCelebratedHighScore: Bool = false

    fileprivate var score: Int64 = 0 {
        didSet {
            updateScoreLabel(score, oldScore: oldValue)
            checkForNewHighScore(score)
        }
    }

    fileprivate func checkForNewHighScore(_ score: Int64) {
        guard currentHighScore > 0 && !hasCelebratedHighScore else {
            return
        }

        if score > currentHighScore {
            celebrateHighScore()
        }
    }

    fileprivate func celebrateHighScore() {
        hasCelebratedHighScore = true
        let blobEmiter = SKEmitterNode(fileNamed: "Confetti.sks")!
        let labelWidth = scoreLabel.calculateAccumulatedFrame().width
        blobEmiter.particlePositionRange = CGVector(dx: labelWidth, dy: 0)
        blobEmiter.position = scoreLabel.position
        blobEmiter.zPosition = NodeStackingOrder.effects.rawValue
        addChild(blobEmiter)
    }

    fileprivate func updateScoreLabel(_ score: Int64, oldScore: Int64) {
        // Fade in on first score
        if score > 0 && oldScore <= 0 {
            if let fadeInAction = scoreLabel.userData?.object(forKey: "fadeInAction") as? SKAction {
                scoreLabel.run(fadeInAction)
            } else {
                let fadeInAction = SKAction.fadeIn(withDuration: 0.25)
                fadeInAction.timingMode = .easeIn
                scoreLabel.run(fadeInAction)

                scoreLabel.userData?.setObject(fadeInAction, forKey: "fadeInAction" as NSCopying)
            }
        }

        // Fade out when set to 0
        if score <= 0 && oldScore > 0 {
            if let fadeOutAction = scoreLabel.userData?.object(forKey: "fadeOutAction") as? SKAction {
                scoreLabel.run(fadeOutAction)
            } else {
                let fadeOutAction = SKAction.fadeOut(withDuration: 0.25)
                fadeOutAction.timingMode = .easeIn
                scoreLabel.run(fadeOutAction)

                scoreLabel.userData?.setObject(fadeOutAction, forKey: "fadeOutAction" as NSCopying)
            }
        }

        // Pulse when score increases
        if score > oldScore {
            if let pulseAction = scoreLabel.userData?.object(forKey: "pulseAction") as? SKAction {
                scoreLabel.run(pulseAction)
            } else {
                let growAction = SKAction.scale(by: 1.25, duration: 0.15)
                let pulseAction = SKAction.sequence([
                    growAction,
                    growAction.reversed()
                ])
                pulseAction.timingMode = .easeInEaseOut
                scoreLabel.run(pulseAction)
                scoreLabel.userData?.setObject(pulseAction, forKey: "pulseAction" as NSCopying)
            }
        }

        scoreLabel.text = "Score \(score)"
    }

    // MARK: Game Nodes
    fileprivate let gameAreaNode = SKNode()

    fileprivate let playerNodeName: String = "player"
    fileprivate var playerNode: TargetShapeNode? {
        return gameAreaNode.childNode(withName: playerNodeName) as? TargetShapeNode
    }

    fileprivate let incorrectTargetNodeName: String = "target-incorrect"
    fileprivate var incorrectTargets: [TargetShapeNode] {
        var incorrectTargetNodes = [TargetShapeNode]()
        gameAreaNode.enumerateChildNodes(withName: incorrectTargetNodeName) { node, _ in
            incorrectTargetNodes.append(node as! TargetShapeNode)
        }
        return incorrectTargetNodes
    }

    fileprivate let correctTargetNodeName: String = "target-correct"
    fileprivate var correctTarget: TargetShapeNode? {
        return gameAreaNode.childNode(withName: correctTargetNodeName) as? TargetShapeNode
    }

    // MARK: Hud Nodes
    fileprivate let scoreLabel = SKLabelNode()

    fileprivate let timeIndicator = TimeIndicatorNode()

    // MARK: Interface Setup
    override func didMove(to view: SKView) {
        addChild(gameAreaNode)

        setupBackground()
        setupScoreLabel()
        setupTimeIndicator()

        startPuzzle()
    }

    fileprivate func setupBackground() {
        backgroundColor = SKColor.white
        let backgroundNode = SKSpriteNode(texture: Textures.getMenuScreenTexture(size))
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.zPosition = NodeStackingOrder.backgroundImage.rawValue
        gameAreaNode.addChild(backgroundNode)
    }

    fileprivate func setupTimeIndicator() {
        timeIndicator.indicatorStrokeColor = SKColor(red: 49/255, green: 71/255, blue: 215/255, alpha: 0.75)
        timeIndicator.indicatorStrokeWidth = 4
        timeIndicator.size = CGSize(width: timeIndicatorDiamiter, height: timeIndicatorDiamiter)
        timeIndicator.position = centerPoint
        timeIndicator.zPosition = NodeStackingOrder.timerIndicator.rawValue
        gameAreaNode.addChild(timeIndicator)
    }

    fileprivate func setupScoreLabel() {
        scoreLabel.text = "Score \(score)"
        scoreLabel.alpha = 0
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.fontSize = 45
        scoreLabel.fontColor = SKColor.white
        scoreLabel.position = topLabelPosition
        scoreLabel.zPosition = NodeStackingOrder.interface.rawValue

        gameAreaNode.addChild(scoreLabel)
    }

    // MARK: Level Setup
    fileprivate func startPuzzle() {
        levelsPlayed += 1
        drawPuzzleForLevel(levelsPlayed)
    }

    fileprivate func getTimeForLevel(_ level: Int) -> TimeInterval {
        let maxTimeForLevel: TimeInterval = 1.2 // Starting time allowed for per level
        let minTimeForLevel: TimeInterval = 0.4 // Cap on minimum amount of time per level

        var timeForLevel = maxTimeForLevel - Double(level / 5) * 0.1
        if timeForLevel < minTimeForLevel {
            timeForLevel = minTimeForLevel
        }

        return timeForLevel
    }

    fileprivate func getNewPlayerNode() -> TargetShapeNode {
        let newPlayer = settings.gameMode == .colorMatch
            ? TargetShapeNode(targetShape: TargetShape.square) : TargetShapeNode.randomShapeNode()
        newPlayer.name = playerNodeName
        newPlayer.position = centerPoint
        newPlayer.targetSize = targetSize
        newPlayer.alpha = 0
        newPlayer.setScale(0)
        newPlayer.zPosition = NodeStackingOrder.playerTarget.rawValue

        let showAction = SKAction.group([
            SKAction.fadeIn(withDuration: setupNewGameAnimationDuration),
            SKAction.scale(to: 1.0, duration: setupNewGameAnimationDuration)
        ])
        showAction.timingMode = .easeIn

        newPlayer.run(showAction)

        return newPlayer
    }

    fileprivate func drawPuzzleForLevel(_ level: Int) {
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
        timeIndicator.run(SKAction.fadeIn(withDuration: setupNewGameAnimationDuration))

        run(SKAction.sequence([
            SKAction.wait(forDuration: setupNewGameAnimationDuration * 1.5),
            SKAction.run({
                if self.hasStartedFirstLevel {
                    self.startLevel()
                } else {
                    self.showGameGuidance()
                }
            })
        ]))
    }

    fileprivate func startLevel() {
        isPlayingLevel = true
    }

    fileprivate func getNumberOfTargetsForLevelsPlayed(_ levelsPlayed: Int) -> Int {
        var bonusTargets = 0
        if settings.newTargetIncrement > 0 && settings.newTargetAfterTurn > 0 {
            bonusTargets = Int(floor(Double(levelsPlayed / settings.newTargetAfterTurn))) * settings.newTargetIncrement
        }
        var numberOfTargets = settings.minNumberOfTargets + bonusTargets
        numberOfTargets = numberOfTargets > settings.maxNumberOfTargets ? settings.maxNumberOfTargets : numberOfTargets
        return numberOfTargets
    }

    fileprivate func setupTargetsFor(_ playerTargetNode: TargetShapeNode, numberOfTargets: Int) {

        // Get new target positions
        let targetPositions = calculatePositionForTargets(quantity: numberOfTargets)

        // Pick winning target
        let random = GKRandomDistribution(lowestValue: 0, highestValue: targetPositions.count - 1)
        let winningTargetIndex = random.nextInt()

        // Create targets
        var newTargets = [TargetShapeNode]()
        for (i, position) in targetPositions.enumerated() {

            let targetNode = getTargetShapeNodeFor(playerTargetNode.targetColor,
                                                   playerNodeShape: playerTargetNode.targetShape,
                                                   isWinning: i == winningTargetIndex)

            // Invisible in center
            targetNode.alpha = 0
            targetNode.setScale(0)
            targetNode.position = centerPoint
            targetNode.zPosition = NodeStackingOrder.target.rawValue

            // Animate
            let showAnimation = SKAction.group([
                SKAction.fadeIn(withDuration: setupNewGameAnimationDuration),
                SKAction.move(to: position, duration: setupNewGameAnimationDuration),
                SKAction.scale(to: 1.0, duration: setupNewGameAnimationDuration)
            ])
            showAnimation.timingMode = .easeIn
            targetNode.run(showAnimation)

            newTargets.append(targetNode)
        }

        // Add targets to screen
        for newTarget in newTargets {
            gameAreaNode.addChild(newTarget)
        }
    }

    fileprivate func getTargetShapeNodeFor(_ playerNodeColor: TargetColor,
                                           playerNodeShape: TargetShape,
                                           isWinning: Bool) -> TargetShapeNode {
        var targetColor: TargetColor
        var targetShape: TargetShape

        if isWinning {
            switch settings.gameMode {
            case .colorMatch:
                targetColor = playerNodeColor
                targetShape = TargetShape.square
            case .shapeMatch:
                targetColor = TargetColor.random(not: playerNodeColor)
                targetShape = playerNodeShape
            case .exactMatch:
                targetColor = playerNodeColor
                targetShape = playerNodeShape
            }
        } else {
            switch settings.gameMode {
            case .colorMatch:
                targetColor = TargetColor.random(not: playerNodeColor)
                targetShape = TargetShape.square
            case .shapeMatch:
                targetColor = TargetColor.random()
                targetShape = TargetShape.random(not: playerNodeShape)
            case .exactMatch:
                targetColor = TargetColor.random(not: playerNodeColor)
                targetShape = TargetShape.random(not: playerNodeShape)
            }
        }

        let targetNode = TargetShapeNode(targetColor: targetColor, targetShape: targetShape)
        targetNode.targetSize = targetSize

        if isWinning {
            targetNode.name = correctTargetNodeName
        } else {
            targetNode.name = incorrectTargetNodeName
        }

        return targetNode
    }

    fileprivate func calculatePositionForTargets(quantity numberOfTargets: Int) -> [CGPoint] {
        var targetPositions = [CGPoint]()

        let degreesBetweenTargets = 360 / numberOfTargets

        for degrees in stride(from: 0, to: 360, by: degreesBetweenTargets) {
            let radians = Double(degrees) * Double.pi / 180.0

            let targetX = CGFloat(cos(radians)) * targetDistanceFromCenterPoint + centerPoint.x
            let targetY = CGFloat(sin(radians)) * targetDistanceFromCenterPoint + centerPoint.y

            targetPositions.append(CGPoint(x: targetX, y: targetY))
        }

        return targetPositions
    }

    // MARK: Gameplay
    fileprivate var lastUpdateTime: TimeInterval = 0
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime

        if isPlayingLevel {
            updateLevelWithDeltaTime(deltaTime)
        }
    }

    fileprivate func updateLevelWithDeltaTime(_ deltaTime: TimeInterval) {
        timeRemainingForCurrentLevel -= deltaTime

        if timeRemainingForCurrentLevel <= 0 {
            let collisionState = getCollisionStateForPlayer(playerNode!,
                                                            withCorrectTarget: correctTarget!,
                                                            andIncorrectTargets: incorrectTargets)
            if collisionState == .correctTarget {
                player(playerNode!, didSelectCorrectTarget: correctTarget!, withIncorrectTargets: incorrectTargets)
            } else {
                timeIndicator.percent = 100
                gameOver("Times Up")
            }
        }
    }

    fileprivate func updateTimeIndicator() {
        timeIndicator.percent = ((timeForCurrentLevel - timeRemainingForCurrentLevel) / timeForCurrentLevel) * 100
    }

    fileprivate func playSound(_ soundAction: SKAction) {
        if settings.soundsEnabled {
            run(soundAction)
        }
    }

    fileprivate func player(_ playerNode: TargetShapeNode,
                            didSelectCorrectTarget correctTarget: TargetShapeNode,
                            withIncorrectTargets incorrectTargets: [TargetShapeNode]) {
        isPlayingLevel = false

        // Update score
        let pointsGained = pointsRemainingForCurrentLevel
        score += pointsGained

        playSound(successSoundAction)

        // Display points gained
        correctTarget.setPointsGained(pointsGained)

        // Grow winning target
        let growAction = SKAction.scale(to: 2, duration: successAnimationDuration)
        growAction.timingMode = .easeIn
        correctTarget.run(SKAction.sequence([
            growAction,
            SKAction.removeFromParent()
        ]))

        // Fade out incorrect targets
        let shrinkAction = SKAction.scale(to: 1, duration: successAnimationDuration)
        shrinkAction.timingMode = .easeIn
        incorrectTargets.forEach({
            $0.run(SKAction.sequence([
                shrinkAction,
                SKAction.removeFromParent()
            ]))
        })

        // Fade out timer
        timeIndicator.run(SKAction.fadeOut(withDuration: successAnimationDuration))

        // Animate removal of current player node
        playerNode.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: successAnimationDuration),
                SKAction.scale(to: 0, duration: successAnimationDuration)
            ]),
            SKAction.removeFromParent(),

            // Draw new puzzle
            SKAction.run({
                self.startPuzzle()
            })
        ]))
    }

    fileprivate func playerDidSelectIncorrectTarget() {
        gameOver("Incorrect")
    }

    fileprivate func returnPlayerToCenterPoint(_ playerNode: TargetShapeNode) {
        let returnAction = SKAction.move(to: centerPoint, duration: TimeInterval(0.15))
        returnAction.timingMode = .easeInEaseOut
        playerNode.run(returnAction, withKey: "Return")
    }

    fileprivate func movePlayerNode(_ playerNode: TargetShapeNode, withVector vector: CGPoint) {
        // Remove position actions
        removeGameGuidance()
        playerNode.removeAction(forKey: "Return")

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

    fileprivate enum PlayerCollisionState {
        case correctTarget
        case incorrectTarget
        case noTarget
    }

    fileprivate func getCollisionStateForPlayer(_ playerNode: TargetShapeNode,
                                                withCorrectTarget correctTarget: TargetShapeNode,
                                                andIncorrectTargets incorrectTargets: [TargetShapeNode])
        -> PlayerCollisionState {

        // Check for correct selection
        if playerNode.intersects(correctTarget) {
            return .correctTarget
        }

        // Check for incorrect selection
        let playerIntersectsIncorrectTarget = incorrectTargets
            .map({ playerNode.intersects($0) })
            .reduce(false, { $0 || $1 })

        if playerIntersectsIncorrectTarget {
            return .incorrectTarget
        }

        return .noTarget
    }

    fileprivate func player(_ playerNode: TargetShapeNode,
                            didEndMoveWithCorrectTarget correctTarget: TargetShapeNode,
                            andIncorrectTargets incorrectTargets: [TargetShapeNode]) {

        let collisionState = getCollisionStateForPlayer(playerNode,
                                                        withCorrectTarget: correctTarget,
                                                        andIncorrectTargets: incorrectTargets)
        switch collisionState {
        case .correctTarget:
            player(playerNode, didSelectCorrectTarget: correctTarget, withIncorrectTargets: incorrectTargets)
        case .incorrectTarget:
            playerDidSelectIncorrectTarget()
        case .noTarget:
            returnPlayerToCenterPoint(playerNode)
        }
    }
}

// MARK: Game Over
extension MatchingGameScene {
    fileprivate func gameOver(_ reason: String) {
        isPlayingLevel = false
        isGameOver = true

        print("Game Over: \(reason)")

        playSound(failSoundAction)

        let currentHighScore = scoreManager.getHighScoreForGameType(settings.gameType)
        scoreManager.recordNewScore(score, forGameType: settings.gameType)

        var gameOverSequence = [SKAction]()
        #if !((arch(i386) || arch(x86_64)) && os(iOS))
            gameOverSequence.append(contentsOf: [
                SKAction.wait(forDuration: 0.1),
                SKAction.run({ [ unowned scope = self ] in
                    scope.blurScene()
                })
            ])
        #endif

        gameOverSequence.append(contentsOf: [
            SKAction.wait(forDuration: 0.25),
            SKAction.run({ [ unowned scope = self ] in
                scope.showHighScoreLabel(scope.score, isHighScore: scope.score > currentHighScore)
                scope.showNewGameButton()
                scope.showReturnToMenuButton()
            })
        ])

        run(SKAction.sequence(gameOverSequence))
    }

    fileprivate func blurScene() {
        let blurNode = SKEffectNode()
        blurNode.filter = CIFilter(name: "CIGaussianBlur", withInputParameters: ["inputRadius": 10.0])!
        blurNode.shouldRasterize = true
        blurNode.run(SKAction.fadeAlpha(to: 0.45, duration: 0.5))

        addChild(blurNode)

        gameAreaNode.removeFromParent()
        blurNode.addChild(gameAreaNode)
    }

    fileprivate func showHighScoreLabel(_ score: Int64, isHighScore: Bool) {
        let scoreLabel = SKLabelNode()
        scoreLabel.text = isHighScore ? "New High Score" : "Score \(score)"
        scoreLabel.alpha = 0
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.fontSize = 45
        scoreLabel.fontColor = SKColor.black
        scoreLabel.position = centerPoint + CGPoint(x: 0, y: 175)
        scoreLabel.zPosition = NodeStackingOrder.interface.rawValue

        scoreLabel.run(SKAction.fadeIn(withDuration: 0.5))
        addChild(scoreLabel)

        let highScoreLabel = SKLabelNode()
        highScoreLabel.text = "High Score \(scoreManager.getHighScoreForGameType(settings.gameType))"
        highScoreLabel.alpha = 0
        highScoreLabel.horizontalAlignmentMode = .center
        highScoreLabel.fontSize = 30
        highScoreLabel.fontColor = SKColor.black
        highScoreLabel.position = centerPoint + CGPoint(x: 0, y: 135)
        highScoreLabel.zPosition = NodeStackingOrder.interface.rawValue

        highScoreLabel.run(SKAction.fadeIn(withDuration: 0.5))
        addChild(highScoreLabel)
    }

    fileprivate func showNewGameButton() {
        let playAgainLabel = SKLabelNode()
        playAgainLabel.text = "Tap to Play Again"
        playAgainLabel.name = "play-again"
        playAgainLabel.fontSize = 35
        playAgainLabel.fontColor = SKColor.black
        playAgainLabel.verticalAlignmentMode = .center
        playAgainLabel.alpha = 0
        playAgainLabel.position = centerPoint
        playAgainLabel.zPosition = NodeStackingOrder.gameOverInterface.rawValue
        addChild(playAgainLabel)

        playAgainLabel.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.5),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(by: 1.2, duration: 0.4),
                SKAction.scale(by: 0.8333, duration: 0.4)
            ]))
        ]))
    }

    fileprivate func showReturnToMenuButton() {
        let returnToMenuLabel = SKLabelNode()
        returnToMenuLabel.text = "Return to Menu"
        returnToMenuLabel.name = "back-to-menu"
        returnToMenuLabel.fontSize = 35
        returnToMenuLabel.fontColor = SKColor.black
        returnToMenuLabel.verticalAlignmentMode = .center
        returnToMenuLabel.alpha = 0
        returnToMenuLabel.position = CGPoint(x: centerPoint.x, y: 100)
        returnToMenuLabel.zPosition = NodeStackingOrder.gameOverInterface.rawValue
        addChild(returnToMenuLabel)

        returnToMenuLabel.run(SKAction.fadeIn(withDuration: 0.65))
    }

    fileprivate func restartGame() {
        let newGameScene = MatchingGameScene(size: size)
        newGameScene.scaleMode = scaleMode
        newGameScene.settings = settings
        view?.presentScene(newGameScene)
    }

    fileprivate func returnToMenu() {
        let menuScene = MenuScene(size: size)
        menuScene.scaleMode = scaleMode
        let transition = SKTransition.doorsCloseHorizontal(withDuration: 0.25)
        view?.presentScene(menuScene, transition: transition)
    }
}

// MARK: Game Guidance
extension MatchingGameScene {
    fileprivate func showGameGuidance() {
        showGuidanceLabel()
        playHintAnimationForPlayer(playerNode!, toNode: correctTarget!)
    }

    fileprivate func removeGameGuidance() {
        playerNode?.removeAction(forKey: "Hint")
        if let guidanceLabel = gameAreaNode.childNode(withName: "guidance-label") {
            guidanceLabel.removeFromParent()
        }
    }

    fileprivate func playHintAnimationForPlayer(_ playerNode: TargetShapeNode, toNode targetNode: TargetShapeNode) {
        let hintPoint = (centerPoint + targetNode.position) / 2

        let hintAction = SKAction.sequence([
            SKAction.move(to: hintPoint, duration: 0.3),
            SKAction.move(to: centerPoint, duration: 0.3)])
        hintAction.timingMode = .easeInEaseOut

        playerNode.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.wait(forDuration: 1.25),
                hintAction
            ]))
        ]), withKey: "Hint")
    }

    fileprivate func showGuidanceLabel() {
        let guidanceLabel = SKLabelNode()
        guidanceLabel.text = settings.gameMode == .colorMatch ? "Match the Colour" : "Match the Shape"
        guidanceLabel.verticalAlignmentMode = .center
        guidanceLabel.horizontalAlignmentMode = .center
        guidanceLabel.fontSize = 35
        guidanceLabel.fontColor = SKColor.white
        guidanceLabel.position = topLabelPosition
        guidanceLabel.zPosition = NodeStackingOrder.interface.rawValue
        guidanceLabel.name = "guidance-label"

        // Blink label
        guidanceLabel.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 0.25),
            SKAction.fadeAlpha(to: 0.75, duration: 0.5),
            SKAction.fadeAlpha(to: 1, duration: 0.5)
        ])))

        gameAreaNode.addChild(guidanceLabel)
    }
}

// MARK: Handle input
extension MatchingGameScene {
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        let touchLocation = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)

        // Start initial game after initial move
        if !hasStartedFirstLevel {
            hasStartedFirstLevel = true
            startLevel()
        }

        if isPlayingLevel {
            movePlayerNode(playerNode!, withVector: touchLocation - previousLocation)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        let touchLocation = touch.location(in: self)

        if isPlayingLevel {
            player(playerNode!, didEndMoveWithCorrectTarget: correctTarget!, andIncorrectTargets: incorrectTargets)
        } else if isGameOver {
            let touchedNodes = nodes(at: touchLocation)
            if touchedNodes.contains(where: {$0.name == "play-again" }) {
                restartGame()
            } else if touchedNodes.contains(where: {$0.name == "back-to-menu" }) {
                returnToMenu()
            }
        }
    }
}
// swiftlint:disable:this file_length
