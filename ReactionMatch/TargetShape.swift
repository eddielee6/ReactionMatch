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
    case Star
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
            case .Star:
                return "star"
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
            case .Star:
                let visualOffset:CGFloat = 1.2 // Stars within standard rect are too small - boost them a bit
                let starShapeSize = CGSize(width: shapeSize.width * visualOffset , height: shapeSize.height * visualOffset)
                return SKShapeNode(fivePointStarOfSize: starShapeSize)
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
    
    convenience init(fivePointStarOfSize size: CGSize) {
        self.init()
        
        let starPathPoints = [
            CGPoint(x: 5.0, y: 0.5),
            CGPoint(x: 6.5, y: 3.5),
            CGPoint(x: 10.0, y: 4.0),
            CGPoint(x: 7.5, y: 6.0),
            CGPoint(x: 8.0, y: 9.5),
            CGPoint(x: 5.0, y: 8.0),
            CGPoint(x: 2.0, y: 9.5),
            CGPoint(x: 2.5, y: 6.0),
            CGPoint(x: 0, y: 4.0),
            CGPoint(x: 3.5, y: 3.5)]
        
        let starPathPointsGridSize:CGFloat = 10.0
        let gridSizeOffset = starPathPointsGridSize / 2.0
        
        let starPath = CGPathCreateMutable()
        
        for (i, starPathPoint) in starPathPoints.enumerate() {
            let xNormalised = (starPathPoint.x - gridSizeOffset) / starPathPointsGridSize
            let yNormalised = (starPathPoint.y - gridSizeOffset) / starPathPointsGridSize
            
            let xScaled = xNormalised * size.width
            let yScaled = yNormalised * size.height
            
            if i == 0 {
                CGPathMoveToPoint(starPath, nil, xScaled, yScaled)
            } else {
                CGPathAddLineToPoint(starPath, nil, xScaled, yScaled)
            }
        }
        CGPathCloseSubpath(starPath)
        
        path = starPath
    }
}