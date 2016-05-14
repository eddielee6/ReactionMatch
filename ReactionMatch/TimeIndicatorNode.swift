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
    
    var percentFull: Double = 0 {
        didSet {
            if percentFull <= 0 {
                texture = nil
            } else {
                texture = getTimeIndicatorTextureOfSize(CGFloat(percentFull))
            }
        }
    }
    
    private func getTimeIndicatorTextureOfSize(percentFull: CGFloat) -> SKTexture {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextAddPath(context, getTimeIndicatorPath(percentFull))
        CGContextSetStrokeColorWithColor(context, indicatorStrokeColor.CGColor)
        CGContextSetLineWidth(context, indicatorStrokeWidth)
        CGContextStrokePath(context)
        
        let spriteImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: spriteImage)
    }
    
    private func getTimeIndicatorPath(percentFull: CGFloat) -> CGPath {
        let startAngle: CGFloat = -90
        let endAngle: CGFloat = startAngle - (360/100 * percentFull)
        
        let indicatorPath = UIBezierPath(
            arcCenter: CGPoint(x: size.width/2, y: size.height/2),
            radius: (size.width * 0.9) / 2,
            startAngle: startAngle * CGFloat(M_PI) / 180,
            endAngle: endAngle * CGFloat(M_PI) / 180,
            clockwise: false)
        
        return indicatorPath.CGPath
    }
}