//
//  GameOverScene.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 19/01/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import SpriteKit

class GameOverScene: SKScene {
    
    enum StackingOrder: CGFloat {
        case BackgroundImage
        case Interface
    }
    
    let scoreManager = ScoreManager.sharedInstance
    
    var newScore: Int64!
    var reason: String!
    
    let growAndShrink = SKAction.sequence([
        SKAction.scaleBy(1.2, duration: 0.4),
        SKAction.scaleBy(0.8333, duration: 0.4)
    ])
    
    override func didMoveToView(view: SKView) {
        setGameOverState()
        showNewGameButton()
    }
    
    func setGameOverState() {
        // Set background
        let backgroundNode = SKSpriteNode(texture: Textures.getWhiteToGreyTextureOfSize(size))
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.zPosition = StackingOrder.BackgroundImage.rawValue
        addChild(backgroundNode)

        // Game Over type
        let gameEndReasonLabel = SKLabelNode()
        gameEndReasonLabel.text = reason
        gameEndReasonLabel.horizontalAlignmentMode = .Center
        gameEndReasonLabel.fontSize = 45
        gameEndReasonLabel.fontColor = SKColor.blackColor()
        gameEndReasonLabel.position = CGPoint(x: size.width/2, y: size.height - 85)
        gameEndReasonLabel.zPosition = StackingOrder.Interface.rawValue
        addChild(gameEndReasonLabel)
        
        let currentHighScore = scoreManager.getHighScore()
        
        scoreManager.recordNewScore(newScore)
        
        let scoreLabel = SKLabelNode()
        scoreLabel.horizontalAlignmentMode = .Center
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = SKColor.blackColor()
        scoreLabel.position = CGPoint(x: size.width/2, y: gameEndReasonLabel.position.y - 60)
        scoreLabel.zPosition = StackingOrder.Interface.rawValue
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
                let playAgainLabel = SKLabelNode()
                playAgainLabel.text = "Tap to Play Again"
                playAgainLabel.fontSize = 35
                playAgainLabel.fontColor = SKColor.blackColor()
                playAgainLabel.verticalAlignmentMode = .Center
                playAgainLabel.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
                playAgainLabel.zPosition = StackingOrder.Interface.rawValue
                self.addChild(playAgainLabel)
                
                playAgainLabel.runAction(SKAction.repeatActionForever(self.growAndShrink))
            })
        ]))
    }
    
    func startNewGame() {
        let reveal = SKTransition.doorwayWithDuration(0.5)
        let scene = MatchingGameScene(size: self.size)
        self.view?.presentScene(scene, transition:reveal)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        startNewGame()
    }
}