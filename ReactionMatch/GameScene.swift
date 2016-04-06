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
    
    var winningTargetRandom: GKRandom!
    
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
    
    var player = SKShapeNode()
    var targets = Array<SKShapeNode>()
    
    var centerPoint: CGPoint = CGPoint.zero
    
    override func didMoveToView(view: SKView) {
        winningTargetRandom = GKRandomDistribution(lowestValue: 1, highestValue: 4)
        centerPoint = CGPoint(x: size.width/2, y: size.height/2 - 60)
        
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
        
        // Player
        player = SKShapeNode(rectOfSize: CGSize(width: 30, height: 30), cornerRadius: 5.0)
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
        
        let winningColour = getRandomColour()
        let otherColour = getRandomColour(winningColour)
        
        player.fillColor = winningColour
        player.strokeColor = SKColor.whiteColor()
        addNewTargets(winningColour, otherColour: otherColour)
        
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
            if player.fillColor == target.fillColor {
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
        let target = SKShapeNode(rectOfSize: CGSize(width: 35, height: 35), cornerRadius: 5.0)
        target.fillColor = withColour
        target.strokeColor = withColour
        target.alpha = 0
        target.zPosition = 9
        
        let pointsGainedLabel = SKLabelNode(fontNamed: "SanFrancisco")
        pointsGainedLabel.verticalAlignmentMode = .Center
        pointsGainedLabel.horizontalAlignmentMode = .Center
        pointsGainedLabel.fontSize = 20
        pointsGainedLabel.name = "pointsGainedLabel"
        target.addChild(pointsGainedLabel)
        
        return target
    }
    
    func addNewTargets(winningColour: SKColor, otherColour: SKColor) {
        // Remove any old targets
        removeChildrenInArray(targets)
        targets.removeAll()
        
        let targetDistance: CGFloat = 100
        
        let showAction = SKAction.fadeInWithDuration(0.25)
        showAction.timingMode = .EaseIn
        
        let winningTarget = winningTargetRandom.nextInt()
        
        let topTarget = createTarget(otherColour)
        topTarget.position = CGPoint(x: centerPoint.x, y: centerPoint.y + targetDistance)
        if (winningTarget == 1) {
            topTarget.fillColor = winningColour
            topTarget.strokeColor = winningColour
        }
        addChild(topTarget)
        targets.append(topTarget)
        topTarget.runAction(showAction)
        
        let rightTarget = createTarget(otherColour)
        rightTarget.position = CGPoint(x: centerPoint.x + targetDistance, y: centerPoint.y)
        if (winningTarget == 2) {
            rightTarget.fillColor = winningColour
            rightTarget.strokeColor = winningColour
        }
        addChild(rightTarget)
        targets.append(rightTarget)
        rightTarget.runAction(showAction)
        
        let bottomTarget = createTarget(otherColour)
        bottomTarget.position = CGPoint(x: centerPoint.x, y: centerPoint.y - targetDistance)
        if (winningTarget == 3) {
            bottomTarget.fillColor = winningColour
            bottomTarget.strokeColor = winningColour
        }
        addChild(bottomTarget)
        targets.append(bottomTarget)
        bottomTarget.runAction(showAction)
        
        let leftTarget = createTarget(otherColour)
        leftTarget.position = CGPoint(x: centerPoint.x - targetDistance, y: centerPoint.y)
        if (winningTarget == 4) {
            leftTarget.fillColor = winningColour
            leftTarget.strokeColor = winningColour
        }
        addChild(leftTarget)
        targets.append(leftTarget)
        leftTarget.runAction(showAction)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
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
        
        player.removeActionForKey("Hint")
        player.removeActionForKey("Return")
        player.position = CGPointMake(newX, newY)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Start timer after initial touch
        if !gameStarted {
            gameStarted = true
            resetTimer(timeForLevel)
        }
        
        for target in targets {
            if player.intersectsNode(target) {
                if player.fillColor == target.fillColor {
                    correctSelection(target)
                    break
                } else {
                    incorrectSelection()
                    break
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
    
    func getRandomColour(notColour: SKColor? = nil) -> SKColor {
        let selectedColour = ShapeColor.random().value
        
        if selectedColour == notColour {
            return getRandomColour(notColour)
        }
        
        return selectedColour
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