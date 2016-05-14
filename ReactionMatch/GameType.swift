//
//  GameType.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 14/05/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import Foundation

enum GameType {
    case Classic, V2
}

extension GameType {
    var name: String {
        get {
            switch self {
            case .Classic:
                return "classic"
            case .V2:
                return "v2"
            }
        }
    }
}

extension GameType {
    var leaderboardIdentifier: String {
        get {
            switch self {
            case .Classic:
                return "me.eddielee.ReactionMatch.TopScore"
            case .V2:
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
            case .Classic:
                matchingGameSettings.gameMode = .ColorMatch
                matchingGameSettings.minNumberOfTargets = 4
                matchingGameSettings.maxNumberOfTargets = 4
                matchingGameSettings.newTargetAfterTurn = 0
                matchingGameSettings.newTargetIncrement = 0
            case .V2:
                matchingGameSettings.gameMode = .ShapeMatch
                matchingGameSettings.minNumberOfTargets = 2
                matchingGameSettings.maxNumberOfTargets = 8
                matchingGameSettings.newTargetAfterTurn = 5
                matchingGameSettings.newTargetIncrement = 2
            }
            
            return matchingGameSettings
        }
    }
}