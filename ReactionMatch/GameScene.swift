//
//  GameScene.swift
//  MatchingGame
//
//  Created by Eddie Lee on 18/01/2016.
//  Copyright (c) 2016 Eddie Lee. All rights reserved.
//

import SpriteKit

enum TargetType: UInt32 {
    case Top
    case Right
    case Bottom
    case Left
    
    private static let _count: TargetType.RawValue = {
        var maxValue: UInt32 = 0
        while let _ = TargetType(rawValue: ++maxValue) { }
        return maxValue
    }()
    
    static func randomType() -> TargetType {
        let rand = arc4random_uniform(_count)
        return TargetType(rawValue: rand)!
    }
}

class GameScene: SKScene {
    
    let scoreLabel = SKLabelNode()
    let timeLabel = SKLabelNode()
    var player = SKShapeNode()
    var score: Int = 0
    var timeRemaining: Double = 0
    
    let possibleColours = [SKColor.redColor(), SKColor.greenColor(), SKColor.blueColor(), SKColor.cyanColor(), SKColor.yellowColor(), SKColor.magentaColor(), SKColor.orangeColor(), SKColor.purpleColor()]
    
    override func didMoveToView(view: SKView) {
        backgroundColor = SKColor.whiteColor()
        
        player = SKShapeNode(rectOfSize: CGSize(width: 30, height: 30), cornerRadius: 5.0)
        player.fillColor = SKColor.redColor()
        player.position = CGPoint(x: size.width/2, y: size.height/2)
        player.name = "player"
        player.zPosition = 10
        addChild(player)
        
        // Score
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .Left
        scoreLabel.fontSize = 25
        scoreLabel.fontColor = SKColor.blackColor()
        scoreLabel.position = CGPoint(x: 10, y: size.height - 35)
        scoreLabel.zPosition = 10
        addChild(scoreLabel)
        
        // Timer
        timeLabel.text = "Remaining: 10"
        timeLabel.horizontalAlignmentMode = .Left
        timeLabel.fontSize = 25
        timeLabel.fontColor = SKColor.blackColor()
        timeLabel.position = CGPoint(x: 10, y: size.height - 65)
        timeLabel.zPosition = 10
        addChild(timeLabel)

        
        newPuzzle()
    }
    
    func getRandomColour(notColour: SKColor? = nil) -> SKColor {
        let colourIndex = Int(arc4random_uniform(UInt32(possibleColours.count)))
        let selectedColour = possibleColours[colourIndex]
        
        if selectedColour == notColour {
            return getRandomColour(notColour)
        }
        
        return selectedColour
    }
    
    func recolorPlayer(withColour: SKColor) {
        player.fillColor = withColour
    }
    
    func newPuzzle() {
        removeTargets()
        
        let winningColour = getRandomColour()
        let otherColour = getRandomColour(winningColour)
        recolorPlayer(winningColour)
        addTargets(winningColour, otherColour: otherColour)
        startTimer()
    }
    
    func stopTimer() {
        removeActionForKey("GameTimer")
        self.updateTimer(1)
    }
    
    func startTimer() {
        self.updateTimer(1)
        
        let timerInterval = 0.1
        runAction(SKAction.repeatActionForever(SKAction.sequence([
            SKAction.waitForDuration(timerInterval),
            SKAction.runBlock({
                if (self.timeRemaining <= 0) {
                    print("time expired")
                    self.removeActionForKey("GameTimer")
                    self.gameOver()
                } else {
                    self.updateTimer(self.timeRemaining - timerInterval)
                }
            })
        ])), withKey: "GameTimer")
    }
    
    func updateTimer(timeRemaining: Double) {
        self.timeRemaining = timeRemaining
        
        if (timeRemaining <= 0) {
            self.timeLabel.text = "Remaining: 0"
        } else {
            self.timeLabel.text = "Remaining: \(Int(ceil(timeRemaining / 0.1)))"
        }
    }
    
    func removeTargets() {
        let targets = getNodes("target")
        removeChildrenInArray(targets)
    }
    
    func createTarget(withColour: SKColor) -> SKShapeNode {
        let target = SKShapeNode(rectOfSize: CGSize(width: 35, height: 35), cornerRadius: 5.0)
        target.fillColor = withColour
        target.name = "target"
        target.alpha = 0
        target.zPosition = 9
        return target
    }
    
    func addTargets(winningColour: SKColor, otherColour: SKColor) {
        let targetDistance: CGFloat = 100
        
        let showAction = SKAction.fadeInWithDuration(0.25)
        
        let winningTarget = TargetType.randomType()
        
        let topTarget = createTarget(otherColour)
        topTarget.position = CGPoint(x: size.width/2, y: (size.height/2) + targetDistance)
        if (winningTarget == TargetType.Top) {
            topTarget.fillColor = winningColour
        }
        addChild(topTarget)
        topTarget.runAction(showAction)
        
        let rightTarget = createTarget(otherColour)
        rightTarget.position = CGPoint(x: (size.width/2) + targetDistance, y: size.height/2)
        if (winningTarget == TargetType.Right) {
            rightTarget.fillColor = winningColour
        }
        addChild(rightTarget)
        rightTarget.runAction(showAction)
        
        let bottomTarget = createTarget(otherColour)
        bottomTarget.position = CGPoint(x: size.width/2, y: (size.height/2) - targetDistance)
        if (winningTarget == TargetType.Bottom) {
            bottomTarget.fillColor = winningColour
        }
        addChild(bottomTarget)
        bottomTarget.runAction(showAction)
        
        let leftTarget = createTarget(otherColour)
        leftTarget.position = CGPoint(x: (size.width/2) - targetDistance, y: size.height/2)
        if (winningTarget == TargetType.Left) {
            leftTarget.fillColor = winningColour
        }
        addChild(leftTarget)
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
    
    func getNodes(ofType: String) -> Array<SKNode> {
        return children.filter({
            return $0.name == ofType
        })
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let targets = getNodes("target") as! Array<SKShapeNode>
        
        let winningTarget = targets.filter({
            return $0.fillColor == player.fillColor
        }).first!
        
        let loosingTargets = targets.filter({
            return $0.fillColor != player.fillColor
        })
        
        if player.intersectsNode(winningTarget) {
            let pointsGained = Int(ceil(timeRemaining / 0.1))
            
            stopTimer()
            
            score += pointsGained
            updateScore()
            
            let resetTime = 0.25
            
            self.returnPlayer(resetTime)
            
            loosingTargets.forEach({
                $0.runAction(SKAction.scaleBy(0, duration: resetTime))
            })
            
            winningTarget.runAction(SKAction.sequence([
                SKAction.group([
                    SKAction.scaleBy(2, duration: resetTime),
                    SKAction.runBlock({
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
                    self.newPuzzle()
                })
            ]))
        } else {
            let hitLoosingTarget = loosingTargets.contains({
                return player.intersectsNode($0);
            })
            
            if hitLoosingTarget {
                gameOver()
                return
            }
            
            returnPlayer(0.15)
        }
    }
    
    func gameOver() {
        let transition = SKTransition.doorsCloseVerticalWithDuration(NSTimeInterval(0.5))
        let gameOverScene = GameOverScene(size: self.size)
        gameOverScene.gameScore = score
        self.view?.presentScene(gameOverScene, transition: transition)
    }
    
    func returnPlayer(withDuration: Double) {
        player.runAction(
            SKAction.moveTo(CGPoint(x: size.width/2, y: size.height/2), duration: NSTimeInterval(withDuration)),
            withKey: "Return"
        )
    }
    
    func updateScore() {
        scoreLabel.text = "Score: \(score)"
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
