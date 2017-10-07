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

    var targetSize: CGSize = CGSize(width: 40, height: 40) {
        didSet {
            path = targetShape.getShapeNode(targetSize).path
        }
    }

    var shapeName: String {
        return "\(targetColor.name) \(targetShape.name)"
    }

    init (targetColor: TargetColor, targetShape: TargetShape) {
        self.targetColor = targetColor
        self.targetShape = targetShape
        super.init()

        setupPointsGainedLabel()

        self.path = self.targetShape.getShapeNode(targetSize).path
        self.fillColor = self.targetColor.value
        self.strokeColor = SKColor.white
        self.lineWidth = 2
    }

    convenience init (targetShape: TargetShape) {
        self.init(targetColor: TargetColor.random(), targetShape: TargetShape.square)
    }

    fileprivate func setupPointsGainedLabel() {
        let pointsGainedLabel = SKLabelNode(fontNamed: "SanFranciscoDisplay-Bold")
        pointsGainedLabel.verticalAlignmentMode = .center
        pointsGainedLabel.horizontalAlignmentMode = .center
        pointsGainedLabel.fontSize = 550
        pointsGainedLabel.setScale(0.1)
        pointsGainedLabel.alpha = 0.75
        pointsGainedLabel.fontColor = SKColor.white
        pointsGainedLabel.name = "points-gained-label"
        addChild(pointsGainedLabel)
    }

    func setPointsGained(_ points: Int64) {
        let pointsGainedLabel = childNode(withName: "points-gained-label") as! SKLabelNode
        pointsGainedLabel.text = String(points)

        let action = SKAction.group([
            SKAction.scale(to: 1, duration: 0.5),
            SKAction.sequence([
                SKAction.wait(forDuration: 0.2),
                SKAction.fadeOut(withDuration: 0.3)
            ])
        ])
        action.timingMode = .easeIn

        pointsGainedLabel.run(action)
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
