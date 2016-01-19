//
//  GameScene.swift
//  MatchingGame
//
//  Created by Eddie Lee on 18/01/2016.
//  Copyright (c) 2016 Eddie Lee. All rights reserved.
//

import SpriteKit

struct SpriteType {
    static let None: UInt32 = 0
    static let Player: UInt32 = 1
    static let Target: UInt32 = 2
}

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
    
    let shapeSize = CGSize(width: 30, height: 30)
    
    let scoreLabel = SKLabelNode()
    let timeLabel = SKLabelNode()
    var player = SKShapeNode()
    var score: Int = 0
    var timeRemaining: Double = 0
    
    override func didMoveToView(view: SKView) {
        // No gravity
        physicsWorld.gravity = CGVectorMake(0, 0)
        
        backgroundColor = SKColor.whiteColor()
        
        player = SKShapeNode(rectOfSize: shapeSize)
        player.fillColor = SKColor.redColor()
        player.position = CGPoint(x: size.width/2, y: size.height/2)
        player.physicsBody = SKPhysicsBody(rectangleOfSize: shapeSize)
        player.physicsBody?.dynamic = true
        player.physicsBody?.categoryBitMask = SpriteType.Player
        player.physicsBody?.contactTestBitMask = SpriteType.Target
        player.physicsBody?.collisionBitMask = SpriteType.None
        player.physicsBody?.usesPreciseCollisionDetection = true
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
    
    func createTarget() -> SKShapeNode {
        let target = SKShapeNode(rectOfSize: shapeSize)
        target.physicsBody = SKPhysicsBody(rectangleOfSize: shapeSize)
        target.fillColor = SKColor.greenColor()
        target.physicsBody?.dynamic = true
        target.physicsBody?.categoryBitMask = SpriteType.Target
        target.physicsBody?.contactTestBitMask = SpriteType.Player
        target.physicsBody?.collisionBitMask = SpriteType.None
        target.zPosition = 9
        return target
    }
    
    func newPuzzle() {
        removeTargets()
        addTargets()
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
        let targets = getNodes(SpriteType.Target)
        removeChildrenInArray(targets)
    }
    
    func addTargets() {
        let targetDistance: CGFloat = 100
        
        let winningTarget = TargetType.randomType()
        
        let topTarget = createTarget()
        topTarget.position = CGPoint(x: size.width/2, y: (size.height/2) + targetDistance)
        if (winningTarget == TargetType.Top) {
            topTarget.fillColor = SKColor.redColor()
        }
        addChild(topTarget)
        
        let rightTarget = createTarget()
        rightTarget.position = CGPoint(x: (size.width/2) + targetDistance, y: size.height/2)
        if (winningTarget == TargetType.Right) {
            rightTarget.fillColor = SKColor.redColor()
        }
        addChild(rightTarget)
        
        let bottomTarget = createTarget()
        bottomTarget.position = CGPoint(x: size.width/2, y: (size.height/2) - targetDistance)
        if (winningTarget == TargetType.Bottom) {
            bottomTarget.fillColor = SKColor.redColor()
        }
        addChild(bottomTarget)
        
        let leftTarget = createTarget()
        leftTarget.position = CGPoint(x: (size.width/2) - targetDistance, y: size.height/2)
        if (winningTarget == TargetType.Left) {
            leftTarget.fillColor = SKColor.redColor()
        }
        addChild(leftTarget)
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
    
    func getNodes(ofType: UInt32) -> Array<SKNode> {
        return children.filter({
            return $0.physicsBody?.categoryBitMask == ofType
        })
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let targets = getNodes(SpriteType.Target) as! Array<SKShapeNode>
        for target in targets {
            if player.intersectsNode(target) {
                if player.fillColor == target.fillColor {
                    

                    let pointsGained = Int(ceil(timeRemaining / 0.1))
                    
                    stopTimer()
                    
                    score += pointsGained
                    updateScore()
                    
                    let resetTime = 0.25
                    
                    self.returnPlayer(resetTime)

                    
                    for loosingTarget in self.getLoosingTargets() {
                        loosingTarget.runAction(SKAction.scaleBy(0, duration: resetTime))
                    }
             
                    target.runAction(SKAction.sequence([
                        SKAction.group([
                            SKAction.scaleBy(2, duration: resetTime),
                            SKAction.runBlock({
                                let pointsLabel = SKLabelNode(fontNamed: "SanFrancisco")
                                pointsLabel.verticalAlignmentMode = .Center
                                pointsLabel.horizontalAlignmentMode = .Center
                                pointsLabel.fontSize = 20
                                pointsLabel.text = "\(pointsGained)"
                                target.addChild(pointsLabel)
                            })
                        ]),
                        SKAction.runBlock({
                            self.newPuzzle()
                        })
                    ]))

                } else {
                    gameOver()
                }
                
                return
            }
        }
        
        returnPlayer(0.15)
    }
    
    func gameOver() {
        let transition = SKTransition.fadeWithColor(UIColor.blackColor(), duration: 0.5)
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
    
    func getLoosingTargets() -> Array<SKShapeNode> {
        let targets = getNodes(SpriteType.Target) as! Array<SKShapeNode>
        return targets.filter({
            return $0.fillColor == SKColor.greenColor()
        })
    }
    
    func updateScore() {
        scoreLabel.text = "Score: \(score)"
    }
    
}
