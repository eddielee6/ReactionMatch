//
//  MuteSwitchNode.swift
//  ReactionMatch
//
//  Created by Eddie Lee on 15/04/2016.
//  Copyright © 2016 Eddie Lee. All rights reserved.
//

import Foundation
import SpriteKit

class MuteSwitchNode: SKSpriteNode {
    
    private let soundOnTexture = SKTexture(imageNamed: "sound-on")
    private let soundOffTexture = SKTexture(imageNamed: "sound-off")
    
    enum AudioState: Int {
        case Off
        case On
    }
    
    var audioState: AudioState {
        get {
            if let persistedAudioState = getPersistedAudioState() {
                return persistedAudioState
            }
        
            return .On
        }
        set {
            persistAudioState(newValue)
            setTexture()
        }
    }
    
    private func toggleAudioState() {
        switch audioState {
        case .On:
            audioState = .Off
        case .Off:
            audioState = .On
        }
    }
    
    private func persistAudioState(audioState: AudioState) {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(audioState.rawValue, forKey: "audioState")
        defaults.synchronize()
    }
    
    private func getPersistedAudioState() -> AudioState? {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let persistedAudioStateValue = defaults.objectForKey("audioState") as? Int {
            return AudioState(rawValue: persistedAudioStateValue)
        }
        
        return nil
    }
    
    private func setTexture() {
        switch audioState {
        case .On:
            setTexture(soundOnTexture)
        case .Off:
            setTexture(soundOffTexture)
        }
    }
    
    private func setTexture(texture: SKTexture) {
        self.texture = texture
        self.size = texture.size()
    }
    
    init() {
        super.init(texture: nil, color: UIColor.clearColor(), size: CGSizeZero)
        self.userInteractionEnabled = true
        self.anchorPoint = CGPointZero
        setTexture()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let parentNode = parent, touch = touches.first {
            let touchLocation = touch.locationInNode(parentNode)
            
            if self.containsPoint(touchLocation) {
                toggleAudioState()
            }
        }
    }
}