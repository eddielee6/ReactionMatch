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
    case Red, Maroon, Purple, Green, Orange, Cyan, Blue, Pink
}

extension TargetColor {
    var name: String {
        get {
            switch self {
            case .Red:
                return "red"
            case .Maroon:
                return "maroon"
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
                return SKColor(red: 255/255, green: 81/255, blue: 50/255, alpha: 1)
            case .Maroon:
                return SKColor(red: 157/255, green: 17/255, blue: 0/255, alpha: 1)
            case .Purple:
                return SKColor(red: 94/255, green: 49/255, blue: 147/255, alpha: 1)
            case .Green:
                return SKColor(red: 0/255, green: 144/255, blue: 81/255, alpha: 1)
            case .Orange:
                return SKColor(red: 255/255, green: 158/255, blue: 24/255, alpha: 1)
            case .Cyan:
                return SKColor(red: 0/255, green: 145/255, blue: 246/255, alpha: 1)
            case .Blue:
                return SKColor(red: 6/255, green: 86/255, blue: 147/255, alpha: 1)
            case .Pink:
                return SKColor(red: 255/255, green: 47/255, blue: 146/255, alpha: 1)
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