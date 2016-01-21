//
//  GameOverScene.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 19/01/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import SpriteKit
import GameKit

class GameOverScene: SKScene {
    
    let scoreManager = ScoreManager.sharedInstance
    var newScore: Int!
    
    override func didMoveToView(view: SKView) {
        backgroundColor = SKColor.blackColor()
        
        let currentHighScore = scoreManager.getLocalHighScore()
        
        scoreManager.recordNewScore(newScore)

        let scoreLabel = SKLabelNode(fontNamed: "SanFrancisco")
        
        if (newScore > currentHighScore) {
            scoreLabel.text = "New High Score: \(newScore)!!"
        } else {
            scoreLabel.text = "Score: \(newScore) High Score: \(currentHighScore)"
        }
        
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = SKColor.whiteColor()
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 80)
        addChild(scoreLabel)
        
        runAction(SKAction.sequence([
            SKAction.waitForDuration(NSTimeInterval(0.3)),
            SKAction.runBlock({
                let playAgainLabel = SKLabelNode(fontNamed: "SanFrancisco")
                playAgainLabel.text = "Tap to Play Again"
                playAgainLabel.fontSize = 35
                playAgainLabel.verticalAlignmentMode = .Center
                playAgainLabel.fontColor = SKColor.whiteColor()
                playAgainLabel.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
                self.addChild(playAgainLabel)
                
                let growAction = SKAction.scaleBy(1.2, duration: 0.4)
                let shrinkAction = SKAction.scaleBy(0.8333, duration: 0.4)
                let growAndShrink = SKAction.sequence([growAction, shrinkAction])
                playAgainLabel.runAction(SKAction.repeatActionForever(growAndShrink))

            })
        ]))
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        runAction(SKAction.runBlock() {
            let reveal = SKTransition.doorwayWithDuration(0.5)
            let scene = GameScene(size: self.size)
            self.view?.presentScene(scene, transition:reveal)
        })
    }
    
    
}