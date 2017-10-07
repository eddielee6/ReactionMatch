//
//  GameType.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 14/05/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import Foundation

enum GameType {
    case classic, v2
}

extension GameType {
    var name: String {
        get {
            switch self {
            case .classic:
                return "classic"
            case .v2:
                return "v2"
            }
        }
    }
}

extension GameType {
    var leaderboardIdentifier: String {
        get {
            switch self {
            case .classic:
                return "me.eddielee.ReactionMatch.TopScore"
            case .v2:
                return "me.eddielee.ReactionMatch.TopScoreV2"
            }
        }
    }
}

extension GameType {
    var matchingGameSettings: MatchingGameSettings {
        get {
            var matchingGameSettings = MatchingGameSettings()
            matchingGameSettings.gameType = self
            
            switch self {
            case .classic:
                matchingGameSettings.gameMode = .colorMatch
                matchingGameSettings.minNumberOfTargets = 4
                matchingGameSettings.maxNumberOfTargets = 4
                matchingGameSettings.newTargetAfterTurn = 0
                matchingGameSettings.newTargetIncrement = 0
            case .v2:
                matchingGameSettings.gameMode = .shapeMatch
                matchingGameSettings.minNumberOfTargets = 2
                matchingGameSettings.maxNumberOfTargets = 8
                matchingGameSettings.newTargetAfterTurn = 5
                matchingGameSettings.newTargetIncrement = 2
            }
            
            return matchingGameSettings
        }
    }
}
