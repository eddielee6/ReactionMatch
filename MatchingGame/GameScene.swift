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
    
    let scoreLabel = SKLabelNode(fontNamed: "SanFrancisco")
    var player = SKShapeNode()
    var score: Int = 0
    
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
    
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        guard let touch = touches.first else {
//            return
//        }
//
//        let touchLocation = touch.locationInNode(self)
//        if let touchTarget = physicsWorld.bodyAtPoint(touchLocation) {
//            if touchTarget.node!.physicsBody?.categoryBitMask == SpriteType.Player {
//                isFingerOnPlayer = true
//            }
//        }
//    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.locationInNode(self)
        let previousLocation = touch.previousLocationInNode(self)
        
        let newX = player.position.x + (touchLocation.x - previousLocation.x)
        let newY = player.position.y + (touchLocation.y - previousLocation.y)
        player.position = CGPointMake(newX, newY)
    }
    
    func getNodes(ofType: UInt32) -> Array<SKNode> {
        return getNodes(ofType, fromNodes: children)
    }
    
    func getNodes(ofType: UInt32, fromNodes: Array<SKNode>) -> Array<SKNode> {
        var matchedNodes = Array<SKNode>()
        
        for node in fromNodes {
            if (node.physicsBody?.categoryBitMask == ofType) {
                matchedNodes.append(node)
            }
        }
        
        return matchedNodes
    }
    
    func getNode(ofType: UInt32) -> SKNode? {
        return getNode(ofType, fromNodes: children)
    }
    
    func getNode(ofType: UInt32, fromNodes: Array<SKNode>) -> SKNode? {
        for node in fromNodes {
            if (node.physicsBody?.categoryBitMask == ofType) {
                return node
            }
        }
        
        return nil
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.locationInNode(self)
        
        let touchedNodes = nodesAtPoint(touchLocation)
        
        if let targetNode = getNode(SpriteType.Target, fromNodes: touchedNodes) as? SKShapeNode {
            if player.fillColor == targetNode.fillColor {
                print("win")
                score += 1
            } else {
                print("loose")
                score = 0
            }
            
            updateScore()
            newPuzzle()
            returnPlayer(0.1)
        } else {
            returnPlayer(0.5)
        }
    }
    
    func returnPlayer(withDuration: Double) {
        player.runAction(
            SKAction.moveTo(CGPoint(x: size.width/2, y: size.height/2), duration: NSTimeInterval(withDuration))
        )
    }
    
    func updateScore() {
        scoreLabel.text = "Score: \(score)"
    }
    
}
