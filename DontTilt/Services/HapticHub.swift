//
//  HapticHub.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 27/03/26.
//
// MARK: - HAPTIC MANAGER: HANDLES UI BUMPS AND CONTINUOUS TILT RUMBLE

import UIKit

final class HapticHub {
    static let shared = HapticHub()
    
    // Strong generators
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    private var lastHapticTime = Date()
    
    private init() {
        rigidGenerator.prepare()
        heavyGenerator.prepare()
    }
    
    func startDangerRumble() {}
    func stopDangerRumble() {}
    
    func updateDangerRumble(dangerRatio: Double) {
        // Trigger slightly earlier to build more tension
        guard dangerRatio > 0.40 else { return }
        
        let now = Date()
        
        // SPEED CURVE:
        // 0.40 danger = pulses every ~0.25 seconds
        // 1.00 danger = pulses every ~0.04 seconds (continuous buzz)
        let throttleInterval = max(0.04, 0.25 - ((dangerRatio - 0.40) * 0.40))
        
        guard now.timeIntervalSince(lastHapticTime) > throttleInterval else { return }
        lastHapticTime = now
        
        // INTENSITY CURVE:
        if dangerRatio > 0.70 {
            // High danger: Maximum heavy thuds
            heavyGenerator.impactOccurred(intensity: 1.0)
            heavyGenerator.prepare()
            
        } else if dangerRatio > 0.55 {
            // Medium danger: Slightly softer heavy thuds
            heavyGenerator.impactOccurred(intensity: 0.7)
            heavyGenerator.prepare()
            
        } else {
            // Early warning: Sharp, stiff clicks
            rigidGenerator.impactOccurred(intensity: 1.0)
            rigidGenerator.prepare()
        }
    }
}
