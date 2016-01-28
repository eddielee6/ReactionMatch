//
//  GameScene.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 18/01/2016.
//  Copyright (c) 2016 Eddie Lee. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    let scoreLabel = SKLabelNode()
    let stateLabel = SKLabelNode()
    
    var gameStarted: Bool = false
    var score: Int = 0
    var levelsPlayed: Int = 0
    
    let baseTimeForLevel: Double = 1.2
    let minTimeForLevel: Double = 0.4
    var timeForLevel: Double = 1.2
    var timeRemaining: Double = 0
    
    var player = SKShapeNode()
    var targets = Array<SKShapeNode>()
    
    var centerPoint: CGPoint = CGPoint.zero
    
    override func didMoveToView(view: SKView) {
        setupInitialState()
        drawNewPuzzle()
    }
    
    func setupInitialState() {
        // Background
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
        
        let texture = SKTexture(CGImage: image.CGImage!)
        let backgroundNode = SKSpriteNode(texture: texture)
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
        stateLabel.text = "Ready"
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
        
        centerPoint = CGPoint(x: size.width/2, y: size.height/2 - 60)
        
        // Player
        player = SKShapeNode(rectOfSize: CGSize(width: 30, height: 30), cornerRadius: 5.0)
        player.position = centerPoint
        player.zPosition = 10
        addChild(player)
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
            if winningTarget.position.x > player.position.x {
                let action = SKAction.sequence([
                    SKAction.moveToX(player.position.x + 50, duration: 0.25),
                    SKAction.moveToX(centerPoint.x, duration: 0.25)
                ])
                action.timingMode = .EaseInEaseOut
                player.runAction(action, withKey: "Hint")
            } else if winningTarget.position.x < player.position.x {
                let action = SKAction.sequence([
                    SKAction.moveToX(player.position.x - 50, duration: 0.25),
                    SKAction.moveToX(centerPoint.x, duration: 0.25)
                ])
                action.timingMode = .EaseInEaseOut
                player.runAction(action, withKey: "Hint")
            } else if winningTarget.position.y > player.position.y {
                let action = SKAction.sequence([
                    SKAction.moveToY(player.position.y + 50, duration: 0.25),
                    SKAction.moveToY(centerPoint.y, duration: 0.25)
                ])
                action.timingMode = .EaseInEaseOut
                player.runAction(action, withKey: "Hint")
            } else if winningTarget.position.y < player.position.y {
                let action = SKAction.sequence([
                    SKAction.moveToY(player.position.y - 50, duration: 0.25),
                    SKAction.moveToY(centerPoint.y, duration: 0.25)
                ])
                action.timingMode = .EaseInEaseOut
                player.runAction(action, withKey: "Hint")
            }
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
        return target
    }
    
    func addNewTargets(winningColour: SKColor, otherColour: SKColor) {
        // Remove any old targets
        removeChildrenInArray(targets)
        targets.removeAll()
        
        let targetDistance: CGFloat = 100
        
        let showAction = SKAction.fadeInWithDuration(0.25)
        showAction.timingMode = .EaseIn
        
        let winningTarget = randomInt(1, max: 4)
        
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
        
        runAction(SKAction.playSoundFileNamed("success.wav", waitForCompletion: false))
        
        // Update score
        let pointsGained = getPointsForTime(timeRemaining)
        score += pointsGained
        scoreLabel.text = "Score \(score)"
        
        // Add points gained
        let pointsGainedLabel = SKLabelNode(fontNamed: "SanFrancisco")
        pointsGainedLabel.verticalAlignmentMode = .Center
        pointsGainedLabel.horizontalAlignmentMode = .Center
        pointsGainedLabel.fontSize = 20
        pointsGainedLabel.fontColor = self.invertColour(winningTarget.fillColor)
        pointsGainedLabel.text = "\(pointsGained)"
        winningTarget.addChild(pointsGainedLabel)
        
        let resetAnimationTime = 0.25
        
        // Grow winning target
        let growAction = SKAction.scaleBy(2, duration: 0.25)
        growAction.timingMode = .EaseIn
        winningTarget.runAction(growAction)
        
        // Fade out incorrect targets
        let shrinkAction = SKAction.scaleBy(0, duration: resetAnimationTime)
        shrinkAction.timingMode = .EaseIn
        targets.filter({
            return $0 != winningTarget
        }).forEach({
            $0.runAction(shrinkAction)
        })
        
        // Return player to center
        let returnAction = SKAction.moveTo(centerPoint, duration: NSTimeInterval(resetAnimationTime))
        returnAction.timingMode = .EaseInEaseOut
        player.runAction(returnAction, withKey: "Return")
        
        // Draw new puzzle
        runAction(SKAction.sequence([
            SKAction.waitForDuration(resetAnimationTime),
            SKAction.runBlock({
                self.drawNewPuzzle()
                self.resetTimer(self.timeForLevel)
            })
        ]))
    }
    
    func incorrectSelection() {
        gameOver("Wrong Selection")
    }
    
    func failedSelection() {
        let returnAction = SKAction.moveTo(centerPoint, duration: NSTimeInterval(0.15))
        returnAction.timingMode = .EaseInEaseOut
        player.runAction(returnAction, withKey: "Return")
    }
    
    func gameOver(reason: String) {
        print("Game Over: \(reason)")
        self.stateLabel.text = reason
        
        runAction(SKAction.playSoundFileNamed("fail.mp3", waitForCompletion: false))
        let transition = SKTransition.doorsCloseVerticalWithDuration(NSTimeInterval(0.5))
        let gameOverScene = GameOverScene(size: self.size)
        gameOverScene.newScore = score
        gameOverScene.reason = reason
        self.view?.presentScene(gameOverScene, transition: transition)
    }
    
    
    let possibleColours = [
        SKColor(red: 234/255, green: 72/255, blue: 89/255, alpha: 1), // red
        SKColor(red: 240/255, green: 221/255, blue: 41/255, alpha: 1), // yellow
        SKColor(red: 148/255, green: 20/255, blue: 141/255, alpha: 1), // purple
        SKColor(red: 88/255, green: 222/255, blue: 99/255, alpha: 1), // green
        SKColor(red: 235/255, green: 94/255, blue: 0/255, alpha: 1), // orange
        SKColor(red: 67/255, green: 213/255, blue: 222/255, alpha: 1), // cyan
        SKColor(red: 29/255, green: 45/255, blue: 222/255, alpha: 1), // blue
        SKColor(red: 234/255, green: 85/255, blue: 202/255, alpha: 1), // pink
    ]
    
    func randomInt(min: Int, max:Int) -> Int {
        return min + Int(arc4random_uniform(UInt32(max - min + 1)))
    }
    
    func getRandomColour(notColour: SKColor? = nil) -> SKColor {
        let colourIndex = randomInt(0, max: possibleColours.count - 1)
        let selectedColour = possibleColours[colourIndex]
        
        if selectedColour == notColour {
            return getRandomColour(notColour)
        }
        
        return selectedColour
    }
    
    func invertColour(colour: SKColor) -> SKColor {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        colour.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(red: 1-r, green: 1-g, blue: 1-b, alpha: a)
    }
}
