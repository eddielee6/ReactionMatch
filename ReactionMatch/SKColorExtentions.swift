//
//  SKColorExtentions.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 11/04/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import Foundation
import SpriteKit

extension SKColor {
    var inverted: SKColor {
        get {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            
            self.getRed(&r, green: &g, blue: &b, alpha: &a)
            return SKColor(red: 1-r, green: 1-g, blue: 1-b, alpha: a)
        }
    }
}