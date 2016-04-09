//
//  GameScene.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 18/01/2016.
//  Copyright (c) 2016 Eddie Lee. All rights reserved.
//

import SpriteKit
import GameKit

class GameScene: SKScene {
    
    let successSoundAction = SKAction.playSoundFileNamed("success.wav", waitForCompletion: false)
    let failSondAction = SKAction.playSoundFileNamed("fail.wav", waitForCompletion: false)
    
    var winningTargetRandom = GKRandomDistribution(lowestValue: 1, highestValue: 4)
    
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
    var targets = Array<SKShapeNode>()
    
    var centerPoint: CGPoint = CGPoint.zero
    
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
        
        let playerColour = ShapeColor.random()
        let playerShape = TargetShape.random()
        
        let playerShapeNode = playerShape.shapeNode
        playerShapeNode.name = "player-shape-node"
        playerShapeNode.fillColor = playerColour.value
        playerShapeNode.strokeColor = SKColor.whiteColor()
        
        player.removeAllChildren()
        player.addChild(playerShapeNode)
        
        addNewTargets(playerColour)
        
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
    
    func createTarget(withColour: SKColor) -> SKShapeNode {
        let targetShape = TargetShape.random()
        
        let target = targetShape.shapeNode
        target.fillColor = withColour
        target.strokeColor = withColour
        target.alpha = 0
        target.zPosition = 9
        target.name = "target"
        
        let pointsGainedLabel = SKLabelNode(fontNamed: "SanFrancisco")
        pointsGainedLabel.verticalAlignmentMode = .Center
        pointsGainedLabel.horizontalAlignmentMode = .Center
        pointsGainedLabel.fontSize = 20
        pointsGainedLabel.name = "pointsGainedLabel"
        target.addChild(pointsGainedLabel)
        
        return target
    }
    
    func addNewTargets(winningColour: ShapeColor) {
        // Remove any old targets
        removeChildrenInArray(targets)
        targets.removeAll()
        
        let targetDistance: CGFloat = 100
        
        let showAction = SKAction.fadeInWithDuration(0.25)
        showAction.timingMode = .EaseIn
        
        let winningTarget = winningTargetRandom.nextInt()
        
        let topTargetColour = ShapeColor.random(not: winningColour)
        let topTarget = createTarget(topTargetColour.value)
        topTarget.position = CGPoint(x: centerPoint.x, y: centerPoint.y + targetDistance)
        if (winningTarget == 1) {
            topTarget.fillColor = winningColour.value
            topTarget.strokeColor = winningColour.value
            topTarget.name = "winner"
        }
        addChild(topTarget)
        targets.append(topTarget)
        topTarget.runAction(showAction)
        
        let rightTargetColour = ShapeColor.random(not: winningColour)
        let rightTarget = createTarget(rightTargetColour.value)
        rightTarget.position = CGPoint(x: centerPoint.x + targetDistance, y: centerPoint.y)
        if (winningTarget == 2) {
            rightTarget.fillColor = winningColour.value
            rightTarget.strokeColor = winningColour.value
            rightTarget.name = "winner"
        }
        addChild(rightTarget)
        targets.append(rightTarget)
        rightTarget.runAction(showAction)
        
        let bottomTargetColour = ShapeColor.random(not: winningColour)
        let bottomTarget = createTarget(bottomTargetColour.value)
        bottomTarget.position = CGPoint(x: centerPoint.x, y: centerPoint.y - targetDistance)
        if (winningTarget == 3) {
            bottomTarget.fillColor = winningColour.value
            bottomTarget.strokeColor = winningColour.value
            bottomTarget.name = "winner"
        }
        addChild(bottomTarget)
        targets.append(bottomTarget)
        bottomTarget.runAction(showAction)
        
        let leftTargetColour = ShapeColor.random(not: winningColour)
        let leftTarget = createTarget(leftTargetColour.value)
        leftTarget.position = CGPoint(x: centerPoint.x - targetDistance, y: centerPoint.y)
        if (winningTarget == 4) {
            leftTarget.fillColor = winningColour.value
            leftTarget.strokeColor = winningColour.value
            leftTarget.name = "winner"
        }
        addChild(leftTarget)
        targets.append(leftTarget)
        leftTarget.runAction(showAction)
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
        
        if let playerShape = player.childNodeWithName("player-shape-node") as? SKShapeNode {
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