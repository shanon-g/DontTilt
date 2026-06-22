//
//  LevelEngine.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 27/03/26.
//

// MARK: - LEVEL LOGIC: MANAGES SPECIFIC RULES FOR EACH GAME MODE

import Foundation

protocol LevelEngine {
    var targetRollOffset: Double { get }
    var isWarningActive: Bool { get }
    
    func update(deltaTime: Double, config: DifficultyConfig)
    func checkFailure(currentTilt: Double, tolerance: Double, sensor: SensorHub, config: DifficultyConfig) -> Bool
    func reset(config: DifficultyConfig)
}

final class ServerLevelEngine: LevelEngine {
    var targetRollOffset: Double = 0
    var isWarningActive: Bool = false // gapake ini di Server level
    
    private var driftTime: Double = 0
    
    func update(deltaTime: Double, config: DifficultyConfig) {
        driftTime += deltaTime * config.serverDriftSpeed
        targetRollOffset = sin(driftTime) * config.serverDriftAmplitude
    }
    
    func checkFailure(currentTilt: Double, tolerance: Double, sensor: SensorHub, config: DifficultyConfig) -> Bool {
        return currentTilt > tolerance
    }
    
    func reset(config: DifficultyConfig) {
        driftTime = 0
        targetRollOffset = 0
    }
}

final class BabysitterLevelEngine: LevelEngine {
    var targetRollOffset: Double = 0 // Gapake in Babysitter level
    var isWarningActive: Bool = false
    
    private var timeUntilNextWarning: Double = 0
    private var warningTimeRemaining: Double = 0

    private let warningGracePeriod: Double = 0.8    // buffer
    
    func update(deltaTime: Double, config: DifficultyConfig) {
        if isWarningActive {
            warningTimeRemaining -= deltaTime
            if warningTimeRemaining <= 0 {
                isWarningActive = false
                scheduleNextWarning(config: config)
            }
        } else {
            timeUntilNextWarning -= deltaTime
            if timeUntilNextWarning <= 0 {
                isWarningActive = true
                warningTimeRemaining = config.babyFreezeDuration
            }
        }
    }
    
    func checkFailure(currentTilt: Double, tolerance: Double, sensor: SensorHub, config: DifficultyConfig) -> Bool {
        // 1. Basic tilt check
        if currentTilt > tolerance { return true }
        
        // 2. Freeze check (When baby is waking up)
        if isWarningActive {
            // Calculate how long the warning has been on screen
            let timeSinceWarningStarted = config.babyFreezeDuration - warningTimeRemaining
            
            if timeSinceWarningStarted > warningGracePeriod {
                let freezeTiltLimit = tolerance * config.babyFreezeTiltMultiplier
                let freezeMovement = sensor.movementMagnitude + (sensor.rotationMagnitude * 0.08)

                if currentTilt > freezeTiltLimit { return true }
                if freezeMovement > config.babyFreezeMovementTolerance { return true }
            }
        }
        
        return false
    }
    
    func reset(config: DifficultyConfig) {
        isWarningActive = false
        scheduleNextWarning(config: config)
    }
    
    private func scheduleNextWarning(config: DifficultyConfig) {
        timeUntilNextWarning = Double.random(in: config.babyWarningGap)
    }
}
