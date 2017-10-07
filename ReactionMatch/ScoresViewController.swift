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
        addBackgroundBlur()
    }
    
    func addBackgroundBlur() {
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            view.backgroundColor = UIColor.clear
            
            let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
            blurEffectView.frame = self.view.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            view.insertSubview(blurEffectView, at: 0)
        }
    }
    
    @IBAction func didTouchDone(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}
