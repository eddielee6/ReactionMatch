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
    
    var centerPoint: CGPoint = CGPoint.zero
    let targetDistanceFromCenterPoint: CGFloat = 100
    let numberOfTargets: Int = 8
    
    var winningTargetRandom = GKRandomDistribution(lowestValue: 0, highestValue: 3)
    
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
    
    var player = SKNode()
    var playerTarget: Target?
    
    var targets = Array<SKShapeNode>()
    
    override func didMoveToView(view: SKView) {
        setupInitialState()
        drawNewPuzzle()
    }
    
    func setupInitialState() {
        centerPoint = CGPoint(x: size.width/2, y: size.height/2 - 60)
        
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
        
        // Player
        player.position = centerPoint
        player.zPosition = 10
        addChild(player)
    }
    
    func getTargetPositions(quantity numberOfTargets: Int) -> [CGPoint] {
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
        
        player.removeAllChildren()
        
        playerTarget = Target()
        playerTarget!.shapeNode.strokeColor = SKColor.whiteColor()
        
        player.addChild(playerTarget!.shapeNode)
        
        setupTargets(playerTarget: playerTarget!)
        
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
            var action:SKAction!
            
            if winningTarget.position.x > player.position.x {
                action = SKAction.sequence([
                    SKAction.moveToX(player.position.x + 50, duration: 0.3),
                    SKAction.moveToX(centerPoint.x, duration: 0.3)
                ])
            } else if winningTarget.position.x < player.position.x {
                action = SKAction.sequence([
                    SKAction.moveToX(player.position.x - 50, duration: 0.3),
                    SKAction.moveToX(centerPoint.x, duration: 0.3)
                ])
            } else if winningTarget.position.y > player.position.y {
                action = SKAction.sequence([
                    SKAction.moveToY(player.position.y + 50, duration: 0.3),
                    SKAction.moveToY(centerPoint.y, duration: 0.3)
                ])
            } else if winningTarget.position.y < player.position.y {
                action = SKAction.sequence([
                    SKAction.moveToY(player.position.y - 50, duration: 0.3),
                    SKAction.moveToY(centerPoint.y, duration: 0.3)
                ])
            }
            
            action.timingMode = .EaseInEaseOut
            player.runAction(SKAction.repeatActionForever(SKAction.sequence([
                SKAction.waitForDuration(1.25),
                action
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
    
    
    
    func setupTargets(playerTarget playerTarget: Target) {
        // Remove any old targets
        removeChildrenInArray(targets)
        targets.removeAll()
        
        // Get new targets
        targets = getTargetNodes(playerTarget: playerTarget, quantity: numberOfTargets)
        
        let winningTargetIndex = winningTargetRandom.nextInt()
        
        let winningTarget = targets[winningTargetIndex]
        winningTarget.fillColor = playerTarget.targetColor.value
        winningTarget.strokeColor = playerTarget.targetColor.value
        winningTarget.name = "winner"
        
        for target in targets {
            addChild(target)
        }
    }
    
    func getTargetNodes(playerTarget playerTarget: Target, quantity: Int) -> [SKShapeNode] {
        let targetPositions = getTargetPositions(quantity: quantity)
        var shapeNodes = [SKShapeNode]()
        for position in targetPositions {
            let targetColor = TargetColor.random(not: playerTarget.targetColor)
            let targetShape = TargetShape.random()
            
            
            let targetNode = getTargetNode(color: targetColor, shape: targetShape)
            targetNode.position = position
            
            shapeNodes.append(targetNode)
        }
        return shapeNodes
    }
    
    func getTargetNode(color color: TargetColor, shape: TargetShape) -> SKShapeNode {
        let target = shape.shapeNode
        target.fillColor = color.value
        target.strokeColor = color.value
        target.alpha = 0
        target.zPosition = 9
        target.name = "target"
        
        let showAction = SKAction.fadeInWithDuration(0.25)
        showAction.timingMode = .EaseIn
        target.runAction(showAction)
        
        let pointsGainedLabel = SKLabelNode(fontNamed: "SanFrancisco")
        pointsGainedLabel.verticalAlignmentMode = .Center
        pointsGainedLabel.horizontalAlignmentMode = .Center
        pointsGainedLabel.fontSize = 20
        pointsGainedLabel.name = "pointsGainedLabel"
        target.addChild(pointsGainedLabel)
        
        return target
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        player.removeActionForKey("Hint")
        player.removeActionForKey("Return")
        
        let maxMove: CGFloat = 120
        
        let touchLocation = touch.locationInNode(self)
        let previousLocation = touch.previousLocationInNode(self)
        
        var newX = player.position.x + (touchLocation.x - previousLocation.x)
        if newX > centerPoint.x + maxMove {
            newX = centerPoint.x + maxMove
        } else if newX < centerPoint.x - maxMove {
            newX = centerPoint.x - maxMove
        }
        
        var newY = player.position.y + (touchLocation.y - previousLocation.y)
        if newY > centerPoint.y + maxMove {
            newY = centerPoint.y + maxMove
        } else if newY < centerPoint.y - maxMove {
            newY = centerPoint.y - maxMove
        }
        
        player.position = CGPointMake(newX, newY)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Start timer after initial touch
        if !gameStarted {
            gameStarted = true
            resetTimer(timeForLevel)
        }
        
        if let playerShape = playerTarget?.shapeNode {
            for target in targets {
                if playerShape.intersectsNode(target) {
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
        player.runAction(returnAction, withKey: "Return")
        
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
        player.runAction(returnAction, withKey: "Return")
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
}

extension SKColor {
    var inverted: SKColor {
        get {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            
            self.getRed(&r, green: &g, blue: &b, alpha: &a)
            return SKColor(red: 1-r, green: 1-g, blue: 1-b, alpha: a)
        }
    }
}