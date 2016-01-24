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
    
    override func didMoveToView(view: SKView) {
        setupInitialState()
        drawNewPuzzle()
    }
    
    func setupInitialState() {
        backgroundColor = SKColor.whiteColor()
        
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
        stateLabel.runAction(SKAction.repeatActionForever(blinkAction))
        
        // Player
        player = SKShapeNode(rectOfSize: CGSize(width: 30, height: 30), cornerRadius: 5.0)
        player.fillColor = SKColor.redColor()
        player.position = CGPoint(x: size.width/2, y: size.height/2)
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
        addNewTargets(winningColour, otherColour: otherColour)
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
        
        let winningTarget = randomInt(1, max: 4)
        
        let topTarget = createTarget(otherColour)
        topTarget.position = CGPoint(x: size.width/2, y: (size.height/2) + targetDistance)
        if (winningTarget == 1) {
            topTarget.fillColor = winningColour
        }
        addChild(topTarget)
        targets.append(topTarget)
        topTarget.runAction(showAction)
        
        let rightTarget = createTarget(otherColour)
        rightTarget.position = CGPoint(x: (size.width/2) + targetDistance, y: size.height/2)
        if (winningTarget == 2) {
            rightTarget.fillColor = winningColour
        }
        addChild(rightTarget)
        targets.append(rightTarget)
        rightTarget.runAction(showAction)
        
        let bottomTarget = createTarget(otherColour)
        bottomTarget.position = CGPoint(x: size.width/2, y: (size.height/2) - targetDistance)
        if (winningTarget == 3) {
            bottomTarget.fillColor = winningColour
        }
        addChild(bottomTarget)
        targets.append(bottomTarget)
        bottomTarget.runAction(showAction)
        
        let leftTarget = createTarget(otherColour)
        leftTarget.position = CGPoint(x: (size.width/2) - targetDistance, y: size.height/2)
        if (winningTarget == 4) {
            leftTarget.fillColor = winningColour
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
        
        let screenCentre = CGPoint(x: size.width/2, y: (size.height/2))
        
        var newX = player.position.x + (touchLocation.x - previousLocation.x)
        if newX > screenCentre.x + maxMove {
            newX = screenCentre.x + maxMove
        } else if newX < screenCentre.x - maxMove {
            newX = screenCentre.x - maxMove
        }
        
        var newY = player.position.y + (touchLocation.y - previousLocation.y)
        if newY > screenCentre.y + maxMove {
            newY = screenCentre.y + maxMove
        } else if newY < screenCentre.y - maxMove {
            newY = screenCentre.y - maxMove
        }
        
        player.removeActionForKey("Return")
        player.position = CGPointMake(newX, newY)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Start timer after initial touch
        if !gameStarted {
            gameStarted = true
            resetTimer(timeForLevel)
        }
        
        //let targets = getNodes("target") as! Array<SKShapeNode>
        targets.forEach({
            if player.intersectsNode($0) {
                if player.fillColor == $0.fillColor {
                    correctSelection($0)
                } else {
                    incorrectSelection()
                }
            } else {
                failedSelection()
            }
        })
    }
    
    func correctSelection(winningTarget: SKShapeNode) {
        stopTimer()
        
        runAction(SKAction.playSoundFileNamed("success.wav", waitForCompletion: false))
        
        // Update score
        let pointsGained = getPointsForTime(timeRemaining)
        score += pointsGained
        scoreLabel.text = "Score \(score)"
        
        // Return player to center
        player.runAction(
            SKAction.moveTo(CGPoint(x: size.width/2, y: size.height/2), duration: NSTimeInterval(0.25)),
            withKey: "Return"
        )
        
        // Enhance winning target
        winningTarget.runAction(SKAction.sequence([
            SKAction.group([
                SKAction.scaleBy(2, duration: 0.25),
                SKAction.runBlock({
                    // Print points gained
                    let pointsGainedLabel = SKLabelNode(fontNamed: "SanFrancisco")
                    pointsGainedLabel.verticalAlignmentMode = .Center
                    pointsGainedLabel.horizontalAlignmentMode = .Center
                    pointsGainedLabel.fontSize = 20
                    pointsGainedLabel.fontColor = self.invertColour(winningTarget.fillColor)
                    pointsGainedLabel.text = "\(pointsGained)"
                    winningTarget.addChild(pointsGainedLabel)
                })
            ]),
            SKAction.runBlock({
                self.drawNewPuzzle()
                self.resetTimer(self.timeForLevel)
            })
        ]))
        
        // Fade out incorrect targets
        targets.filter({
            return $0 != winningTarget
        }).forEach({
            $0.runAction(SKAction.scaleBy(0, duration: 0.25))
        })
    }
    
    func incorrectSelection() {
        gameOver("Wrong Selection")
    }
    
    func failedSelection() {
        player.runAction(
            SKAction.moveTo(CGPoint(x: size.width/2, y: size.height/2), duration: NSTimeInterval(0.15)),
            withKey: "Return"
        )
    }
    
    func gameOver(reason: String) {
        print("Game Over: \(reason)")
        self.stateLabel.text = reason
        
        runAction(SKAction.playSoundFileNamed("fail.mp3", waitForCompletion: false))
        let transition = SKTransition.doorsCloseVerticalWithDuration(NSTimeInterval(0.5))
        let gameOverScene = GameOverScene(size: self.size)
        gameOverScene.newScore = score
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
