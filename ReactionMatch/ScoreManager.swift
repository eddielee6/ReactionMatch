//
//  ScoreManager.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 21/01/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import UIKit
import GameKit

public protocol ScoreManagerFocusDelegate {
    func scoreManagerWillTakeFocus()
    func scoreManagerDidResignFocus()
}

public class ScoreManager {
    
    public static let sharedInstance = ScoreManager()
    
    public var focusDelegate: ScoreManagerFocusDelegate?
    
    private let leaderboardIdentifier: String = "me.eddielee.ReactionMatch.TopScore"
    private var gameCentreEnabled: Bool = false
    
    
    // MARK: Authentication
    
    public func authenticateLocalPlayer(viewController: UIViewController) {
        let localPlayer = GKLocalPlayer.localPlayer()
        
        var scoreManagerDidTakeFocus: Bool = false
        
        localPlayer.authenticateHandler = { (GameCentreLoginViewController, error) -> () in
            if let gameCentreLoginViewController = GameCentreLoginViewController {
                
                if let focusDelegate = self.focusDelegate {
                    focusDelegate.scoreManagerWillTakeFocus()
                    scoreManagerDidTakeFocus = true
                }
                
                viewController.presentViewController(gameCentreLoginViewController, animated: true, completion: nil)
                
            } else {
                if scoreManagerDidTakeFocus {
                    if let focusDelegate = self.focusDelegate {
                        focusDelegate.scoreManagerDidResignFocus()
                    }
                }
                
                if localPlayer.authenticated {
                    self.gameCentreEnabled = true
                    self.updateLocalHighScore()
                } else {
                    self.gameCentreEnabled = false
                }
            }
        }
    }
    
    private func updateLocalHighScore() {
        let localPlayer = GKLocalPlayer.localPlayer()
        let localPlayerLeaderBoard = GKLeaderboard(players: [localPlayer])
        
        localPlayerLeaderBoard.identifier = leaderboardIdentifier
        
        localPlayerLeaderBoard.loadScoresWithCompletionHandler { (scores, error) -> () in
            if let localPlayerGameCentreHighScore = localPlayerLeaderBoard.localPlayerScore {
                if localPlayerGameCentreHighScore.value != self.getLocalHighScore() {
                    self.setLocalHighScore(localPlayerGameCentreHighScore.value)
                }
            }
        }
    }
    
    
    // MARK: Score Recording
    
    public func recordNewScore(newScore: Int64) {
        updateLocalHighScore(newScore)
        
        if gameCentreEnabled {
            submitScoreToGameCentre(newScore)
        }
    }
    
    private func updateLocalHighScore(newScore: Int64) {
        if newScore > getLocalHighScore() {
            setLocalHighScore(newScore)
        }
    }
    
    private func submitScoreToGameCentre(score: Int64) {
        let scoreToSubmit = GKScore(leaderboardIdentifier: leaderboardIdentifier)
        scoreToSubmit.value = Int64(score)
        
        GKScore.reportScores([scoreToSubmit], withCompletionHandler: { (error: NSError?) -> () in
            if let error = error {
                print(error.localizedDescription)
            }
        })
    }
    
    
    // MARK: Get High Score
    
    public func getHighScore() -> Int64 {
        return self.getLocalHighScore()
    }
    
    
    // MARK: Local Cache
    
    private func setLocalHighScore(score: Int64) {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        defaults.setObject(NSNumber(longLong: score), forKey: "highScore")
        defaults.synchronize()
    }
    
    private func getLocalHighScore() -> Int64 {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        if let highScore = defaults.objectForKey("highScore") as? NSNumber {
            return highScore.longLongValue
        }
        
        return 0
    }
}