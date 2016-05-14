//
//  GameViewController.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 18/01/2016.
//  Copyright (c) 2016 Eddie Lee. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class MatchingGameViewController: UIViewController, ScoreManagerFocusDelegate {
    
    enum GameType {
        case Classic, Pro
    }
    
    let gameType: GameType = .Classic
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setAudioSessionCategory(AVAudioSessionCategoryAmbient)
        
        ScoreManager.sharedInstance.focusDelegate = self
        ScoreManager.sharedInstance.authenticateLocalPlayer(self)
        
        if let skView = self.view as? SKView {
            skView.ignoresSiblingOrder = true
            //skView.showsFPS = true
            //skView.showsNodeCount = true
            
            let matchingGameScene = MatchingGameScene(size: view.bounds.size)
            matchingGameScene.scaleMode = .ResizeFill
            
            switch gameType {
            case .Classic:
                matchingGameScene.settings.gameMode = .ColorMatch
                matchingGameScene.settings.minNumberOfTargets = 4
                matchingGameScene.settings.maxNumberOfTargets = 4
                matchingGameScene.settings.newTargetAfterTurn = 0
                matchingGameScene.settings.newTargetIncrement = 0
            case .Pro:
                matchingGameScene.settings.gameMode = .ShapeMatch
                matchingGameScene.settings.minNumberOfTargets = 2
                matchingGameScene.settings.maxNumberOfTargets = 8
                matchingGameScene.settings.newTargetAfterTurn = 5
                matchingGameScene.settings.newTargetIncrement = 2
            }
            
            skView.presentScene(matchingGameScene)
        }
    }
    
    func setAudioSessionCategory(audioSessionCategory: String) {
        do {
            try AVAudioSession.sharedInstance().setCategory(audioSessionCategory)
        } catch {
            print(error)
        }
    }
    
    
    // MARK: ScoreManagerFocusDelegate
    
    func scoreManagerWillTakeFocus() {
        if let skView = self.view as? SKView {
            skView.paused = true
        }
    }
    
    func scoreManagerDidResignFocus() {
        if let skView = self.view as? SKView {
            skView.paused = false
        }
    }
    
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
