//
//  ShapeColor.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 06/04/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import SpriteKit
import GameKit

enum TargetColor: Int {
    case Red, Yellow, Purple, Green, Orange, Cyan, Blue, Pink
}

extension TargetColor {
    var name: String {
        get {
            switch self {
            case .Red:
                return "red"
            case .Yellow:
                return "yellow"
            case .Purple:
                return "purple"
            case .Green:
                return "green"
            case .Orange:
                return "orange"
            case .Cyan:
                return "cyan"
            case .Blue:
                return "blue"
            case .Pink:
                return "pink"
            }
        }
    }
}

extension TargetColor {
    var value: SKColor {
        get {
            switch self {
            case .Red:
                return SKColor(red: 234/255, green: 72/255, blue: 89/255, alpha: 1)
            case .Yellow:
                return SKColor(red: 240/255, green: 221/255, blue: 41/255, alpha: 1)
            case .Purple:
                return SKColor(red: 148/255, green: 20/255, blue: 141/255, alpha: 1)
            case .Green:
                return SKColor(red: 88/255, green: 222/255, blue: 99/255, alpha: 1)
            case .Orange:
                return SKColor(red: 235/255, green: 94/255, blue: 0/255, alpha: 1)
            case .Cyan:
                return SKColor(red: 67/255, green: 213/255, blue: 222/255, alpha: 1)
            case .Blue:
                return SKColor(red: 29/255, green: 45/255, blue: 222/255, alpha: 1)
            case .Pink:
                return SKColor(red: 234/255, green: 85/255, blue: 202/255, alpha: 1)
            }
        }
    }
}

extension TargetColor {
    private static let randomSource = GKRandomDistribution(lowestValue: 0, highestValue: count - 1)
    
    private static let count: Int = {
        var max: Int = 0
        while let _ = TargetColor(rawValue: max) { max += 1 }
        return max
    }()
    
    static func random() -> TargetColor {
        let colorValue = randomSource.nextInt()
        return TargetColor(rawValue: colorValue)!
    }
}

extension TargetColor {
    static func random(not notColor: TargetColor) -> TargetColor {
        let selectedColour = TargetColor.random()
        
        if selectedColour == notColor {
            return random(not: notColor)
        }
        
        return selectedColour
    }
}