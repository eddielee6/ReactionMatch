//
//  MenuScene.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 13/05/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {
    let menuOptions = [
        (title: "Play Now", action: startGameV2),
        (title: "Classic Mode", action: startClassicGame)
    ]
    
    override func didMoveToView(view: SKView) {
        addMenuButtons()
    }
    
    private func addMenuButtons() {
        let pulseAction = SKAction.repeatActionForever(SKAction.sequence([
            SKAction.scaleBy(1.1, duration: 0.35),
            SKAction.scaleBy(0.9, duration: 0.35)
        ]))
        
        
        for (i, menuOption) in menuOptions.enumerate() {
            let menuOptionLabel = SKLabelNode()
            menuOptionLabel.name = "menu-option"
            menuOptionLabel.text = menuOption.title
            
            menuOptionLabel.position = CGPoint(
                x: size.width/2,
                y: size.height - (size.height * CGFloat(i+1)) / (CGFloat(menuOptions.count) + 1))
            menuOptionLabel.fontSize = 45
            menuOptionLabel.verticalAlignmentMode = .Center
            
            menuOptionLabel.runAction(pulseAction)
            
            addChild(menuOptionLabel)
        }
    }
    
    private func startGameV2() {
        startGameWithType(.V2)
    }
    
    private func startClassicGame() {
        startGameWithType(.Classic)
    }
    
    private func showGameCenterLeaderboards() {
        
    }
    
    private func startGameWithType(gameType: GameType) {
        let matchingGameScene = MatchingGameScene(size: size)
        matchingGameScene.scaleMode = scaleMode
        matchingGameScene.settings = gameType.matchingGameSettings
        
        let transition = SKTransition.doorsOpenVerticalWithDuration(0.5)
        view?.presentScene(matchingGameScene, transition: transition)
    }
}

// MARK: Input
extension MenuScene {
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.locationInNode(self)
        
        enumerateChildNodesWithName("menu-option") { node, _ in
            if node.containsPoint(touchLocation) {
                if let labelNode = node as? SKLabelNode {
                    if let selectedMenuOption = self.menuOptions.filter({$0.title == labelNode.text}).first {
                        let action = selectedMenuOption.action
                        action(self)()
                    }
                }
            }
        }
    }
}