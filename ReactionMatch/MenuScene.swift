//
//  MenuScene.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 13/05/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {
    
    private enum NodeStackingOrder: CGFloat {
        case BackgroundImage
        case Interface
    }
    
    private let menuOptions = [
        (title: "Play Now", action: startGameV2, instant: false),
        (title: "Classic Mode", action: startClassicGame, instant: false),
        (title: "Leaderboard", action: showGameCenterLeaderboards, instant: true)
    ]
    
    override func didMoveToView(view: SKView) {
        setupBackground()
        addMenuButtons()
    }
    
    private func setupBackground() {
        backgroundColor = SKColor.whiteColor()
        let backgroundNode = SKSpriteNode(texture: Textures.getMenuScreenTexture(size))
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.zPosition = NodeStackingOrder.BackgroundImage.rawValue
        addChild(backgroundNode)
    }
    
    private func addMenuButtons() {
        for (i, menuOption) in menuOptions.enumerate() {
            let menuOptionLabel = SKLabelNode()
            menuOptionLabel.fontColor = SKColor.whiteColor()
            menuOptionLabel.name = "menu-option"
            menuOptionLabel.text = menuOption.title
            menuOptionLabel.zPosition = NodeStackingOrder.Interface.rawValue
            
            menuOptionLabel.position = CGPoint(
                x: size.width/2,
                y: size.height - (size.height * CGFloat(i+1)) / (CGFloat(menuOptions.count) + 1))
            menuOptionLabel.fontSize = 45
            menuOptionLabel.verticalAlignmentMode = .Center
            
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
        if let matchingGameViewController = self.view?.window?.rootViewController as? MatchingGameViewController {
            matchingGameViewController.showLeaderboard()
        }
    }
    
    private func startGameWithType(gameType: GameType) {
        let matchingGameScene = MatchingGameScene(size: size)
        matchingGameScene.scaleMode = scaleMode
        matchingGameScene.settings = gameType.matchingGameSettings
        
        view?.presentScene(matchingGameScene)
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
                        if selectedMenuOption.instant {
                            action(self)()
                        } else {
                            labelNode.runAction(SKAction.sequence([
                                SKAction.group([
                                    SKAction.scaleTo(0.2, duration: 0.15),
                                    SKAction.fadeOutWithDuration(0.15)
                                ]),
                                SKAction.runBlock({
                                    action(self)()
                                })
                            ]))
                        }
                    }
                }
            }
        }
    }
}