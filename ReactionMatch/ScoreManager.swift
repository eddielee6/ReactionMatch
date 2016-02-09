//
//  ScoreManager.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 21/01/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import UIKit
import GameKit

public class ScoreManager {
    public static let sharedInstance = ScoreManager()
    
    private let leaderboardIdentifier: String = "me.eddielee.ReactionMatch.TopScore"
    public var gameCentreEnabled: Bool = false
    
    public func authenticateLocalPlayer(viewController: UIViewController) {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = {(GameCentreLoginViewController, error) -> Void in
            if GameCentreLoginViewController != nil {
                viewController.presentViewController(GameCentreLoginViewController!, animated: true, completion: nil)
            } else {
                self.gameCentreEnabled = localPlayer.authenticated
                
                if self.gameCentreEnabled {
                    self.syncLocalScoreWithGameCentre()
                }
            }
        }
    }
    
    private func syncLocalScoreWithGameCentre() {
        let leaderBoardRequest = GKLeaderboard()
        leaderBoardRequest.identifier = leaderboardIdentifier
        
        leaderBoardRequest.loadScoresWithCompletionHandler { (scores, error) -> Void in
            if let gameCentreScore = leaderBoardRequest.localPlayerScore {
                let currentLocalHighScore = self.getLocalHighScore()
                let gameCentreHighScore = Int(gameCentreScore.value)
                if  gameCentreHighScore > currentLocalHighScore {
                    self.storeLocalHighScore(gameCentreHighScore)
                } else if currentLocalHighScore > gameCentreHighScore {
                    self.submitScoreToGameCentre(currentLocalHighScore)
                }
            }
        }
    }
    
    private func submitScoreToGameCentre(score: Int) {
        let scoreToSubmit = GKScore(leaderboardIdentifier: leaderboardIdentifier)
        scoreToSubmit.value = Int64(score)
        
        GKScore.reportScores([scoreToSubmit], withCompletionHandler: { (error: NSError?) -> Void in
            if error != nil {
                print(error!.localizedDescription)
            }
        })
    }
    
    private func storeLocalHighScore(score: Int) {
        if (score > getLocalHighScore()) {
            let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(score, forKey: "highScore")
            defaults.synchronize()
        }
    }
    
    public func getLocalHighScore() -> Int {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        if let highScore = defaults.objectForKey("highScore") as? Int {
            return highScore
        }
        
        return 0
    }
    
    public func recordNewScore(score: Int) {
        storeLocalHighScore(score)

        if gameCentreEnabled {
            submitScoreToGameCentre(score)
        }
    }
}