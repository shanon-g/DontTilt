//
//  PedometerTasks.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 26/03/26.
//
// MARK: - STEP LOGIC: COUNTS STROLL STEPS & COMBINED WIPER SWIPES

import Foundation

final class StrollEngine: TaskEngine {
    private(set) var progressFraction: Double = 0
    private(set) var progressText: String = ""
    private(set) var isComplete: Bool = false
    
    func update(with sensor: SensorHub, deltaTime: Double) {
        let steps = sensor.customStepCount
        
        let progress = TaskKind.stroll.calculateProgress(value1: Double(steps))
        progressFraction = progress.fraction
        progressText = progress.text
        isComplete = progressFraction >= 1.0
    }
    
    func reset() {
        isComplete = false
        let progress = TaskKind.stroll.calculateProgress(value1: 0)
        progressFraction = progress.fraction
        progressText = progress.text
    }
}

final class WiperAndStrollEngine: TaskEngine {
    private(set) var progressFraction: Double = 0
    private(set) var progressText: String = ""
    private(set) var isComplete: Bool = false
    
    private var swipeCount: Int = 0
    
    func update(with sensor: SensorHub, deltaTime: Double) {
        let steps = sensor.customStepCount
        
        let progress = TaskKind.wiperAndStroll.calculateProgress(value1: Double(steps), value2: Double(swipeCount))
        progressFraction = progress.fraction
        progressText = progress.text
        isComplete = progressFraction >= 1.0
    }
    
    func registerSwipe() {
        if !isComplete { swipeCount += 1 }
    }
    
    func reset() {
        swipeCount = 0
        isComplete = false
        let progress = TaskKind.wiperAndStroll.calculateProgress(value1: 0, value2: 0)
        progressFraction = progress.fraction
        progressText = progress.text
    }
}

final class TakeOrderEngine: TaskEngine {
    private(set) var progressFraction: Double = 0
    private(set) var progressText: String = ""
    private(set) var isComplete: Bool = false
    
    private var tapCount: Int = 0
    
    func update(with sensor: SensorHub, deltaTime: Double) {
        let steps = sensor.customStepCount
        
        let progress = TaskKind.takeOrder.calculateProgress(value1: Double(steps), value2: Double(tapCount))
        progressFraction = progress.fraction
        progressText = progress.text
        isComplete = progressFraction >= 1.0
    }
    
    func registerTap() {
        if !isComplete {
            tapCount += 1
            AudioHub.shared.playSFX(.buttonClick)
        }
    }
    
    func reset() {
        tapCount = 0
        isComplete = false
        let progress = TaskKind.takeOrder.calculateProgress(value1: 0, value2: 0)
        progressFraction = progress.fraction
        progressText = progress.text
    }
}
