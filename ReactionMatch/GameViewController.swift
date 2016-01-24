//
//  GameViewController.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 18/01/2016.
//  Copyright (c) 2016 Eddie Lee. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ScoreManager.sharedInstance.authenticateLocalPlayer(self)
        
        let scene = GameScene(size: view.bounds.size)
        let skView = self.view as! SKView
        //skView.showsFPS = true
        //skView.showsNodeCount = true
        scene.scaleMode = .ResizeFill
        skView.presentScene(scene)
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
