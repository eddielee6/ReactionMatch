//
//  TimeIndicatorNode.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 14/05/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import SpriteKit

class TimeIndicatorNode: SKSpriteNode {

    var indicatorStrokeColor = SKColor.gray
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

    fileprivate func getTimeIndicatorTextureOfSize() -> SKTexture {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()

        context?.setStrokeColor(indicatorStrokeColor.cgColor)
        context?.setLineWidth(indicatorStrokeWidth)
        context?.addPath(getTimeIndicatorPath(CGFloat(percent)))
        context?.strokePath()

        let spriteImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return SKTexture(image: spriteImage!)
    }

    fileprivate func getTimeIndicatorPath(_ strokeArcPercent: CGFloat) -> CGPath {
        let startAngle: CGFloat = 270
        let endAngle: CGFloat = startAngle + (360/100 * strokeArcPercent)

        let indicatorPath = UIBezierPath(
            arcCenter: CGPoint(x: size.width/2, y: size.height/2),
            radius: (size.width * 0.9) / 2,
            startAngle: startAngle * CGFloat(Double.pi) / 180,
            endAngle: endAngle * CGFloat(Double.pi) / 180,
            clockwise: true)

        return indicatorPath.cgPath
    }
}
