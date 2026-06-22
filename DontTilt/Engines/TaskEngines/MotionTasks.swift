//
//  MotionTasks.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 25/03/26.
//
// MARK: - PHYSICS LOGIC: CALC RADAR SPINS, ELEVATOR SQUATS, & KANGAROO JUMPS

import Foundation
import CoreMotion

final class RadarEngine: TaskEngine {
    private(set) var progressFraction: Double = 0
    private(set) var progressText: String = ""
    private(set) var isComplete: Bool = false
    
    private var lastYaw: Double = 0
    private var accumulatedYaw: Double = 0
    private var isFirstUpdate = true
    
    func update(with sensor: SensorHub, deltaTime: Double) {
        if isFirstUpdate {
            lastYaw = sensor.yawRadians
            isFirstUpdate = false
            return
        }
        
        let currentYaw = sensor.yawRadians
        var delta = currentYaw - lastYaw
        
        if delta > .pi { delta -= 2 * .pi }
        if delta < -.pi { delta += 2 * .pi }
        
        accumulatedYaw += abs(delta)
        lastYaw = currentYaw
        
        let turns = accumulatedYaw / (2 * .pi)
        
        // Let TaskConfig handle the UI logic
        let progress = TaskKind.radar.calculateProgress(value1: turns)
        progressFraction = progress.fraction
        progressText = progress.text
        isComplete = progressFraction >= 1.0
    }
    
    func reset() {
        accumulatedYaw = 0
        isFirstUpdate = true
        isComplete = false
        let progress = TaskKind.radar.calculateProgress(value1: 0)
        progressFraction = progress.fraction
        progressText = progress.text
    }
}

final class ElevatorEngine: TaskEngine {
    private(set) var progressFraction: Double = 0
    private(set) var progressText: String = ""
    private(set) var isComplete: Bool = false
    
    private var squatCount: Int = 0
    private var motionCycleState: Int = 0
    
    func update(with sensor: SensorHub, deltaTime: Double) {
        let z = sensor.userAccelerationZ
        
        switch motionCycleState {
        case 0:
            if z < GameConfig.Physics.squatDropThreshold { motionCycleState = 1 }
        case 1:
            if z > GameConfig.Physics.squatRiseThreshold {
                squatCount += 1
                motionCycleState = 2
            }
        default:
            if abs(z) < GameConfig.Physics.squatStabilized { motionCycleState = 0 }
        }
        
        let progress = TaskKind.elevator.calculateProgress(value1: Double(squatCount))
        progressFraction = progress.fraction
        progressText = progress.text
        isComplete = progressFraction >= 1.0
    }
    
    func reset() {
        squatCount = 0
        motionCycleState = 0
        isComplete = false
        let progress = TaskKind.elevator.calculateProgress(value1: 0)
        progressFraction = progress.fraction
        progressText = progress.text
    }
}

final class KangarooEngine: TaskEngine {
    private(set) var progressFraction: Double = 0
    private(set) var progressText: String = ""
    private(set) var isComplete: Bool = false
    
    private var jumpCount: Int = 0
    private var motionCycleState: Int = 0
    
    func update(with sensor: SensorHub, deltaTime: Double) {
        let z = sensor.userAccelerationZ
        
        switch motionCycleState {
        case 0:
            if z > GameConfig.Physics.jumpExplodeThreshold { motionCycleState = 1 }
        case 1:
            if z < GameConfig.Physics.jumpLandThreshold {
                jumpCount += 1
                motionCycleState = 2
            }
        default:
            if abs(z) < GameConfig.Physics.jumpStabilized { motionCycleState = 0 }
        }
        
        let progress = TaskKind.kangaroo.calculateProgress(value1: Double(jumpCount))
        progressFraction = progress.fraction
        progressText = progress.text
        isComplete = progressFraction >= 1.0
    }
    
    func reset() {
        jumpCount = 0
        motionCycleState = 0
        isComplete = false
        let progress = TaskKind.kangaroo.calculateProgress(value1: 0)
        progressFraction = progress.fraction
        progressText = progress.text
    }
}
