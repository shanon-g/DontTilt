//
//  GameConfig.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 26/03/26.
//
// MARK: - MASTER TUNING: DIFFICULTY TIMERS, TOLERANCES, & SENSOR THRESHOLDS

import SwiftUI

enum GameConfig {
    // MARK: - Motion & Sensor Sensitivity
    enum Physics {
        // Elevator (squat)
        static let squatDropThreshold: Double = -0.35
        static let squatRiseThreshold: Double = 0.35
        static let squatStabilized: Double = 0.05
        
        // Kangaroo (jump)
        static let jumpExplodeThreshold: Double = 0.55
        static let jumpLandThreshold: Double = -0.40
        static let jumpStabilized: Double = 0.06
        
        // Stroll (walk)
        static let stepImpactThreshold: Double = 0.10
        static let stepSettleThreshold: Double = 0.05
        static let stepCooldown: Double = 0.25
        static let maxShakeRotation: Double = 2.0   // stop shake kecepetan count as step
    }
}

// MARK: - Difficulty Tuning
struct DifficultyConfig {
    let roundSeconds: Double
    let tiltToleranceDegrees: Double
    let serverDriftAmplitude: Double
    let serverDriftSpeed: Double
    let babyWarningGap: ClosedRange<Double>
    let babyFreezeDuration: Double
    let babyFreezeMovementTolerance: Double
    let babyFreezeTiltMultiplier: Double
    
    // UI & Gameplay Tuning Parameters
    let meterDisplayRangeDegrees: Double // control visual sens of phone
    let greenBarSpeed: Double
    let greenBarAmplitude: Double
}

enum Difficulty: CaseIterable {
    case easy
    case medium
    case hard

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var badgeColor: Color {
        switch self {
        case .easy: return Palette.sage
        case .medium: return Palette.peach
        case .hard: return Palette.danger
        }
    }

    var config: DifficultyConfig {
        switch self {
        case .easy:
            return DifficultyConfig(
                roundSeconds: 90,
                tiltToleranceDegrees: 15,
                serverDriftAmplitude: 3.5,
                serverDriftSpeed: 0.90,
                babyWarningGap: 9.0...12.0,
                babyFreezeDuration: 2,
                babyFreezeMovementTolerance: 0.1,
                babyFreezeTiltMultiplier: 0.65,
                
                // UI Tuning
                meterDisplayRangeDegrees: 30.0, // control visual sens
                greenBarSpeed: 1.0,
                greenBarAmplitude: 2.5  // how far green bar swings left & right
            )

        case .medium:
            return DifficultyConfig(
                roundSeconds: 25,
                tiltToleranceDegrees: 10,
                serverDriftAmplitude: 5.0,
                serverDriftSpeed: 1.35,
                babyWarningGap: 7.0...9.5,
                babyFreezeDuration: 2.5,
                babyFreezeMovementTolerance: 0.07,
                babyFreezeTiltMultiplier: 0.55,
                
                // UI Tuning
                meterDisplayRangeDegrees: 22.0,
                greenBarSpeed: 1.25,
                greenBarAmplitude: 3.0
            )

        case .hard:
            return DifficultyConfig(
                roundSeconds: 20,
                tiltToleranceDegrees: 7.0,
                serverDriftAmplitude: 6.5,
                serverDriftSpeed: 1.85,
                babyWarningGap: 5.0...7.0,
                babyFreezeDuration: 3,
                babyFreezeMovementTolerance: 0.04,
                babyFreezeTiltMultiplier: 0.45,
                
                // UI Tuning
                meterDisplayRangeDegrees: 16.0,
                greenBarSpeed: 1.5,
                greenBarAmplitude: 3.5
            )
        }
    }
}
