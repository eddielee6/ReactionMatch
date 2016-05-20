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
            view.backgroundColor = UIColor.clearColor()
            
            let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
            blurEffectView.frame = self.view.bounds
            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            
            view.insertSubview(blurEffectView, atIndex: 0)
        }
    }
    
    @IBAction func didTouchDone(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
