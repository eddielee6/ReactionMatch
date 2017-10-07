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
import GameKit

class MatchingGameViewController: UIViewController, ScoreManagerFocusDelegate, GKGameCenterControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        setAudioSessionCategory(AVAudioSessionCategoryAmbient)

        ScoreManager.sharedInstance.focusDelegate = self
        ScoreManager.sharedInstance.authenticateLocalPlayer(self)

        let skView = self.view as! SKView
        skView.ignoresSiblingOrder = true
        //skView.showsFPS = true
        //skView.showsNodeCount = true

        let menuScene = MenuScene(size: view.bounds.size)
        menuScene.scaleMode = .resizeFill

        skView.presentScene(menuScene)
    }

    fileprivate func setAudioSessionCategory(_ audioSessionCategory: String) {
        try? AVAudioSession.sharedInstance().setCategory(audioSessionCategory)
    }

    // MARK: ScoreManagerFocusDelegate
    func scoreManagerWillTakeFocus() {
        let skView = self.view as! SKView
        skView.isPaused = true
    }

    func scoreManagerDidResignFocus() {
        let skView = self.view as! SKView
        skView.isPaused = false
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    func gameCenterViewControllerDidFinish(_ gcViewController: GKGameCenterViewController) {
        self.dismiss(animated: true, completion: nil)
    }

    func showLeaderboard() {
        if ScoreManager.sharedInstance.isAuthenticated {
            let gcViewController: GKGameCenterViewController = GKGameCenterViewController()
            gcViewController.gameCenterDelegate = self
            gcViewController.viewState = GKGameCenterViewControllerState.leaderboards
            gcViewController.leaderboardIdentifier = GameType.v2Mode.leaderboardIdentifier
            self.present(gcViewController, animated: true, completion: nil)
        } else {
            let storyboard = UIStoryboard(name: "Scores", bundle: nil)
            let scoresViewController = storyboard.instantiateInitialViewController()!
            self.present(scoresViewController, animated: true, completion: nil)
        }
    }
}
