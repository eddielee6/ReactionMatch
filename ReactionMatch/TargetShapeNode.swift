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
        
        self.path = self.targetShape.getShapeNode(targetSize).path
        self.fillColor = self.targetColor.value
        self.strokeColor = self.targetColor.value
        
        addPointsLabel()
    }
    
    private func addPointsLabel() {
        let pointsGainedLabel = SKLabelNode(fontNamed: "SanFrancisco")
        pointsGainedLabel.verticalAlignmentMode = .Center
        pointsGainedLabel.horizontalAlignmentMode = .Center
        pointsGainedLabel.fontSize = 20
        pointsGainedLabel.name = "pointsGainedLabel"
        self.addChild(pointsGainedLabel)
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