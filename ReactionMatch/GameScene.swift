//
//  GameScene.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 18/01/2016.
//  Copyright (c) 2016 Eddie Lee. All rights reserved.
//

import SpriteKit
import GameKit
import Foundation

enum GameMode {
    case ColorMatch
    case ShapeMatch
    case ExactMatch
}

class GameScene: SKScene {
    
    let gameMode: GameMode = .ShapeMatch // How accuratly should shapes be matched
    
    let minNumberOfTargets: Int = 2 // Starting number of targets on screen
    let maxNumberOfTargets: Int = 8 // Cap on how many targets per game
    let newTargetAfterTurn: Int = 5 // Turns between new targets being added
    let newTargetIncrement: Int = 2 // Number of targets to add each increment
    
    let maxTimeForLevel: NSTimeInterval = 1.2 // Starting time allowed for per level
    let minTimeForLevel: NSTimeInterval = 0.4 // Cap on minimum amount of time per level
    
    var timerRunning: Bool = false
    var timeForLevel: NSTimeInterval = 0
    var timeRemainingForLevel: NSTimeInterval = 0
    
    
    let successAnimationDuration: Double = 0.25
    let setupNewGameAnimationDuration: Double = 0.25
    
    
    let successSoundAction = SKAction.playSoundFileNamed("success.wav", waitForCompletion: false)
    let failSondAction = SKAction.playSoundFileNamed("fail.wav", waitForCompletion: false)
    
    
    let targetDistanceFromCenterPoint: CGFloat = 100
    var centerPoint: CGPoint {
        get {
            let centerPointVerticalOffset: CGFloat = -60
            return CGPoint(x: size.width/2, y: size.height/2 + centerPointVerticalOffset)
        }
    }
    var maxPlayerDistanceFromCenterPoint: CGFloat {
        get {
            return targetDistanceFromCenterPoint * 1.2
        }
    }
    
    var hasStartedPlaying: Bool = false
    
    var levelsPlayed: Int = 0
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score \(score)"
        }
    }
    
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
                if let targetNode = node as? TargetShapeNode {
                    incorrectTargetNodes.append(targetNode)
                }
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
        setupInitialState()
        drawNewPuzzle()
    }
    
    func setupInitialState() {
        // Set background
        let backgroundNode = SKSpriteNode(texture: getBackgroundTexture())
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.zPosition = 0
        addChild(backgroundNode)
        
        // Score
        scoreLabel.text = "Score \(score)"
        scoreLabel.horizontalAlignmentMode = .Center
        scoreLabel.fontSize = 45
        scoreLabel.fontColor = SKColor.blackColor()
        scoreLabel.position = CGPoint(x: size.width/2, y: size.height - 85)
        addChild(scoreLabel)
        
        // Game State
        stateLabel.text = "Swipe to Play"
        stateLabel.horizontalAlignmentMode = .Center
        stateLabel.fontSize = 30
        stateLabel.fontColor = SKColor.blackColor()
        stateLabel.position = CGPoint(x: size.width/2, y: scoreLabel.position.y - 60)
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
    
    func drawNewPuzzle() {
        levelsPlayed += 1
        
        // Setup new player
        let newPlayer = TargetShapeNode.randomShapeNode()
        newPlayer.name = playerNodeName
        newPlayer.strokeColor = SKColor.whiteColor()
        newPlayer.position = centerPoint
        newPlayer.alpha = 0
        newPlayer.setScale(0)
        newPlayer.zPosition = 10
        
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
        let bonusTargets:Int = Int(floor(Double(levelsPlayed / newTargetAfterTurn))) * newTargetIncrement
        var numberOfTargets: Int = minNumberOfTargets + bonusTargets
        numberOfTargets = numberOfTargets > maxNumberOfTargets ? maxNumberOfTargets : numberOfTargets
        
        setupTargetsFor(newPlayer, numberOfTargets: numberOfTargets)
        
        
        timeForLevel = maxTimeForLevel - Double(levelsPlayed / 5) * 0.1
        if timeForLevel < minTimeForLevel {
            timeForLevel = minTimeForLevel
        }
        
        runAction(SKAction.sequence([
            SKAction.waitForDuration(setupNewGameAnimationDuration),
            SKAction.runBlock({
                if self.hasStartedPlaying {
                    self.setTimer(self.timeForLevel)
                } else {
                    self.playHintAnimation()
                }
            })
        ]))
    }
    
    func playHintAnimation() {
        guard let correctTarget = correctTarget, playerNode = playerNode else {
            print("Failed to play hint animation")
            return
        }
        
        let hintPoint = (centerPoint + correctTarget.position) / 2
        
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
    
    func setTimer(timeForLevel: NSTimeInterval) {
        timeRemainingForLevel = timeForLevel
        timerRunning = true
    }
    
    func stopTimer() {
        timerRunning = false
    }
    
    func getPointsForTime(timeRemaining: Double) -> Int {
        return Int(ceil((timeRemaining / timeForLevel) * 10))
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
            
            let targetNode = createTargetShapeNode(playerTargetNode, isWinning: i == winningTargetIndex)
            
            if i == winningTargetIndex {
                targetNode.name = correctTargetNodeName
            } else {
                targetNode.name = incorrectTargetNodeName
            }
            
            // Invisible in center
            targetNode.alpha = 0
            targetNode.setScale(0)
            targetNode.position = centerPoint
            
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
    
    func createTargetShapeNode(playerTargetNode: TargetShapeNode, isWinning: Bool) -> TargetShapeNode {
        var targetColor: TargetColor
        var targetShape: TargetShape
        
        if isWinning {
            switch gameMode {
            case .ColorMatch:
                targetColor = playerTargetNode.targetColor
                targetShape = TargetShape.random()
            case .ShapeMatch:
                targetColor = TargetColor.random()
                targetShape = playerTargetNode.targetShape
            case .ExactMatch:
                targetColor = playerTargetNode.targetColor
                targetShape = playerTargetNode.targetShape
            }
        } else {
            switch gameMode {
            case .ColorMatch:
                targetColor = TargetColor.random(not: playerTargetNode.targetColor)
                targetShape = TargetShape.random()
            case .ShapeMatch:
                targetColor = TargetColor.random()
                targetShape = TargetShape.random(not: playerTargetNode.targetShape)
            case .ExactMatch:
                targetColor = TargetColor.random(not: playerTargetNode.targetColor)
                targetShape = TargetShape.random(not: playerTargetNode.targetShape)
            }
        }
        
        let targetNode = TargetShapeNode(targetColor: targetColor, targetShape: targetShape)
        
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
    

    enum PlayerCollisionState {
        case CorrectTarget
        case IncorrectTarget
        case NoTarget
    }
    
    func getPlayerCollisionState() -> PlayerCollisionState {
        guard let playerNode = playerNode, correctTarget = correctTarget else {
            print("Failed to get player collision state")
            return .NoTarget
        }
        
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
    
    func playerMadeCorrectSelection() {
        stopTimer()
        
        // Update score
        let pointsGained = getPointsForTime(timeRemainingForLevel)
        score += pointsGained
        
        // Play sound
        runAction(successSoundAction)
        
        if let correctTarget = correctTarget {
            // Display points gained
            if let winningTargetPointsLabel = correctTarget.childNodeWithName("pointsGainedLabel") as? SKLabelNode {
                winningTargetPointsLabel.fontColor = correctTarget.fillColor.inverted
                winningTargetPointsLabel.text = "\(pointsGained)"
            }
            
            // Grow winning target
            let growAction = SKAction.scaleBy(2, duration: successAnimationDuration)
            growAction.timingMode = .EaseIn
            correctTarget.runAction(SKAction.sequence([
                growAction,
                SKAction.removeFromParent()
            ]))
        }
        
        
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
        if let playerNode = playerNode {
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
    }
    
    func playerMadeIncorrectSelection() {
        gameOver("Incorrect")
    }
    
    func playerMadeNoSelection() {
        if let playerNode = playerNode {
            let returnAction = SKAction.moveTo(centerPoint, duration: NSTimeInterval(0.15))
            returnAction.timingMode = .EaseInEaseOut
            playerNode.runAction(returnAction, withKey: "Return")
        }
    }
    
    func gameOver(reason: String) {
        print("Game Over: \(reason)")
        self.stateLabel.text = reason
        
        runAction(failSondAction)
        let transition = SKTransition.doorsCloseVerticalWithDuration(NSTimeInterval(0.5))
        let gameOverScene = GameOverScene(size: self.size)
        gameOverScene.newScore = score
        gameOverScene.reason = reason
        self.view?.presentScene(gameOverScene, transition: transition)
    }
    
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.locationInNode(self)
        let previousLocation = touch.previousLocationInNode(self)
        
        if let playerNode = playerNode {
            playerNode.removeActionForKey("Hint")
            playerNode.removeActionForKey("Return")
            
            let newPosition = playerNode.position + (touchLocation - previousLocation)
            playerNode.position = newPosition
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Start timer after initial touch
        if !hasStartedPlaying {
            hasStartedPlaying = true
            setTimer(timeForLevel)
        }
        
        switch(getPlayerCollisionState()) {
        case .CorrectTarget:
            playerMadeCorrectSelection()
        case .IncorrectTarget:
            playerMadeIncorrectSelection()
        case .NoTarget:
            playerMadeNoSelection()
        }
    }
    
    
    var lastUpdateTime: NSTimeInterval = 0
    override func update(currentTime: NSTimeInterval) {
        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime
        
        boundsCheckPlayerNode()
        
        updateTimer(deltaTime)
    }
    
    func updateTimer(deltaTime: NSTimeInterval) {
        guard timerRunning == true else {
            return
        }
        
        timeRemainingForLevel -= deltaTime
        
        let currentPointsAvailable = getPointsForTime(timeRemainingForLevel)
        stateLabel.text = "\(currentPointsAvailable) points"
        
        if timeRemainingForLevel <= 0 {
            if getPlayerCollisionState() == .CorrectTarget {
                playerMadeCorrectSelection()
            } else {
                //removeActionForKey("GameTimer")
                gameOver("Times Up")
            }
        }
    }

    func boundsCheckPlayerNode() {
        if let playerNode = playerNode {
            let distance = (playerNode.position - centerPoint).length()
            if distance > maxPlayerDistanceFromCenterPoint {
                let offset = playerNode.position - centerPoint
                let direction = offset.normalized()
                let cappedPosition = (direction * maxPlayerDistanceFromCenterPoint) + centerPoint
                playerNode.position = cappedPosition
            }
        }
    }
}