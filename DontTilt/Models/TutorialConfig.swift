//
//  TutorialConfig.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 01/04/26.
//

import Foundation
import SwiftUI
import Combine

enum TutorialComponent {
    case tiltMeter, taskBubble, timer, none
}

class TutorialConfig: ObservableObject {
    @Published var isActive: Bool = false
    @Published var step: Int = 1
    @Published var showTasksModal: Bool = false
    @Published var tutTaskComplete: Bool = false
    
    var highlightedComponent: TutorialComponent {
        switch step {
        case 1, 2: return .tiltMeter
        case 3: return .taskBubble
        case 4: return .timer
        default: return .none
        }
    }
    
    func message(for level: LevelPage) -> String {
        switch step {
        case 1:
            return "The Tilt Meter tracks your balance.\nIt tracks the phone both horizontally & vertically!\nKeep it flat to stay in the Green Zone."
        case 2:
            return "⚠️ Tilting into the red ends the game!\nYou are safe in this tutorial, but in a real game, you will lose."
        case 3:
            return "This is your Task.\nPhysically move while keeping the phone flat.\n\nFinish all the squats to unlock the Next button!"
        case 4:
            return "This is the Timer.\nFinish your task before it hits zero to WIN!"
        case 5:
            return level == .server
                ? "Server Gimmick:\nThe green target zone slowly drifts. Stay alert!"
                : "Babysitter Gimmick:\nIf the baby cries 'FREEZE!', stop all movement instantly!"
        case 6:
            return "Let's test the limits!\nTilt your phone into the red zone to feel the warning rumble and end the tutorial."
        default: return ""
        }
    }

    func start() {
        self.isActive = true
        self.step = 1
        self.showTasksModal = false
        self.tutTaskComplete = false
    }

    func stop() {
        self.isActive = false
    }

    func nextStep() {
        if step < 6 { step += 1 }
    }

    func previousStep() {
        if step > 1 { step -= 1 }
    }

    func checkProgress(dangerRatio: Double) -> Bool {
        guard isActive else { return false }
        if step == 6 && dangerRatio > 0.8 {
            return true
        }
        return false
    }
}
