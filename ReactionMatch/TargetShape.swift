//
//  TargetShape.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 08/04/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import SpriteKit
import GameKit

private let shapeSize = CGSize(width: 35, height: 35)

enum TargetShape: Int {
    case Square
    case Circle
    case Triangle
}

extension TargetShape {
    var name: String {
        get {
            switch self {
            case .Square:
                return "square"
            case .Circle:
                return "circle"
            case .Triangle:
                return "triangle"
            }
        }
    }
}

extension TargetShape {
    var shapeNode: SKShapeNode {
        get {
            switch self {
            case .Square:
                return SKShapeNode(rectOfSize: shapeSize, cornerRadius: 5.0)
            case .Circle:
                return SKShapeNode(ellipseOfSize: shapeSize)
            case .Triangle:
                return SKShapeNode(triangleOfSize: shapeSize)
            }
        }
    }
}

extension TargetShape {
    private static let randomSource = GKRandomDistribution(lowestValue: 0, highestValue: count - 1)
    
    private static let count: Int = {
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


extension SKShapeNode {
    convenience init(triangleOfSize size: CGSize) {
        self.init()
        
        let trianglePath = CGPathCreateMutable()
        CGPathMoveToPoint(trianglePath, nil, -size.width/2, -size.height/2)
        CGPathAddLineToPoint(trianglePath, nil, size.width/2, -size.height/2)
        CGPathAddLineToPoint(trianglePath, nil, 0, size.height/2)
        CGPathAddLineToPoint(trianglePath, nil, -size.width/2, -size.height/2)
        
        path = trianglePath
    }
}