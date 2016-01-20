//
//  GameViewController.swift
//  MatchingGame
//
//  Created by Eddie Lee on 18/01/2016.
//  Copyright (c) 2016 Eddie Lee. All rights reserved.
//

import UIKit
import SpriteKit
import GameKit

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.authenticateLocalPlayer()
        
        let scene = GameStartScene(size: view.bounds.size)
        let skView = self.view as! SKView
        //skView.showsFPS = true
        //skView.showsNodeCount = true
        scene.scaleMode = .ResizeFill
        skView.presentScene(scene)
    }
    
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = {(GameCentreLoginViewController, error) -> Void in
            if GameCentreLoginViewController != nil {
                self.presentViewController(GameCentreLoginViewController!, animated: true, completion: nil)
            } else {
                self.storeGameCentreState(localPlayer.authenticated)
            }
        }
    }
    
    func storeGameCentreState(enabled: Bool) {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(enabled, forKey: "gameCentreEnabled")
        defaults.synchronize()
    }


    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
