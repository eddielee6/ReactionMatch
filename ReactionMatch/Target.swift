//
//  Target.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 09/04/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import SpriteKit
import GameKit

struct Target {
    let targetColor: TargetColor
    let targetShape: TargetShape
    let shapeNode: SKShapeNode
    
    init (targetColor: TargetColor, targetShape: TargetShape) {
        self.targetColor = targetColor
        self.targetShape = targetShape
        
        self.shapeNode = self.targetShape.shapeNode
        self.shapeNode.fillColor = self.targetColor.value
    }
    
    init () {
        let targetColor = TargetColor.random()
        let targetShape = TargetShape.random()
        
        self.init(targetColor: targetColor, targetShape: targetShape)
    }
}