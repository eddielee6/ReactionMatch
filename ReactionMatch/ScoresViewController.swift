//
//  ScoresViewController.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 20/05/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import UIKit

class ScoresViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if !UIAccessibilityIsReduceTransparencyEnabled() {
            addBackgroundBlur(toView: self.view)
        }
    }

    fileprivate func addBackgroundBlur(toView viewToBlur: UIView) {
        viewToBlur.backgroundColor = UIColor.clear

        let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        blurEffectView.frame = viewToBlur.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        viewToBlur.insertSubview(blurEffectView, at: 0)
    }

    @IBAction func didTouchDone(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}
