//
//  GameType.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 14/05/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import Foundation

enum GameType {
    case classicMode, v2Mode
}

extension GameType {
    var name: String {
        switch self {
        case .classicMode:
            return "classic"
        case .v2Mode:
            return "v2"
        }
    }
}

extension GameType {
    var leaderboardIdentifier: String {
        switch self {
        case .classicMode:
            return "me.eddielee.ReactionMatch.TopScore"
        case .v2Mode:
            return "me.eddielee.ReactionMatch.TopScoreV2"
        }
    }
}

extension GameType {
    var matchingGameSettings: MatchingGameSettings {
        var matchingGameSettings = MatchingGameSettings()
        matchingGameSettings.gameType = self

        switch self {
        case .classicMode:
            matchingGameSettings.gameMode = .colorMatch
            matchingGameSettings.minNumberOfTargets = 4
            matchingGameSettings.maxNumberOfTargets = 4
            matchingGameSettings.newTargetAfterTurn = 0
            matchingGameSettings.newTargetIncrement = 0
        case .v2Mode:
            matchingGameSettings.gameMode = .shapeMatch
            matchingGameSettings.minNumberOfTargets = 2
            matchingGameSettings.maxNumberOfTargets = 8
            matchingGameSettings.newTargetAfterTurn = 5
            matchingGameSettings.newTargetIncrement = 2
        }

        return matchingGameSettings
    }
}
