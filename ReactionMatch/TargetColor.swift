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
    case red, maroon, purple, green, orange, cyan, blue, pink
}

extension TargetColor {
    var name: String {
        switch self {
        case .red:
            return "red"
        case .maroon:
            return "maroon"
        case .purple:
            return "purple"
        case .green:
            return "green"
        case .orange:
            return "orange"
        case .cyan:
            return "cyan"
        case .blue:
            return "blue"
        case .pink:
            return "pink"
        }
    }
}

extension TargetColor {
    var value: SKColor {
        switch self {
        case .red:
            return SKColor(red: 255/255, green: 81/255, blue: 50/255, alpha: 1)
        case .maroon:
            return SKColor(red: 157/255, green: 17/255, blue: 0/255, alpha: 1)
        case .purple:
            return SKColor(red: 94/255, green: 49/255, blue: 147/255, alpha: 1)
        case .green:
            return SKColor(red: 0/255, green: 144/255, blue: 81/255, alpha: 1)
        case .orange:
            return SKColor(red: 255/255, green: 158/255, blue: 24/255, alpha: 1)
        case .cyan:
            return SKColor(red: 0/255, green: 145/255, blue: 246/255, alpha: 1)
        case .blue:
            return SKColor(red: 6/255, green: 86/255, blue: 147/255, alpha: 1)
        case .pink:
            return SKColor(red: 255/255, green: 47/255, blue: 146/255, alpha: 1)
        }
    }
}

extension TargetColor {
    fileprivate static let randomSource = GKRandomDistribution(lowestValue: 0, highestValue: count - 1)

    fileprivate static let count: Int = {
        var max: Int = 0
        while TargetColor(rawValue: max) != nil { max += 1 }
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
