//
//  GameStartScene.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 20/01/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import SpriteKit

class GameStartScene: SKScene {
    
    override func didMoveToView(view: SKView) {
        backgroundColor = SKColor.blackColor()
        
        let startLabel = SKLabelNode(fontNamed: "SanFrancisco")
        startLabel.text = "Tap to Start"
        startLabel.fontSize = 50
        startLabel.verticalAlignmentMode = .Center
        startLabel.fontColor = SKColor.whiteColor()
        startLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(startLabel)
        
        let growAction = SKAction.scaleBy(1.2, duration: 0.4)
        let shrinkAction = SKAction.scaleBy(0.8333, duration: 0.4)
        let growAndShrink = SKAction.sequence([growAction, shrinkAction])
        startLabel.runAction(SKAction.repeatActionForever(growAndShrink))
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        runAction(SKAction.runBlock() {
            let reveal = SKTransition.doorwayWithDuration(0.5)
            let scene = GameScene(size: self.size)
            self.view?.presentScene(scene, transition:reveal)
        })
    }
}