//
//  TargetShape.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 08/04/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import SpriteKit
import GameKit

enum TargetShape: Int {
    case square
    case circle
    case triangle
    case star
}

extension TargetShape {
    var name: String {
        get {
            switch self {
            case .square:
                return "square"
            case .circle:
                return "circle"
            case .triangle:
                return "triangle"
            case .star:
                return "star"
            }
        }
    }
}

extension TargetShape {
    func getShapeNode(_ shapeSize: CGSize) -> SKShapeNode {
        switch self {
        case .square:
            return SKShapeNode(rectOf: shapeSize, cornerRadius: 5.0)
        case .circle:
            return SKShapeNode(ellipseOf: shapeSize)
        case .triangle:
            return SKShapeNode(triangleOfSize: shapeSize)
        case .star:
            let visualOffset:CGFloat = 1.2 // Stars within standard rect are too small - boost them a bit
            let starShapeSize = CGSize(width: shapeSize.width * visualOffset , height: shapeSize.height * visualOffset)
            return SKShapeNode(fivePointStarOfSize: starShapeSize)
        }
    }
}

extension TargetShape {
    fileprivate static let randomSource = GKRandomDistribution(lowestValue: 0, highestValue: count - 1)
    
    fileprivate static let count: Int = {
        var max: Int = 0
        while let _ = TargetShape(rawValue: max) { max += 1 }
        return max
    }()
    
    static func random() -> TargetShape {
        let value = randomSource.nextInt()
        return TargetShape(rawValue: value)!
    }
}

extension TargetShape {
    static func random(not notShape: TargetShape) -> TargetShape {
        let selectedShape = TargetShape.random()
        
        if selectedShape == notShape {
            return random(not: notShape)
        }
        
        return selectedShape
    }
}
