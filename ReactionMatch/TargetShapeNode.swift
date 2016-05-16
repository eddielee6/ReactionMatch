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
    
    private let pointsGainedLabel: SKLabelNode
    
    private let targetSize = CGSize(width: 40, height: 40)
    
    var shapeName: String {
        get {
            return "\(targetColor.name) \(targetShape.name)"
        }
    }
    
    init (targetColor: TargetColor, targetShape: TargetShape) {
        self.targetColor = targetColor
        self.targetShape = targetShape
        
        self.pointsGainedLabel = SKLabelNode(fontNamed: "SanFrancisco")
        
        super.init()
        
        pointsGainedLabel.verticalAlignmentMode = .Center
        pointsGainedLabel.horizontalAlignmentMode = .Center
        pointsGainedLabel.fontSize = 20
        self.addChild(pointsGainedLabel)
        
        self.path = self.targetShape.getShapeNode(targetSize).path
        self.fillColor = self.targetColor.value
        self.strokeColor = SKColor.whiteColor()
        self.lineWidth = 2
    }
    
    convenience init (targetShape: TargetShape) {
        self.init(targetColor: TargetColor.random(), targetShape: TargetShape.Square)
    }
    
    func setPointsGained(points: Int) {
        pointsGainedLabel.fontColor = SKColor.whiteColor() // targetColor.value.inverted
        pointsGainedLabel.text = String(points)
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