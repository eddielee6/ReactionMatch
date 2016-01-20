//
//  GameOverScene.swift
//  MatchingGame
//
//  Created by Eddie Lee on 19/01/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import SpriteKit
import GameKit

class GameOverScene: SKScene {
    
    var gameScore: Int!
    
    override func didMoveToView(view: SKView) {
        let previousHighScore = getHighScore()
        
        storeHighScore(gameScore)
        let currentHighScore = getHighScore()
        
        backgroundColor = SKColor.blackColor()
        
        let scoreLabel = SKLabelNode(fontNamed: "SanFrancisco")
        
        if (currentHighScore > previousHighScore) {
            scoreLabel.text = "New High Score: \(gameScore)!!"
            
            if gameCentreEnabled() {
                submitScore(gameScore)
            }
        } else {
            scoreLabel.text = "Score: \(gameScore) High Score: \(currentHighScore)"
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
    
    func gameCentreEnabled() -> Bool {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        if let highScore = defaults.objectForKey("gameCentreEnabled") as? Bool {
            return highScore
        }
        
        return false
    }
    
    func storeHighScore(score: Int) {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        if (score > getHighScore()) {
            defaults.setObject(score, forKey: "highScore")
            defaults.synchronize()
        }
    }
    
    func submitScore(score: Int) {
        let leaderboardID = "me.eddielee.ReactionMatch.TopScore"
        let scoreToSubmit = GKScore(leaderboardIdentifier: leaderboardID)
        scoreToSubmit.value = Int64(score)
        
        GKScore.reportScores([scoreToSubmit], withCompletionHandler: { (error: NSError?) -> Void in
            if error != nil {
                print(error!.localizedDescription)
            }
        })
    }
    
    func getHighScore() -> Int {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        if let highScore = defaults.objectForKey("highScore") as? Int {
            return highScore
        }
        
        return 0
    }
}