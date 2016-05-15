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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setAudioSessionCategory(AVAudioSessionCategoryAmbient)
        
        ScoreManager.sharedInstance.focusDelegate = self
        ScoreManager.sharedInstance.authenticateLocalPlayer(self)
        
        if let skView = self.view as? SKView {
            skView.ignoresSiblingOrder = true
            //skView.showsFPS = true
            //skView.showsNodeCount = true
            
            let menuScene = MenuScene(size: view.bounds.size)
            menuScene.scaleMode = .ResizeFill
            
            skView.presentScene(menuScene)
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
