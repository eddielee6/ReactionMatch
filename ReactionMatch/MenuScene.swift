//
//  MenuScene.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 13/05/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {

    fileprivate enum NodeStackingOrder: CGFloat {
        case backgroundImage
        case effects
        case interface
    }

    fileprivate let menuOptions = [
        (title: "Play Now", action: startGameV2, instant: false),
        (title: "Classic Mode", action: startClassicGame, instant: false),
        (title: "Leaderboard", action: showGameCenterLeaderboards, instant: true)
    ]

    override func didMove(to view: SKView) {
        setupBackground()
        setupEffects()
        addMenuButtons()
    }

    fileprivate func setupBackground() {
        backgroundColor = SKColor.white
        let backgroundNode = SKSpriteNode(texture: Textures.getMenuScreenTexture(size))
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.zPosition = NodeStackingOrder.backgroundImage.rawValue
        addChild(backgroundNode)
    }

    fileprivate func setupEffects() {
        let blobEmiter = SKEmitterNode(fileNamed: "Blobs.sks")!
        blobEmiter.particlePositionRange = CGVector(dx: size.width, dy: size.height)
        blobEmiter.zPosition = NodeStackingOrder.effects.rawValue
        blobEmiter.position = CGPoint(x: size.width/2, y: size.height/2)
        self.addChild(blobEmiter)
    }

    fileprivate func addMenuButtons() {
        for (i, menuOption) in menuOptions.enumerated() {
            let menuOptionLabel = SKLabelNode()
            menuOptionLabel.fontColor = SKColor.white
            menuOptionLabel.name = "menu-option"
            menuOptionLabel.text = menuOption.title
            menuOptionLabel.zPosition = NodeStackingOrder.interface.rawValue

            menuOptionLabel.position = CGPoint(
                x: size.width/2,
                y: size.height - (size.height * CGFloat(i+1)) / (CGFloat(menuOptions.count) + 1))
            menuOptionLabel.fontSize = 45
            menuOptionLabel.verticalAlignmentMode = .center

            menuOptionLabel.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.wait(forDuration: 0.25),
                SKAction.fadeAlpha(to: 0.75, duration: 0.5),
                SKAction.fadeAlpha(to: 1, duration: 0.5)
            ])))

            addChild(menuOptionLabel)
        }
    }

    fileprivate func startGameV2() {
        startGameWithType(.v2Mode)
    }

    fileprivate func startClassicGame() {
        startGameWithType(.classicMode)
    }

    fileprivate func showGameCenterLeaderboards() {
        if let matchingGameViewController = self.view?.window?.rootViewController as? MatchingGameViewController {
            matchingGameViewController.showLeaderboard()
        }
    }

    fileprivate func startGameWithType(_ gameType: GameType) {
        let matchingGameScene = MatchingGameScene(size: size)
        matchingGameScene.scaleMode = scaleMode
        matchingGameScene.settings = gameType.matchingGameSettings

        view?.presentScene(matchingGameScene)
    }
}

// MARK: Input
extension MenuScene {
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        let touchLocation = touch.location(in: self)

        enumerateChildNodes(withName: "menu-option") { node, _ in
            if node.contains(touchLocation) {
                if let labelNode = node as? SKLabelNode {
                    if let selectedMenuOption = self.menuOptions.filter({$0.title == labelNode.text}).first {
                        let action = selectedMenuOption.action
                        if selectedMenuOption.instant {
                            action(self)()
                        } else {
                            labelNode.run(SKAction.sequence([
                                SKAction.group([
                                    SKAction.scale(to: 0.2, duration: 0.15),
                                    SKAction.fadeOut(withDuration: 0.15)
                                ]),
                                SKAction.run({
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
