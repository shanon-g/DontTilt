//
//  TaskConfig.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 26/03/26.
//
// MARK: - DATA MODELS: DEFINES LEVELS, TASKS, & GAME PHASES

import SwiftUI

enum LevelPage: CaseIterable {
    case server
    case babysitter

    var title: String {
        switch self {
        case .server: return "The Server"
        case .babysitter: return "The Babysitter"
        }
    }

    var gameplayBackground: String {
        switch self {
        case .server: return "server_bg_gameplay"
        case .babysitter: return "babysitter_bg_gameplay"
        }
    }

    var failBackground: String {
        switch self {
        case .server: return "server_bg_fail"
        case .babysitter: return "babysitter_bg_fail"
        }
    }

    var previewImage: String {
        switch self {
        case .server: return "server_preview"
        case .babysitter: return "babysitter_preview"
        }
    }

    var tutorialImage: String {
        switch self {
        case .server: return "server_tutorial"
        case .babysitter: return "babysitter_tutorial"
        }
    }
    
    var actionTutorialImage: String {
        switch self {
        case .server: return "server_tutorial_irl"
        case .babysitter: return "babysitter_tutorial_irl"
        }
    }

//    var lossText: String {
//        switch self {
//        case .server: return "Broken Plate!"
//        case .babysitter: return "Baby Woke Up!"
//        }
//    }
}

struct TaskGoals {
    static let radarTurns: Double = 3
    static let squatCount: Int = 6
    static let jumpCount: Int = 10
    static let strollSteps: Int = 15
    static let moonwalkSteps: Int = 15
    static let wiperSteps: Int = 12
    static let wiperSwipes: Int = 15
    static let compassHold: Double = 6.0
    static let orderTaps: Int = 15
    static let orderSteps: Int = 12
}

enum CompassDirection: String, CaseIterable {
    case north = "North"
    case northeast = "Northeast"
    case east = "East"
    case southeast = "Southeast"
    case south = "South"
    case southwest = "Southwest"
    case west = "West"
    case northwest = "Northwest"
    
    var targetDegrees: Double {
        switch self {
        case .north: return 0
        case .northeast: return 45
        case .east: return 90
        case .southeast: return 135
        case .south: return 180
        case .southwest: return 225
        case .west: return 270
        case .northwest: return 315
        }
    }
}

enum TaskKind: CaseIterable {
    case radar
    case elevator
    case kangaroo
    case stroll
    case moonwalk
    case compass
    case wiperAndStroll
    case takeOrder

    var title: String {
        switch self {
            case .radar: return "The Radar"
            case .elevator: return "The Elevator"
            case .kangaroo: return "The Kangaroo"
            case .stroll: return "The Stroll"
            case .moonwalk: return "The Moonwalk"
            case .compass: return "The Compass"
            case .wiperAndStroll: return "The Wiper & Stroll"
            case .takeOrder: return "Take Order"
        }
    }
    
    var simplifiedInstructions: String {
        switch self {
        case .radar: return "SPIN!"
        case .elevator: return "SQUAT!"
        case .kangaroo: return "JUMP!"
        case .stroll: return "WALK!"
        case .moonwalk: return "MOONWALK!"
        case .compass: return "TURN!"
        case .wiperAndStroll: return "SWIPE & WALK!"
        case .takeOrder: return "TAP & WALK!"
        }
    }

    var instructions: String {
        switch self {
            case .radar:
                return "Spin \(TaskGoals.radarTurns) times"
            case .elevator:
                return "Do \(TaskGoals.squatCount) squats"
            case .kangaroo:
                return "Jump \(TaskGoals.jumpCount) times"
            case .stroll:
                return "Walk \(TaskGoals.strollSteps) steps"
            case .moonwalk:
                return "Walk backward \(TaskGoals.moonwalkSteps) steps"
            case .compass:
                return "Hold for \(TaskGoals.compassHold) seconds in the correct direction"
            case .wiperAndStroll:
                return "Walk \(TaskGoals.wiperSteps) steps + \(TaskGoals.wiperSwipes) swipes"
            case .takeOrder:
                return "Walk \(TaskGoals.orderSteps) steps + Tap \(TaskGoals.orderTaps) times"
        }
    }
    
    func calculateProgress(value1: Double, value2: Double = 0, context: String = "") -> (fraction: Double, text: String) {
        switch self {
        case .radar:
            let fraction = min(value1 / TaskGoals.radarTurns, 1.0)
            return (fraction, "\(Int(value1 * 360))° / \(Int(TaskGoals.radarTurns * 360))°")
            
        case .elevator:
            let fraction = min(value1 / Double(TaskGoals.squatCount), 1.0)
            return (fraction, "\(Int(value1)) / \(TaskGoals.squatCount)")
            
        case .kangaroo:
            let fraction = min(value1 / Double(TaskGoals.jumpCount), 1.0)
            return (fraction, "\(Int(value1)) / \(TaskGoals.jumpCount)")
            
        case .stroll:
            let fraction = min(value1 / Double(TaskGoals.strollSteps), 1.0)
            return (fraction, "\(Int(value1)) / \(TaskGoals.strollSteps)")
            
        case .moonwalk:
            let fraction = min(value1 / Double(TaskGoals.moonwalkSteps), 1.0)
            return (fraction, "\(Int(value1)) / \(TaskGoals.moonwalkSteps)")
            
        case .compass:
            let fraction = min(value1 / TaskGoals.compassHold, 1.0)
            let timerString = String(format: "%.1f", value1)
            return (fraction, "\(context) • \(timerString) / \(Int(TaskGoals.compassHold))s")
            
        case .wiperAndStroll:
            let stepFraction = min(value1 / Double(TaskGoals.wiperSteps), 1.0)
            let swipeFraction = min(value2 / Double(TaskGoals.wiperSwipes), 1.0)
            // average them together 50 50
            let fraction = (stepFraction + swipeFraction) / 2.0
            
            return (fraction, "Steps \(Int(value1))/\(TaskGoals.wiperSteps) • Swipes \(Int(value2))/\(TaskGoals.wiperSwipes)")
            
        case .takeOrder:
            let stepFraction = min(value1 / Double(TaskGoals.orderSteps), 1.0)
            let tapFraction = min(value2 / Double(TaskGoals.orderTaps), 1.0)
            // average them together 50 50
            let fraction = (stepFraction + tapFraction) / 2.0
            
            return (fraction, "Steps \(Int(value1))/\(TaskGoals.orderSteps), Taps \(Int(value2))/\(TaskGoals.orderTaps)")
        }
    }
    
    var iconAsset: String {
        switch self {
        case .radar: return "radar_icon"
        case .elevator: return "elevator_icon"
        case .kangaroo: return "kangaroo_icon"
        case .stroll: return "stroll_icon"
        case .moonwalk: return "moonwalk_icon"
        case .compass: return "compass_icon"
        case .wiperAndStroll: return "wiperAndStroll_icon"
        case .takeOrder: return "takeOrder_icon"
        }
    }
}

enum GamePhase {
    case menu
    case countdown
    case playing
    case result
}
