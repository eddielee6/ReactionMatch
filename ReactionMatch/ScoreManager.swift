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
    
    static let sharedInstance = ScoreManager()
    
    var focusDelegate: ScoreManagerFocusDelegate?
    
    private var gameCentreEnabled: Bool = false
    private var localPlayer: GKLocalPlayer!
    
    
    // MARK: Authentication
    func authenticateLocalPlayer(viewController: UIViewController) {
        print("authenticateLocalPlayer")
        
        localPlayer = GKLocalPlayer.localPlayer()
        
        var scoreManagerDidTakeFocus: Bool = false
        
        localPlayer.authenticateHandler = { (GameCentreLoginViewController, error) -> () in
            if let gameCentreLoginViewController = GameCentreLoginViewController {
                
                if let focusDelegate = self.focusDelegate {
                    focusDelegate.scoreManagerWillTakeFocus()
                    scoreManagerDidTakeFocus = true
                }
                
                print("will present gameCentreLoginViewController")
                
                viewController.presentViewController(gameCentreLoginViewController, animated: true, completion: nil)
                
            } else {
                if scoreManagerDidTakeFocus {
                    if let focusDelegate = self.focusDelegate {
                        focusDelegate.scoreManagerDidResignFocus()
                    }
                }
                
                print("localPlayer.authenticated: \(self.localPlayer.authenticated)")
                
                if self.localPlayer.authenticated {
                    self.gameCentreEnabled = true
                    self.updateLocalHighScores()
                } else {
                    self.gameCentreEnabled = false
                }
            }
        }
    }
    
    private func updateLocalHighScores() {
        for gameType in [GameType.Classic, GameType.V2] {
            updateLocalHighScoreForGameType(gameType)
        }
    }
    
    private func updateLocalHighScoreForGameType(gameType: GameType) {
        print("will updateLocalHighScoreForGameType: \(gameType.name)")
        
        let localPlayerLeaderBoard = GKLeaderboard(players: [localPlayer])
        
        localPlayerLeaderBoard.identifier = gameType.leaderboardIdentifier
        
        localPlayerLeaderBoard.loadScoresWithCompletionHandler { (scores, error) -> () in
            guard error == nil else {
                print(error)
                return
            }
            
            let gameCentreHighScore = localPlayerLeaderBoard.localPlayerScore?.value
            let localHighScore = self.getLocalHighScoreForGameType(gameType)
            
            print("updating high score for game type \(gameType.name)")
            print("gameCentreHighScore: \(gameCentreHighScore)")
            print("localHighScore: \(localHighScore)")
            
            if gameCentreHighScore != localHighScore {
                self.setLocalHighScore(gameCentreHighScore ?? 0, forGameType: gameType)
            }
        }
    }
    
    
    // MARK: Score Recording
    func recordNewScore(newScore: Int64, forGameType gameType: GameType) {
        updateLocalHighScore(newScore, forGameType: gameType)
        
        if gameCentreEnabled {
            submitScoreToGameCentre(newScore, forGameType: gameType)
        }
    }
    
    private func updateLocalHighScore(newScore: Int64, forGameType gameType: GameType) {
        if newScore > getLocalHighScoreForGameType(gameType) {
            setLocalHighScore(newScore, forGameType: gameType)
        }
    }
    
    private func submitScoreToGameCentre(score: Int64, forGameType gameType: GameType) {
        let scoreToSubmit = GKScore(leaderboardIdentifier: gameType.leaderboardIdentifier)
        scoreToSubmit.value = Int64(score)
        
        GKScore.reportScores([scoreToSubmit], withCompletionHandler: { (error: NSError?) -> () in
            if let error = error {
                print(error.localizedDescription)
            }
        })
    }
    
    
    // MARK: Get High Score
    func getHighScoreForGameType(gameType: GameType) -> Int64 {
        return getLocalHighScoreForGameType(gameType)
    }
    
    
    // MARK: Local Cache
    private func setLocalHighScore(score: Int64, forGameType gameType: GameType) {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        defaults.setObject(NSNumber(longLong: score), forKey: "highScore-\(gameType.name)")
        defaults.synchronize()
    }
    
    private func getLocalHighScoreForGameType(gameType: GameType) -> Int64 {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        if let highScore = defaults.objectForKey("highScore-\(gameType.name)") as? NSNumber {
            return highScore.longLongValue
        }
        
        return 0
    }
}