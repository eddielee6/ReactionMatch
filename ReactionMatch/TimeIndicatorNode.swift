//
//  TimeIndicatorNode.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 14/05/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import SpriteKit

class TimeIndicatorNode: SKSpriteNode {
    
    var indicatorStrokeColor = SKColor.grayColor()
    var indicatorStrokeWidth: CGFloat = 4
    
    var percent: Double = 0 {
        didSet {
            if oldValue != percent {
                if percent <= 0 {
                    texture = nil
                } else {
                    texture = getTimeIndicatorTextureOfSize()
                }
            }
        }
    }
    
    private func getTimeIndicatorTextureOfSize() -> SKTexture {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetStrokeColorWithColor(context, indicatorStrokeColor.CGColor)
        CGContextSetLineWidth(context, indicatorStrokeWidth)
        CGContextAddPath(context, getTimeIndicatorPath(CGFloat(percent)))
        CGContextStrokePath(context)
        
        let spriteImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: spriteImage)
    }
    
    private func getTimeIndicatorPath(strokeArcPercent: CGFloat) -> CGPath {
        let startAngle: CGFloat = 270
        let endAngle: CGFloat = startAngle + (360/100 * strokeArcPercent)
        
        let indicatorPath = UIBezierPath(
            arcCenter: CGPoint(x: size.width/2, y: size.height/2),
            radius: (size.width * 0.9) / 2,
            startAngle: startAngle * CGFloat(M_PI) / 180,
            endAngle: endAngle * CGFloat(M_PI) / 180,
            clockwise: true)
        
        return indicatorPath.CGPath
    }
}