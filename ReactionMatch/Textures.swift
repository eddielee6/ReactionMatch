//
//  Textures.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 14/05/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import SpriteKit

class Textures {
    static func getMenuScreenTexture(_ size: CGSize) -> SKTexture {
        return getTextureOfSize(size, withColors: [
            SKColor(red: 85/255, green: 190/255, blue: 239/255, alpha: 1),
            SKColor(red: 91/255, green: 112/255, blue: 255/255, alpha: 1)
        ], andStartPoint: CGPoint(x: 0.0, y: 0.2), andStopPoint: CGPoint(x: 0.0, y: 0.8))
    }
    
    static func getWhiteToGreyTextureOfSize(_ size: CGSize) -> SKTexture {
        return getTextureOfSize(size, withColors: [
            SKColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1),
            SKColor(red: 215/255, green: 215/255, blue: 215/255, alpha: 1)
        ], andStartPoint: CGPoint(x: 0.0, y: 0.0), andStopPoint: CGPoint(x: 0.0, y: 1.0))
    }
    
    static func getTextureOfSize(_ size: CGSize, withColors colors: [SKColor], andStartPoint startPoint: CGPoint, andStopPoint stopPoint: CGPoint) -> SKTexture {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: CGPoint.zero, size: size)
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = stopPoint
        
        UIGraphicsBeginImageContext(size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(cgImage: image!.cgImage!)
    }
}
