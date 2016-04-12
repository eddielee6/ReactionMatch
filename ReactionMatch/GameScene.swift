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

class GameScene: SKScene {
    
    let successSoundAction = SKAction.playSoundFileNamed("success.wav", waitForCompletion: false)
    let failSondAction = SKAction.playSoundFileNamed("fail.wav", waitForCompletion: false)
    let fadeInAction = SKAction.fadeInWithDuration(0.25)
    
    var centerPoint: CGPoint = CGPoint.zero
    let targetDistanceFromCenterPoint: CGFloat = 100    
    
    let numberOfTargets: Int = 4
    
    let scoreLabel = SKLabelNode()
    let stateLabel = SKLabelNode()
    
    var gameStarted: Bool = false
    var levelsPlayed: Int = 0
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score \(score)"
        }
    }
    
    let baseTimeForLevel: Double = 1.2
    let minTimeForLevel: Double = 0.4
    var timeForLevel: Double = 1.2
    var timeRemaining: Double = 0
    
    var player: TargetShapeNode?
    var targets = Array<TargetShapeNode>()
    
    override func didMoveToView(view: SKView) {
        setupInitialState()
        drawNewPuzzle()
    }
    
    func setupInitialState() {
        centerPoint = CGPoint(x: size.width/2, y: size.height/2 - 60)
        
        fadeInAction.timingMode = .EaseIn
        
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
        
        timeForLevel = baseTimeForLevel - Double(levelsPlayed / 5) * 0.1
        if timeForLevel < minTimeForLevel {
            timeForLevel = minTimeForLevel
        }
        
        // Remove any existing player
        if let existingPlayer = player {
            existingPlayer.removeFromParent()
        }
        
        // Setup new player
        let newPlayer = TargetShapeNode.randomShapeNode()
        newPlayer.strokeColor = SKColor.whiteColor()
        newPlayer.position = centerPoint
        newPlayer.zPosition = 10
        addChild(newPlayer)
        
        player = newPlayer
        
        setupTargetsFor(playerColor: newPlayer.targetColor, playerShape: newPlayer.targetShape)
        
        runAction(SKAction.sequence([
            SKAction.waitForDuration(0.5),
            SKAction.runBlock({
                if !self.gameStarted {
                    self.firstPlayHint()
                }
            })
        ]))
    }
    
    func getWinningTarget() -> SKShapeNode? {
        for target in targets {
            if target.name == "winner" {
                return target
            }
        }
        
        return nil
    }
    
    func firstPlayHint() {
        if let winningTarget = getWinningTarget() {
            let hintPoint = (centerPoint + winningTarget.position) / 2
            
            let hintAction = SKAction.sequence([
                SKAction.moveTo(hintPoint, duration: 0.3),
                SKAction.moveTo(centerPoint, duration: 0.3)])
            hintAction.timingMode = .EaseInEaseOut
            
            player!.runAction(SKAction.repeatActionForever(SKAction.sequence([
                SKAction.waitForDuration(1.25),
                hintAction
            ])), withKey: "Hint")
        }
    }
    
    func stopTimer() {
        removeActionForKey("GameTimer")
    }
    
    func resetTimer(time: Double) {
        self.timeRemaining = time
        
        let tickInterval = 0.1
        runAction(SKAction.repeatActionForever(SKAction.sequence([
            SKAction.waitForDuration(tickInterval),
            SKAction.runBlock({
                self.timeRemaining = self.timeRemaining - tickInterval
                
                if self.timeRemaining <= 0 {
                    self.removeActionForKey("GameTimer")
                    self.gameOver("Times Up")
                } else {
                    self.stateLabel.text = "\(self.getPointsForTime(self.timeRemaining)) points"
                }
            })
        ])), withKey: "GameTimer")
    }
    
    func getPointsForTime(timeRemaining: Double) -> Int {
        return Int(ceil((timeRemaining / timeForLevel) * 10))
    }    
    
    func setupTargetsFor(playerColor playerColor: TargetColor, playerShape: TargetShape) {
        // Remove any old targets
        removeChildrenInArray(targets)
        targets.removeAll()
        
        // Get new target positions
        let targetPositions = calculatePositionForTargets(quantity: numberOfTargets)
        
        // Pick winning target
        let random = GKRandomDistribution(lowestValue: 0, highestValue: targetPositions.count - 1)
        let winningTargetIndex = random.nextInt()
        
        // Create targets
        for (i, position) in targetPositions.enumerate() {
            let targetColor = TargetColor.random(not: playerColor)
            let targetShape = TargetShape.random()
            
            let targetNode = TargetShapeNode(targetColor: targetColor, targetShape: targetShape)
            
            targetNode.position = position
            
            // Fade in
            targetNode.alpha = 0
            targetNode.runAction(fadeInAction)
            
            // Color winning target correctly
            if i == winningTargetIndex {
                targetNode.fillColor = playerColor.value
                targetNode.strokeColor = playerColor.value
                targetNode.name = "winner"
            }
            
            addChild(targetNode)
            
            targets.append(targetNode)
        }
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
    
    func correctSelection(winningTarget: SKShapeNode) {
        stopTimer()
        
        // Update score
        let pointsGained = getPointsForTime(timeRemaining)
        score += pointsGained
        
        // Play sound
        runAction(successSoundAction)
        
        // Add points gained
        let pointsGainedLabel = winningTarget.childNodeWithName("pointsGainedLabel")! as! SKLabelNode
        pointsGainedLabel.fontColor = winningTarget.fillColor.inverted
        pointsGainedLabel.text = "\(pointsGained)"
        
        // Return player to center
        let returnAction = SKAction.moveTo(centerPoint, duration: NSTimeInterval(0.25))
        returnAction.timingMode = .EaseInEaseOut
        player!.runAction(returnAction, withKey: "Return")
        
        // Grow winning target
        let growAction = SKAction.scaleBy(2, duration: 0.25)
        growAction.timingMode = .EaseIn
        winningTarget.runAction(growAction)
        
        // Fade out incorrect targets
        let shrinkAction = SKAction.scaleBy(0, duration: 0.25)
        shrinkAction.timingMode = .EaseIn
        targets.filter({
            return $0 != winningTarget
        }).forEach({
            $0.runAction(shrinkAction)
        })
        
        // Draw new puzzle
        runAction(SKAction.sequence([
            SKAction.waitForDuration(0.25),
            SKAction.runBlock({
                self.drawNewPuzzle()
                self.resetTimer(self.timeForLevel)
            })
        ]))
    }
    
    func incorrectSelection() {
        gameOver("Wrong Colour")
    }
    
    func failedSelection() {
        let returnAction = SKAction.moveTo(centerPoint, duration: NSTimeInterval(0.15))
        returnAction.timingMode = .EaseInEaseOut
        player!.runAction(returnAction, withKey: "Return")
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
        
        if let currentPlayer = player {
            currentPlayer.removeActionForKey("Hint")
            currentPlayer.removeActionForKey("Return")
            
            let newPosition = currentPlayer.position + (touchLocation - previousLocation)
            currentPlayer.position = newPosition
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Start timer after initial touch
        if !gameStarted {
            gameStarted = true
            resetTimer(timeForLevel)
        }
        
        if let currentPlayer = player {
            for target in targets {
                if currentPlayer.intersectsNode(target) {
                    if target.name == "winner" {
                        correctSelection(target)
                        break
                    } else {
                        incorrectSelection()
                        break
                    }
                }
            }
        }
        
        failedSelection()
    }
    
    override func update(currentTime: NSTimeInterval) {
        let playerMaxDistanceFromCenterPoint = targetDistanceFromCenterPoint * 1.2
        
        if let currentPlayer = player {
            let distance = (currentPlayer.position - centerPoint).length()
            if distance > playerMaxDistanceFromCenterPoint {
                let offset = currentPlayer.position - centerPoint
                let direction = offset.normalized()
                let cappedPosition = (direction * playerMaxDistanceFromCenterPoint) + centerPoint
                currentPlayer.position = cappedPosition
            }
        }
    }
}