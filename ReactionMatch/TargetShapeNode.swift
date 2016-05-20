//
//  TargetShapeNode.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 12/04/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import Foundation
import SpriteKit

class TargetShapeNode: SKShapeNode {
    let targetColor: TargetColor
    let targetShape: TargetShape
    
    private let targetSize = CGSize(width: 40, height: 40)
    
    var shapeName: String {
        get {
            return "\(targetColor.name) \(targetShape.name)"
        }
    }
    
    init (targetColor: TargetColor, targetShape: TargetShape) {
        self.targetColor = targetColor
        self.targetShape = targetShape
        super.init()
        
        setupPointsGainedLabel()
        
        self.path = self.targetShape.getShapeNode(targetSize).path
        self.fillColor = self.targetColor.value
        self.strokeColor = SKColor.whiteColor()
        self.lineWidth = 2
    }
    
    convenience init (targetShape: TargetShape) {
        self.init(targetColor: TargetColor.random(), targetShape: TargetShape.Square)
    }
    
    private func setupPointsGainedLabel() {
        let pointsGainedLabel = SKLabelNode()
        pointsGainedLabel.verticalAlignmentMode = .Center
        pointsGainedLabel.horizontalAlignmentMode = .Center
        pointsGainedLabel.fontSize = 550
        pointsGainedLabel.setScale(0.1)
        pointsGainedLabel.fontColor = SKColor.whiteColor()
        pointsGainedLabel.name = "points-gained-label"
        addChild(pointsGainedLabel)
    }
    
    func setPointsGained(points: Int) {
        let pointsGainedLabel = childNodeWithName("points-gained-label") as! SKLabelNode
        pointsGainedLabel.text = String(points)
        
        let action = SKAction.group([
            SKAction.scaleTo(1, duration: 0.5),
            SKAction.fadeOutWithDuration(0.5)
        ])
        action.timingMode = .EaseIn
        
        pointsGainedLabel.runAction(action)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TargetShapeNode {
    class func randomShapeNode() -> TargetShapeNode {
        let targetColor = TargetColor.random()
        let targetShape = TargetShape.random()
        
        return TargetShapeNode(targetColor: targetColor, targetShape: targetShape)
    }
}