//
//  GameScene.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 18/01/2016.
//  Copyright (c) 2016 Eddie Lee. All rights reserved.
//

import SpriteKit
import GameKit

class MatchingGameScene: SKScene {
    
    enum NodeStackingOrder: CGFloat {
        case BackgroundImage
        case Target
        case PlayerTarget
        case Interface
    }
    
    enum GameMode {
        case ExactMatch // Easy
        case ColorMatch // Medium
        case ShapeMatch // Hard
    }
    
    let gameMode: GameMode = .ShapeMatch // How accuratly should shapes be matched
    
    let minNumberOfTargets: Int = 2 // Starting number of targets on screen
    let maxNumberOfTargets: Int = 8 // Cap on how many targets per game
    let newTargetAfterTurn: Int = 5 // Turns between new targets being added
    let newTargetIncrement: Int = 2 // Number of targets to add each increment
    
    let maxTimeForLevel: NSTimeInterval = 1.2 // Starting time allowed for per level
    let minTimeForLevel: NSTimeInterval = 0.4 // Cap on minimum amount of time per level
    
    let successAnimationDuration: Double = 0.25 // Time taken to animate to new levels
    let setupNewGameAnimationDuration: Double = 0.25 // Time taken to animate to game start
    
    let targetDistanceFromCenterPoint: CGFloat = 110
    var maxPlayerDistanceFromCenterPoint: CGFloat {
        get {
            return targetDistanceFromCenterPoint * 1.2
        }
    }
    
    let soundsEnabled: Bool = true
    
    var isPlayingLevel: Bool = false
    var timeForLevel: NSTimeInterval = 0
    var timeRemainingForLevel: NSTimeInterval = 0
    
    var centerPoint: CGPoint {
        get {
            let centerPointVerticalOffset: CGFloat = -60
            return CGPoint(x: size.width/2, y: size.height/2 + centerPointVerticalOffset)
        }
    }
    
    var hasStartedPlaying: Bool = false
    
    var levelsPlayed: Int = 0
    var score: Int64 = 0 {
        didSet {
            if score > 0 && oldValue <= 0 {
                let fadeInAction = SKAction.fadeInWithDuration(0.25)
                fadeInAction.timingMode = .EaseIn
                scoreLabel.runAction(fadeInAction)
            } else if score <= 0 && oldValue > 0 {
                let fadeOutAction = SKAction.fadeOutWithDuration(0.25)
                fadeOutAction.timingMode = .EaseIn
                scoreLabel.runAction(fadeOutAction)
            }
            
            let growAction = SKAction.scaleBy(1.25, duration: 0.15)
            let pulseAction = SKAction.sequence([
                growAction,
                growAction.reversedAction()
            ])
            pulseAction.timingMode = .EaseInEaseOut
            scoreLabel.runAction(pulseAction)
            
            scoreLabel.text = "Score \(score)"
        }
    }
    
    let successSoundAction = SKAction.playSoundFileNamed("success.wav", waitForCompletion: false)
    let failSoundAction = SKAction.playSoundFileNamed("fail.wav", waitForCompletion: false)
    
    let scoreLabel = SKLabelNode()
    let stateLabel = SKLabelNode()
    
    let playerNodeName: String = "player"
    var playerNode: TargetShapeNode? {
        get {
            return childNodeWithName(playerNodeName) as? TargetShapeNode
        }
    }
    
    let incorrectTargetNodeName: String = "target-incorrect"
    var incorrectTargets: [TargetShapeNode] {
        get {
            var incorrectTargetNodes = [TargetShapeNode]()
            enumerateChildNodesWithName(incorrectTargetNodeName) { node, _ in
                incorrectTargetNodes.append(node as! TargetShapeNode)
            }
            return incorrectTargetNodes
        }
    }

    let correctTargetNodeName: String = "target-correct"
    var correctTarget: TargetShapeNode? {
        get {
            return childNodeWithName(correctTargetNodeName) as? TargetShapeNode
        }
    }
    
    
    override func didMoveToView(view: SKView) {
        setBackground()
        setHud()
        drawNewPuzzle()
    }
    
    var lastUpdateTime: NSTimeInterval = 0
    override func update(currentTime: NSTimeInterval) {
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime
        
        if isPlayingLevel {
            updateLevelWithDeltaTime(deltaTime)
        }
    }
    
    func setTimer(timeForLevel: NSTimeInterval) {
        timeRemainingForLevel = timeForLevel
    }
    
    func getPointsForTime(timeRemaining: Double) -> Int {
        return Int(ceil((timeRemaining / timeForLevel) * 10))
    }
    
    func playSound(soundAction: SKAction) {
        if soundsEnabled {
            runAction(soundAction)
        }
    }
    
    
    
    // MARK: Interface Setup
    
    func setBackground() {
        let backgroundNode = SKSpriteNode(texture: getBackgroundTexture())
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.zPosition = NodeStackingOrder.BackgroundImage.rawValue
        addChild(backgroundNode)
    }
    
    func setHud() {
        scoreLabel.text = "Score \(score)"
        scoreLabel.alpha = 0
        scoreLabel.horizontalAlignmentMode = .Center
        scoreLabel.fontSize = 45
        scoreLabel.fontColor = SKColor.blackColor()
        scoreLabel.position = CGPoint(x: size.width/2, y: size.height - 85)
        scoreLabel.zPosition = NodeStackingOrder.Interface.rawValue
        addChild(scoreLabel)
        
        stateLabel.text = "Swipe to Play"
        stateLabel.horizontalAlignmentMode = .Center
        stateLabel.fontSize = 30
        stateLabel.fontColor = SKColor.blackColor()
        stateLabel.position = CGPoint(x: size.width/2, y: scoreLabel.position.y - 60)
        stateLabel.zPosition = NodeStackingOrder.Interface.rawValue
        addChild(stateLabel)
        
        let blinkAction = SKAction.sequence([
            SKAction.fadeAlphaTo(0.4, duration: 0.4),
            SKAction.fadeAlphaTo(1, duration: 0.4)
        ])
        blinkAction.timingMode = .EaseInEaseOut
        stateLabel.runAction(SKAction.repeatActionForever(blinkAction))
    }
    
    func getBackgroundTexture() -> SKTexture {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = frame
        gradientLayer.colors = [
            SKColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1),
            SKColor(red: 215/255, green: 215/255, blue: 215/255, alpha: 1)
        ].map { $0.CGColor }
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        
        // render the gradient to a UIImage
        UIGraphicsBeginImageContext(frame.size)
        gradientLayer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(CGImage: image.CGImage!)
    }
    
    
    
    // MARK: Game Setup
    
    func drawNewPuzzle() {
        levelsPlayed += 1
        
        // Setup new player
        let newPlayer = TargetShapeNode.randomShapeNode()
        newPlayer.name = playerNodeName
        newPlayer.strokeColor = SKColor.whiteColor()
        newPlayer.position = centerPoint
        newPlayer.alpha = 0
        newPlayer.setScale(0)
        newPlayer.zPosition = NodeStackingOrder.PlayerTarget.rawValue
        
        // Create Fade Action
        let fadeInAction = SKAction.fadeInWithDuration(setupNewGameAnimationDuration)
        fadeInAction.timingMode = .EaseIn
        
        // Create Grow Action
        let growAction = SKAction.scaleTo(1.0, duration: setupNewGameAnimationDuration)
        growAction.timingMode = .EaseIn
        
        // Animate
        newPlayer.runAction(SKAction.group([
            fadeInAction,
            growAction
        ]))
        
        // Add new player
        addChild(newPlayer)
        
        // Add targets
        let numberOfTargets = getNumberOfTargetsForLevelsPlayed(levelsPlayed)
        setupTargetsFor(newPlayer, numberOfTargets: numberOfTargets)
        
        // Set timer for level
        timeForLevel = maxTimeForLevel - Double(levelsPlayed / 5) * 0.1
        if timeForLevel < minTimeForLevel {
            timeForLevel = minTimeForLevel
        }
        setTimer(timeForLevel)
        
        runAction(SKAction.sequence([
            SKAction.waitForDuration(setupNewGameAnimationDuration),
            SKAction.runBlock({
                if self.hasStartedPlaying {
                    self.isPlayingLevel = true
                } else {
                    self.playHintAnimationForPlayer(newPlayer, toNode: self.correctTarget!)
                }
            })
        ]))
    }
    
    func getNumberOfTargetsForLevelsPlayed(levelsPlayed: Int) -> Int {
        let bonusTargets = Int(floor(Double(levelsPlayed / newTargetAfterTurn))) * newTargetIncrement
        var numberOfTargets = minNumberOfTargets + bonusTargets
        numberOfTargets = numberOfTargets > maxNumberOfTargets ? maxNumberOfTargets : numberOfTargets
        return numberOfTargets
    }
    
    func setupTargetsFor(playerTargetNode: TargetShapeNode, numberOfTargets: Int) {
        
        // Get new target positions
        let targetPositions = calculatePositionForTargets(quantity: numberOfTargets)
        
        // Pick winning target
        let random = GKRandomDistribution(lowestValue: 0, highestValue: targetPositions.count - 1)
        let winningTargetIndex = random.nextInt()
        
        // Create Fade Action
        let fadeInAction = SKAction.fadeInWithDuration(setupNewGameAnimationDuration)
        fadeInAction.timingMode = .EaseIn
        
        // Create Grow Action
        let growAction = SKAction.scaleTo(1.0, duration: setupNewGameAnimationDuration)
        growAction.timingMode = .EaseIn
        
        // Create targets
        var newTargets = [TargetShapeNode]()
        for (i, position) in targetPositions.enumerate() {
            
            let targetNode = getTargetShapeNodeFor(playerTargetNode.targetColor, playerNodeShape: playerTargetNode.targetShape, isWinning: i == winningTargetIndex)
            
            // Invisible in center
            targetNode.alpha = 0
            targetNode.setScale(0)
            targetNode.position = centerPoint
            targetNode.zPosition = NodeStackingOrder.Target.rawValue
            
            // Create move action
            let moveToPositionAction = SKAction.moveTo(position, duration: setupNewGameAnimationDuration)
            moveToPositionAction.timingMode = .EaseIn
            
            // Animate
            targetNode.runAction(SKAction.group([
                fadeInAction,
                moveToPositionAction,
                growAction
            ]))
            
            newTargets.append(targetNode)
        }
        
        // Add targets to screen
        for newTarget in newTargets {
            addChild(newTarget)
        }
    }
    
    func getTargetShapeNodeFor(playerNodeColor: TargetColor, playerNodeShape: TargetShape, isWinning: Bool) -> TargetShapeNode {
        var targetColor: TargetColor
        var targetShape: TargetShape
        
        if isWinning {
            switch gameMode {
            case .ColorMatch:
                targetColor = playerNodeColor
                targetShape = TargetShape.random(not: playerNodeShape)
            case .ShapeMatch:
                targetColor = TargetColor.random(not: playerNodeColor)
                targetShape = playerNodeShape
            case .ExactMatch:
                targetColor = playerNodeColor
                targetShape = playerNodeShape
            }
        } else {
            switch gameMode {
            case .ColorMatch:
                targetColor = TargetColor.random(not: playerNodeColor)
                targetShape = TargetShape.random()
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
    
    func calculatePositionForTargets(quantity numberOfTargets: Int) -> [CGPoint] {
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
    
    func playHintAnimationForPlayer(playerNode: TargetShapeNode, toNode targetNode: TargetShapeNode) {
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
    
    func player(playerNode: TargetShapeNode, didSelectCorrectTarget correctTarget: TargetShapeNode, withIncorrectTargets incorrectTargets: [TargetShapeNode]) {
        isPlayingLevel = false
        
        // Update score
        let pointsGained = getPointsForTime(timeRemainingForLevel)
        score += pointsGained
        
        playSound(successSoundAction)
        
        // Display points gained
        correctTarget.setPointsGained(pointsGained)
        
        // Grow winning target
        let growAction = SKAction.scaleBy(2, duration: successAnimationDuration)
        growAction.timingMode = .EaseIn
        correctTarget.runAction(SKAction.sequence([
            growAction,
            SKAction.removeFromParent()
        ]))
        
        // Fade out incorrect targets
        let shrinkAction = SKAction.scaleBy(0, duration: successAnimationDuration)
        shrinkAction.timingMode = .EaseIn
        incorrectTargets.forEach({
            $0.runAction(SKAction.sequence([
                shrinkAction,
                SKAction.removeFromParent()
            ]))
        })
        
        // Animate removal of current player node
        playerNode.runAction(SKAction.sequence([
            SKAction.group([
                SKAction.fadeInWithDuration(successAnimationDuration),
                SKAction.scaleTo(0, duration: successAnimationDuration)
            ]),
            SKAction.removeFromParent(),
            
            // Draw new puzzle
            SKAction.runBlock({
                self.drawNewPuzzle()
            })
        ]))
    }
    
    func playerDidSelectIncorrectTarget() {
        gameOver("Incorrect")
    }
    
    func returnPlayerToCenterPoint(playerNode: TargetShapeNode) {
        let returnAction = SKAction.moveTo(centerPoint, duration: NSTimeInterval(0.15))
        returnAction.timingMode = .EaseInEaseOut
        playerNode.runAction(returnAction, withKey: "Return")
    }
    
    func gameOver(reason: String) {
        isPlayingLevel = false
        
        print("Game Over: \(reason)")
        self.stateLabel.text = reason
        
        playSound(failSoundAction)
        
        let transition = SKTransition.doorsCloseVerticalWithDuration(NSTimeInterval(0.5))
        let gameOverScene = GameOverScene(size: self.size)
        gameOverScene.newScore = score
        self.view?.presentScene(gameOverScene, transition: transition)
    }
    
    func movePlayerNode(playerNode: TargetShapeNode, withVector vector: CGPoint) {
        // Remove position actions
        playerNode.removeActionForKey("Hint")
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
    
    func updateLevelWithDeltaTime(deltaTime: NSTimeInterval) {
        timeRemainingForLevel -= deltaTime
        
        let currentPointsAvailable = getPointsForTime(timeRemainingForLevel)
        stateLabel.text = "\(currentPointsAvailable) points"
        
        if timeRemainingForLevel <= 0 {
            if timeRemainingForLevel <= 0 {
                let collisionState = getCollisionStateForPlayer(playerNode!, withCorrectTarget: correctTarget!, andIncorrectTargets: incorrectTargets)
                if collisionState == .CorrectTarget {
                    player(playerNode!, didSelectCorrectTarget: correctTarget!, withIncorrectTargets: incorrectTargets)
                } else {
                    gameOver("Times Up")
                }
            }
        }
    }
    
    enum PlayerCollisionState {
        case CorrectTarget
        case IncorrectTarget
        case NoTarget
    }
    
    func getCollisionStateForPlayer(playerNode: TargetShapeNode, withCorrectTarget correctTarget: TargetShapeNode, andIncorrectTargets incorrectTargets: [TargetShapeNode]) -> PlayerCollisionState {
        
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
    
    func player(playerNode: TargetShapeNode, didEndMoveWithCorrectTarget correctTarget: TargetShapeNode, andIncorrectTargets incorrectTargets: [TargetShapeNode]) {
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



// MARK: Handle input

extension MatchingGameScene {
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Start timer after initial touch
        if !hasStartedPlaying {
            hasStartedPlaying = true
            isPlayingLevel = true
            setTimer(timeForLevel)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.locationInNode(self)
        let previousLocation = touch.previousLocationInNode(self)
        
        guard isPlayingLevel else {
            return
        }
        
        movePlayerNode(playerNode!, withVector: touchLocation - previousLocation)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard isPlayingLevel else {
            return
        }
        
        player(playerNode!, didEndMoveWithCorrectTarget: correctTarget!, andIncorrectTargets: incorrectTargets)
    }
}