//
//  CGSizeExtentions.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 14/05/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import Foundation
import CoreGraphics

func + (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width + right, height: left.height + right)
}

func - (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width - right, height: left.height - right)
}

func * (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width * right, height: left.height * right)
}

func / (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width / right, height: left.height / right)
}
