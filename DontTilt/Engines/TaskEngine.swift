//
//  TaskEngine.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 25/03/26.
//
// MARK: - PROTOCOL BLUEPRINT: THE REQUIRED STRUCTURE FOR EVERY PHYSICAL TASK

import Foundation

protocol TaskEngine {
    var progressFraction: Double { get }
    var progressText: String { get }
    var isComplete: Bool { get }
    
    // Called every frame to process new sensor data
    func update(with sensor: SensorHub, deltaTime: Double)
    
    // Resets the engine's internal state for a new round
    func reset()
}
