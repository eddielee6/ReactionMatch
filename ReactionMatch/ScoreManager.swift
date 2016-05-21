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
    
    struct FriendsScore {
        var highscore: Int64
        var name: String
    }
    
    static let sharedInstance = ScoreManager()
    
    var focusDelegate: ScoreManagerFocusDelegate?
    
    private var gameCentreEnabled: Bool = false
    
    var isAuthenticated: Bool {
        return GKLocalPlayer.localPlayer().authenticated
    }
    
    
    // MARK: Authentication
    func authenticateLocalPlayer(viewController: UIViewController) {
        print("authenticateLocalPlayer")
        
        var scoreManagerDidTakeFocus: Bool = false
        
        GKLocalPlayer.localPlayer().authenticateHandler = { (gameCentreLoginViewController, error) in
            if let gameCentreLoginViewController = gameCentreLoginViewController {
                
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
                
                guard error == nil else {
                    print(error)
                    return
                }
                
                print("localPlayer.authenticated: \(self.isAuthenticated)")
                
                if self.isAuthenticated {
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
        
        let leaderboardRequest = GKLeaderboard(players: [GKLocalPlayer.localPlayer()])
        leaderboardRequest.identifier = gameType.leaderboardIdentifier
        leaderboardRequest.loadScoresWithCompletionHandler { (scores, error) in
            guard error == nil else {
                print(error)
                return
            }
            
            let gameCentreHighScore = leaderboardRequest.localPlayerScore?.value
            let localHighScore = self.getLocalHighScoreForGameType(gameType)
            
            print("updating high score for game type \(gameType.name)")
            print("gameCentreHighScore: \(gameCentreHighScore)")
            print("localHighScore: \(localHighScore)")
            
            if gameCentreHighScore != localHighScore {
                self.setLocalHighScore(gameCentreHighScore ?? 0, forGameType: gameType)
            }
        }
    }
    
    // MARK: Leaderboards
    func getFriendsHighScoresForGameType(gameType: GameType, withCompletionHandler completionHandler: ([FriendsScore]) -> ()) {
        guard isAuthenticated else {
            print("localPlayer.authenticated: \(self.isAuthenticated)")
            return
        }
        
        let leaderboardRequest = GKLeaderboard()
        leaderboardRequest.identifier = gameType.leaderboardIdentifier
        leaderboardRequest.playerScope = .FriendsOnly
        leaderboardRequest.timeScope = .AllTime
        leaderboardRequest.loadScoresWithCompletionHandler({ (scores, error) in
            guard error == nil else {
                print(error)
                return
            }
            
            let scores: [FriendsScore]? = scores!.map({ score in
                let highScore: Int64 = score.value
                let name: String = score.player.displayName ?? score.player.alias ?? "Unknown"
                return FriendsScore(highscore: highScore, name: name)
            })
            
            completionHandler(scores ?? [FriendsScore]())
        })
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
        
        GKScore.reportScores([scoreToSubmit], withCompletionHandler: { error in
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