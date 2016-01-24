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
    var reason: String!
    
    var playAgainLabel = SKLabelNode()
    
    override func didMoveToView(view: SKView) {
        setGameOverState()
        showNewGameButton()
    }
    
    func setGameOverState() {
        backgroundColor = SKColor.whiteColor()

        // Game Over type
        let gameEndReasonLabel = SKLabelNode()
        gameEndReasonLabel.text = reason
        gameEndReasonLabel.horizontalAlignmentMode = .Center
        gameEndReasonLabel.fontSize = 45
        gameEndReasonLabel.fontColor = SKColor.blackColor()
        gameEndReasonLabel.position = CGPoint(x: size.width/2, y: size.height - 85)
        addChild(gameEndReasonLabel)
        
        let currentHighScore = scoreManager.getLocalHighScore()
        
        scoreManager.recordNewScore(newScore)
        
        let scoreLabel = SKLabelNode()
        scoreLabel.horizontalAlignmentMode = .Center
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = SKColor.blackColor()
        scoreLabel.position = CGPoint(x: size.width/2, y: gameEndReasonLabel.position.y - 60)
        addChild(scoreLabel)
        
        if newScore > currentHighScore {
            scoreLabel.text = "New High Score \(newScore)!!"
            let blinkAction = SKAction.sequence([
                SKAction.fadeAlphaTo(0.4, duration: 0.4),
                SKAction.fadeAlphaTo(1, duration: 0.4)
            ])
            scoreLabel.runAction(SKAction.repeatActionForever(blinkAction))
        } else {
            scoreLabel.text = "Score \(newScore)"
        }
    }
    
    func showNewGameButton() {
        runAction(SKAction.sequence([
            SKAction.waitForDuration(NSTimeInterval(0.3)),
            SKAction.runBlock({
                self.playAgainLabel.text = "Tap to Play Again"
                self.playAgainLabel.fontSize = 35
                self.playAgainLabel.fontColor = SKColor.blackColor()
                self.playAgainLabel.verticalAlignmentMode = .Center
                self.playAgainLabel.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
                self.addChild(self.playAgainLabel)
                
                let growAndShrink = SKAction.sequence([
                    SKAction.scaleBy(1.2, duration: 0.4),
                    SKAction.scaleBy(0.8333, duration: 0.4)
                ])
                self.playAgainLabel.runAction(SKAction.repeatActionForever(growAndShrink))
            })
        ]))
    }
    
    func startNewGame() {
        let reveal = SKTransition.doorwayWithDuration(0.5)
        let scene = GameScene(size: self.size)
        self.view?.presentScene(scene, transition:reveal)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        guard let touch = touches.first else {
//            return
//        }
//        
//        let touchLocation = touch.locationInNode(self)
//
//        if nodeAtPoint(touchLocation) == playAgainLabel {
            startNewGame()
//        }
    }
}