//
//  NavigationTasks.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 26/03/26.
//
// MARK: - COMPASS LOGIC: TRACKS TRUE NORTH HOLD & MOONWALK DIRECTION

import Foundation
import UIKit

final class CompassEngine: TaskEngine {
    private(set) var progressFraction: Double = 0
    private(set) var progressText: String = ""
    private(set) var isComplete: Bool = false
    
    private var currentTarget: CompassDirection = .north
    private var holdTimer: Double = 0
    
    func update(with sensor: SensorHub, deltaTime: Double) {
        let currentHeading = sensor.headingDegrees
        
        var diff = abs(currentHeading - currentTarget.targetDegrees)
        if diff > 180 { diff = 360 - diff }
        
        let tolerance: Double = 20.0
        
        if diff <= tolerance {
            holdTimer += deltaTime
        } else {
            holdTimer = 0
        }
        
        let progress = TaskKind.compass.calculateProgress(value1: holdTimer, context: currentTarget.rawValue)
        progressFraction = progress.fraction
        progressText = progress.text
        isComplete = progressFraction >= 1.0
    }
    
    func reset() {
        currentTarget = CompassDirection.allCases.randomElement() ?? .north
        holdTimer = 0
        isComplete = false
        let progress = TaskKind.compass.calculateProgress(value1: 0, context: currentTarget.rawValue)
        progressFraction = progress.fraction
        progressText = progress.text
    }
}

final class MoonwalkEngine: TaskEngine {
    private(set) var progressFraction: Double = 0
    private(set) var progressText: String = ""
    private(set) var isComplete: Bool = false
    
    private var handledStepCount: Int = 0
    private var backwardStepCount: Int = 0
    
    func update(with sensor: SensorHub, deltaTime: Double) {
        let steps = sensor.customStepCount
        
        if steps > handledStepCount {
            let added = steps - handledStepCount
            handledStepCount = steps
            
            let surge = sensor.stepSurge
            var isMovingBackward = false
            
            let orientation = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first(where: { $0.activationState == .foregroundActive })?
                .interfaceOrientation ?? .landscapeRight
            
            if orientation == .landscapeRight {
                isMovingBackward = surge > 0.04
            } else {
                isMovingBackward = surge < -0.04
            }
            
            if isMovingBackward { backwardStepCount += added }
        }
        
        let progress = TaskKind.moonwalk.calculateProgress(value1: Double(backwardStepCount))
        progressFraction = progress.fraction
        progressText = progress.text
        isComplete = progressFraction >= 1.0
    }
    
    func reset() {
        handledStepCount = 0
        backwardStepCount = 0
        isComplete = false
        let progress = TaskKind.moonwalk.calculateProgress(value1: 0)
        progressFraction = progress.fraction
        progressText = progress.text
    }
}
