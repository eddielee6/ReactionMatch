//
//  SKShapeNodeExtentions.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 12/04/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import Foundation
import SpriteKit

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

extension SKShapeNode {
    convenience init(fivePointStarOfSize size: CGSize) {
        self.init()
        
        let starPathPoints = [
            CGPoint(x: 5.0, y: 9.5),
            CGPoint(x: 6.5, y: 6.5),
            CGPoint(x: 10.0, y: 6.0),
            CGPoint(x: 7.5, y: 4.0),
            CGPoint(x: 8.0, y: 0.5),
            CGPoint(x: 5.0, y: 2.0),
            CGPoint(x: 2.0, y: 0.5),
            CGPoint(x: 2.5, y: 4.0),
            CGPoint(x: 0, y: 6.0),
            CGPoint(x: 3.5, y: 6.5)]
        
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