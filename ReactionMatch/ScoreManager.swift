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

open class ScoreManager {
    
    struct FriendsScore {
        var highscore: Int64
        var name: String
    }
    
    static let sharedInstance = ScoreManager()
    
    var focusDelegate: ScoreManagerFocusDelegate?
    
    fileprivate var gameCentreEnabled: Bool = false
    
    var isAuthenticated: Bool {
        return GKLocalPlayer.localPlayer().isAuthenticated
    }
    
    
    // MARK: Authentication
    func authenticateLocalPlayer(_ viewController: UIViewController) {
        print("authenticateLocalPlayer")
        
        var scoreManagerDidTakeFocus: Bool = false
        
        GKLocalPlayer.localPlayer().authenticateHandler = { (gameCentreLoginViewController, error) in
            if let gameCentreLoginViewController = gameCentreLoginViewController {
                
                if let focusDelegate = self.focusDelegate {
                    focusDelegate.scoreManagerWillTakeFocus()
                    scoreManagerDidTakeFocus = true
                }
                
                print("will present gameCentreLoginViewController")
                
                viewController.present(gameCentreLoginViewController, animated: true, completion: nil)
                
            } else {
                if scoreManagerDidTakeFocus {
                    if let focusDelegate = self.focusDelegate {
                        focusDelegate.scoreManagerDidResignFocus()
                    }
                }
                
                guard error == nil else {
                    print(error!)
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
    
    fileprivate func updateLocalHighScores() {
        for gameType in [GameType.classic, GameType.v2] {
            updateLocalHighScoreForGameType(gameType)
        }
    }
    
    fileprivate func updateLocalHighScoreForGameType(_ gameType: GameType) {
        print("will updateLocalHighScoreForGameType: \(gameType.name)")
        
        let leaderboardRequest = GKLeaderboard(players: [GKLocalPlayer.localPlayer()])
        leaderboardRequest.identifier = gameType.leaderboardIdentifier
        leaderboardRequest.loadScores { (scores, error) in
            guard error == nil else {
                print(error!)
                return
            }
            
            let gameCentreHighScore = leaderboardRequest.localPlayerScore?.value
            let localHighScore = self.getLocalHighScoreForGameType(gameType)
            
            print("updating high score for game type \(gameType.name)")
            print("gameCentreHighScore: \(gameCentreHighScore ?? 0)")
            print("localHighScore: \(localHighScore)")
            
            if gameCentreHighScore != localHighScore {
                self.setLocalHighScore(gameCentreHighScore ?? 0, forGameType: gameType)
            }
        }
    }
    
    // MARK: Leaderboards
    func getFriendsHighScoresForGameType(_ gameType: GameType, withCompletionHandler completionHandler: @escaping ([FriendsScore]) -> ()) {
        guard isAuthenticated else {
            print("localPlayer.authenticated: \(self.isAuthenticated)")
            return
        }
        
        let leaderboardRequest = GKLeaderboard()
        leaderboardRequest.identifier = gameType.leaderboardIdentifier
        leaderboardRequest.playerScope = .friendsOnly
        leaderboardRequest.timeScope = .allTime
        leaderboardRequest.loadScores(completionHandler: { (scores, error) in
            guard error == nil else {
                print(error!)
                return
            }
            
            let scores: [FriendsScore]? = scores!.map({ score in
                let highScore: Int64 = score.value
                let name: String = score.player!.displayName ?? score.player!.alias ?? "Unknown"
                return FriendsScore(highscore: highScore, name: name)
            })
            
            completionHandler(scores ?? [FriendsScore]())
        })
    }
    
    
    // MARK: Score Recording
    func recordNewScore(_ newScore: Int64, forGameType gameType: GameType) {
        updateLocalHighScore(newScore, forGameType: gameType)
        
        if gameCentreEnabled {
            submitScoreToGameCentre(newScore, forGameType: gameType)
        }
    }
    
    fileprivate func updateLocalHighScore(_ newScore: Int64, forGameType gameType: GameType) {
        if newScore > getLocalHighScoreForGameType(gameType) {
            setLocalHighScore(newScore, forGameType: gameType)
        }
    }
    
    fileprivate func submitScoreToGameCentre(_ score: Int64, forGameType gameType: GameType) {
        let scoreToSubmit = GKScore(leaderboardIdentifier: gameType.leaderboardIdentifier)
        scoreToSubmit.value = Int64(score)
        
        GKScore.report([scoreToSubmit], withCompletionHandler: { error in
            if let error = error {
                print(error.localizedDescription)
            }
        })
    }
    
    
    // MARK: Get High Score
    func getHighScoreForGameType(_ gameType: GameType) -> Int64 {
        return getLocalHighScoreForGameType(gameType)
    }
    
    
    // MARK: Local Cache
    fileprivate func setLocalHighScore(_ score: Int64, forGameType gameType: GameType) {
        let defaults: UserDefaults = UserDefaults.standard
        
        defaults.set(NSNumber(value: score as Int64), forKey: "highScore-\(gameType.name)")
        defaults.synchronize()
    }
    
    fileprivate func getLocalHighScoreForGameType(_ gameType: GameType) -> Int64 {
        let defaults: UserDefaults = UserDefaults.standard
        
        if let highScore = defaults.object(forKey: "highScore-\(gameType.name)") as? NSNumber {
            return highScore.int64Value
        }
        
        return 0
    }
}
