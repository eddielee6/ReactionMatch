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
    private let soundOnSelectedTexture = SKTexture(imageNamed: "sound-on-selected")
    private let soundOffTexture = SKTexture(imageNamed: "sound-off")
    private let soundOffSelectedTexture = SKTexture(imageNamed: "sound-off-selected")
    
    private var selected: Bool = false {
        didSet {
            setTexture()
        }
    }
    
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
            if selected {
                setTexture(soundOnSelectedTexture)
            } else {
                setTexture(soundOnTexture)
            }
            
        case .Off:
            if selected {
                setTexture(soundOffSelectedTexture)
            } else {
                setTexture(soundOffTexture)
            }
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
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        selected = true
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let parentNode = parent, touch = touches.first {
            let touchLocation = touch.locationInNode(parentNode)
            selected = self.containsPoint(touchLocation)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        selected = false
        
        if let parentNode = parent, touch = touches.first {
            let touchLocation = touch.locationInNode(parentNode)
            
            if self.containsPoint(touchLocation) {
                toggleAudioState()
            }
        }
    }
}