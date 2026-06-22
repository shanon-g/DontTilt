//
//  GameViewModel.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 16/03/26.
//
// MARK: - BRAIN: MANAGES GAME STATE, TIMERS, HUD UPDATES & AUDIO

import Foundation
import SwiftUI
import Combine

final class GameViewModel: ObservableObject {
    @Published var selectedLevel: LevelPage = .server
    @Published var selectedDifficulty: Difficulty = .easy
    @Published var phase: GamePhase = .menu

    @Published var task: TaskKind = .stroll
    @Published var introCountdown: Double = 3
    @Published var timeRemaining: Double = 0
    @Published var taskProgressFraction: Double = 0
    @Published var taskProgressText: String = ""
    @Published var didWin: Bool = false

    @Published var serverTargetRoll: Double = 0
    @Published var babyWarningActive: Bool = false

    @Published var sensor = SensorHub()
    
    @Published var tutorial = TutorialConfig()

    private var loopTimer: Timer?
    private var lastTick: Date = Date()
    private var taskComplete = false
    private var neutralHorizontalTiltDegrees: Double = 0
    private var neutralVerticalTiltDegrees: Double = 0
    private var lastTask: TaskKind?
    private let includeExperimentalMoonwalk = true
    
    // MARK: - Active Engines & Audio Locks
    private var activeTaskEngine: TaskEngine?
    private var activeLevelEngine: LevelEngine?
    
    // Prevent SFX from firing 30 times a second during the update loop
    private var didPlay10sCountdown = false
    private var wasInDanger = false

    // Display & Gameplay tuning
    private let gameplayTiltToleranceMultiplier: Double = 1.18
    private let foodHorizontalSlideMultiplier: Double = 5.2
    private let foodVerticalSlideMultiplier: Double = 3.2

    init() {
        AudioHub.shared.playMusic(.menu)
    }

    func cycleLevel(next: Bool) {
        AudioHub.shared.playSFX(.buttonClick)
        
        let all = LevelPage.allCases
        guard let currentIndex = all.firstIndex(of: selectedLevel) else { return }
        let newIndex = next ? (currentIndex + 1) % all.count : (currentIndex - 1 + all.count) % all.count
        selectedLevel = all[newIndex]
        
        // Announcer for the chosen level
        if selectedLevel == .server {
            AudioHub.shared.playSFX(.restaurantLevelChosen)
        } else {
            AudioHub.shared.playSFX(.babyLevelChosen)
        }
    }

    func cycleDifficulty(next: Bool) {
        AudioHub.shared.playSFX(.buttonClick)
        
        let all = Difficulty.allCases
        guard let currentIndex = all.firstIndex(of: selectedDifficulty) else { return }
        let newIndex = next ? (currentIndex + 1) % all.count : (currentIndex - 1 + all.count) % all.count
        selectedDifficulty = all[newIndex]
    }

    func startGame(isTutorial: Bool = false) {
        AudioHub.shared.playSFX(.buttonClick)
        AudioHub.shared.playSFX(.enterLevel)
        AudioHub.shared.stopMusic()
        AudioHub.shared.playSFX(.countdown321)
        
        sensor.requestPermissions()
        sensor.startAll()

        phase = .countdown
        introCountdown = 3
        didWin = false
        serverTargetRoll = 0
        babyWarningActive = false
        neutralHorizontalTiltDegrees = 0
        neutralVerticalTiltDegrees = 0

        if isTutorial {
            tutorial.start()
            task = .elevator
            timeRemaining = 999
            
            // force to playing immediately to kill the countdown
            phase = .playing
            introCountdown = 0
            
            // setup the LevelEngine early since aku skip beginPlaying()
            activeLevelEngine = selectedLevel == .server ? ServerLevelEngine() : BabysitterLevelEngine()
            activeLevelEngine?.reset(config: selectedDifficulty.config)
            
        } else {
            tutorial.stop()
            task = pickRandomSupportedTask()
            timeRemaining = selectedDifficulty.config.roundSeconds
        }

        switch task {
        case .radar: activeTaskEngine = RadarEngine()
        case .elevator: activeTaskEngine = ElevatorEngine()
        case .kangaroo: activeTaskEngine = KangarooEngine()
        case .stroll: activeTaskEngine = StrollEngine()
        case .moonwalk: activeTaskEngine = MoonwalkEngine()
        case .compass: activeTaskEngine = CompassEngine()
        case .wiperAndStroll: activeTaskEngine = WiperAndStrollEngine()
        case .takeOrder: activeTaskEngine = TakeOrderEngine()
        }
        
        activeTaskEngine?.reset()
        
        taskProgressFraction = activeTaskEngine?.progressFraction ?? 0
        taskProgressText = activeTaskEngine?.progressText ?? ""

        startLoop()
        }

    func backToMenu() {
        stopLoop()
        sensor.stopAll()
        
        AudioHub.shared.stopAllSFX()

        phase = .menu
        serverTargetRoll = 0
        babyWarningActive = false
        taskProgressFraction = 0
        taskProgressText = ""
        didWin = false
        activeTaskEngine = nil
        activeLevelEngine = nil
        
        AudioHub.shared.playMusic(.menu)
    }

    func registerSwipe(distance: CGFloat) {
        guard phase == .playing, task == .wiperAndStroll else { return }
        if selectedLevel == .babysitter && babyWarningActive {
            endRound(win: false)
            return
        }
        if distance > 80 {
            if let wiperEngine = activeTaskEngine as? WiperAndStrollEngine {
                wiperEngine.registerSwipe()
                updateEngines(deltaTime: 0)
            }
        }
    }
    
    func registerTap() {
        guard phase == .playing, task == .takeOrder else { return }
        
        if let orderEngine = activeTaskEngine as? TakeOrderEngine {
            orderEngine.registerTap()
            updateEngines(deltaTime: 0)
        }
    }

    private func startLoop() {
        stopLoop()
        lastTick = Date()
        loopTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        if let loopTimer { RunLoop.main.add(loopTimer, forMode: .common) }
    }

    private func stopLoop() {
        loopTimer?.invalidate()
        loopTimer = nil
    }

    private func tick() {
        let now = Date()
        let deltaTime = min(now.timeIntervalSince(lastTick), 0.1)
        lastTick = now

        switch phase {
        case .menu, .result: break
        case .countdown:
            introCountdown -= deltaTime
            if introCountdown <= 0 { beginPlaying() }
        case .playing:
            updateEngines(deltaTime: deltaTime)

            if tutorial.isActive {
                // squat unlock
                if tutorial.step == 3 && taskProgressFraction >= 1.0 {
                    tutorial.tutTaskComplete = true
                }
                
                let isFinished = tutorial.checkProgress(dangerRatio: dangerRatio)
                
                // trigger fail
                if isFinished { endRound(win: false) }
                return
            }
            
            if hasFailedFromTiltOrFreeze() {
                endRound(win: false)
                return
            }

            if taskComplete {
                endRound(win: true)
                return
            }

            timeRemaining -= deltaTime
            
            // Trigger 10 second countdown audio exactly once
            if timeRemaining <= 10.0 && !didPlay10sCountdown {
                didPlay10sCountdown = true
                AudioHub.shared.playSFX(.countdown10s)
            }
            
            if timeRemaining <= 0 { endRound(win: false) }
        }
    }

    private func beginPlaying() {
        phase = .playing
        timeRemaining = selectedDifficulty.config.roundSeconds
        neutralHorizontalTiltDegrees = sensor.horizontalTiltDegrees
        neutralVerticalTiltDegrees = sensor.verticalTiltDegrees
        sensor.restartPedometerSession()
        
        // Reset state locks
        taskComplete = false
        didPlay10sCountdown = false
        wasInDanger = false
        
        // Start Level Ambience
        AudioHub.shared.playMusic(selectedLevel == .server ? .restaurant : .baby)
        
        // Setup Level Engine
        activeLevelEngine = selectedLevel == .server ? ServerLevelEngine() : BabysitterLevelEngine()
        activeLevelEngine?.reset(config: selectedDifficulty.config)
        
        HapticHub.shared.startDangerRumble()
    }

    private func endRound(win: Bool) {
        stopLoop()
        phase = .result
        didWin = win
        babyWarningActive = false
        sensor.stopAll()
        
        // Trigger Win/Loss Audio
        AudioHub.shared.stopMusic()
        AudioHub.shared.stopAllSFX()
        HapticHub.shared.stopDangerRumble()
        
        if win {
            AudioHub.shared.playSFX(selectedLevel == .server ? .restaurantSuccess : .babySuccess)
        } else {
            AudioHub.shared.playSFX(selectedLevel == .server ? .restaurantFailed : .babyCrying)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self else { return }
            if self.phase == .result { self.backToMenu() }
        }
    }

    private func updateEngines(deltaTime: Double) {
        // Update Level Mechanics
        activeLevelEngine?.update(deltaTime: deltaTime, config: selectedDifficulty.config)
        serverTargetRoll = activeLevelEngine?.targetRollOffset ?? 0
        
        HapticHub.shared.updateDangerRumble(dangerRatio: dangerRatio)   //haptics
        
        // Edge Trigger: play baby wake sound once when warning flips to true
        let newWarningState = activeLevelEngine?.isWarningActive ?? false
        if newWarningState && !babyWarningActive && selectedLevel == .babysitter {
            AudioHub.shared.playSFX(.babyWakingUp)
        }
        babyWarningActive = newWarningState
        
        // Edge Trigger: Play dish sliding sound once when entering high danger
        if selectedLevel == .server {
            let currentlyInDanger = dangerRatio > 0.65
            if currentlyInDanger && !wasInDanger {
                AudioHub.shared.playSFX(.dishesSliding)
            }
            wasInDanger = currentlyInDanger
        }
        
        if selectedLevel == .babysitter && babyWarningActive {
//            taskProgressText = "Freeze! Hold the phone flat"
            return
        }
        
        // Update Task Mechanics
        guard let taskEngine = activeTaskEngine else { return }
        taskEngine.update(with: sensor, deltaTime: deltaTime)
        taskProgressFraction = taskEngine.progressFraction
        taskProgressText = taskEngine.progressText
        
        if taskEngine.isComplete { taskComplete = true }
    }

    private func hasFailedFromTiltOrFreeze() -> Bool {
        return activeLevelEngine?.checkFailure(
            currentTilt: currentTiltDegrees,
            tolerance: effectiveTiltToleranceDegrees,
            sensor: sensor,
            config: selectedDifficulty.config
        ) ?? false
    }

    private func pickRandomSupportedTask() -> TaskKind {
        let supported = supportedTasks()
        let filtered = supported.filter { $0 != lastTask }
        let chosen = (filtered.isEmpty ? supported : filtered).randomElement() ?? .stroll
        lastTask = chosen
        return chosen
    }

    private func supportedTasks() -> [TaskKind] {
        var tasks: [TaskKind] = []
        if sensor.motionAvailable { tasks += [.radar, .elevator, .kangaroo, .stroll] }
        if sensor.headingAvailable && sensor.locationAuthorized { tasks += [.compass] }
        if includeExperimentalMoonwalk && sensor.motionAvailable && sensor.headingAvailable && sensor.locationAuthorized { tasks += [.moonwalk] }
        
        // Level exclusive tasks
        if selectedLevel == .babysitter {
            tasks.append(.wiperAndStroll)
        } else if selectedLevel == .server {
            tasks.append(.takeOrder)
        }
        
        return tasks.isEmpty ? [.stroll, .radar, .elevator, .kangaroo] : tasks
    }

    // MARK: - Presentation UI Helpers
    
    // Vignette
    var visualDangerVignetteColor: Color {
        let tiltDanger = dangerRatio // already 0.0 to 1.0

        // calculate time danger (0.0 to 1.0) during last 10 sec
        var timeDanger: Double = 0
        if timeRemaining <= 10.0 {
            timeDanger = 1.0 - (timeRemaining.clamped(to: 0...10) / 10.0)
        }

        let combinedIntensity = max(tiltDanger, timeDanger * 0.8)
        let cappedOpacity = combinedIntensity.clamped(to: 0...0.8)

        return Color(red: 1.0, green: 0.0, blue: 0.0, opacity: cappedOpacity)
    }
    
    var displayTaskText: String {
        if selectedLevel == .babysitter && babyWarningActive {
            return "FREEZE!"
        }
        return task.simplifiedInstructions
    }
    
    var currentBackgroundAsset: String { phase == .result && !didWin ? selectedLevel.failBackground : selectedLevel.gameplayBackground }
    var showGameplayItem: Bool { !(phase == .result && !didWin) }
    var activeBabyAsset: String { babyWarningActive ? "baby_warning" : "baby_sleeping" }
    var effectiveTargetRoll: Double { selectedLevel == .server ? serverTargetRoll : 0 }
    var currentHorizontalTiltDegrees: Double { wrappedTiltDelta(sensor.horizontalTiltDegrees, neutralHorizontalTiltDegrees) }
    var currentVerticalTiltDegrees: Double { wrappedTiltDelta(sensor.verticalTiltDegrees, neutralVerticalTiltDegrees) }
    var displayedHorizontalTiltDegrees: Double { -currentHorizontalTiltDegrees }
    var displayedTargetRoll: Double { -effectiveTargetRoll }
    var relativeRoll: Double { currentHorizontalTiltDegrees - effectiveTargetRoll }
    var effectiveTiltToleranceDegrees: Double { selectedDifficulty.config.tiltToleranceDegrees * gameplayTiltToleranceMultiplier }
    
    // Separate vertical tolerance from diff
    private var fixedVerticalTolerance: Double { 15.0 * gameplayTiltToleranceMultiplier }
    
    var currentTiltDegrees: Double {
        let verticalScaleFactor = effectiveTiltToleranceDegrees / fixedVerticalTolerance
        let mathematicallyAdjustedVertical = currentVerticalTiltDegrees * verticalScaleFactor
        
        return sqrt(pow(relativeRoll, 2) + pow(mathematicallyAdjustedVertical, 2))
    }
    
    var dangerRatio: Double { (currentTiltDegrees / effectiveTiltToleranceDegrees).clamped(to: 0...1) }
    
    var dangerColor: Color {
        // Lock to safe green during countdown
        guard phase == .playing else { return Color(red: 0.361, green: 0.992, blue: 0.463) }
        
        let ratio = dangerRatio
        
        let r, g, b: Double
        if ratio < 0.5 {
            let f = ratio / 0.5
            r = 0.361 + f * (1.000 - 0.361)
            g = 0.992 + f * (0.953 - 0.992)
            b = 0.463 + f * (0.435 - 0.463)
        } else {
            let f = (ratio - 0.5) / 0.5
            r = 1.000 + f * (1.000 - 1.000)
            g = 0.953 + f * (0.275 - 0.953)
            b = 0.435 + f * (0.275 - 0.435)
        }
        return Color(red: r, green: g, blue: b)
    }

    var trayFoodOffset: CGSize {
        let horizontalSlide = (-displayedTargetRoll).clamped(to: -10...10) * foodHorizontalSlideMultiplier
        let verticalSlide = (currentVerticalTiltDegrees / 2.5).clamped(to: -10...10) * foodVerticalSlideMultiplier
        return CGSize(width: horizontalSlide, height: verticalSlide)
    }

    var difficultyText: String { selectedDifficulty.title }
    var countdownText: String { "\(max(1, Int(ceil(introCountdown))))" }
    var timerText: String {
        let totalSeconds = Int(ceil(timeRemaining))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "0:%02d", totalSeconds)
        }
    }
    var showHUD: Bool { phase == .countdown || phase == .playing }
    
    // Meter Configs (from GameConfig)
    var safeZoneWidthRatio: CGFloat { 0.15 }
    var warningZoneWidthRatio: CGFloat {
        let ratio = effectiveTiltToleranceDegrees / selectedDifficulty.config.meterDisplayRangeDegrees
        return CGFloat(ratio).clamped(to: 0.2...1.0)
    }
    
    var greenTargetRoll: Double {
        guard phase == .playing else { return effectiveTargetRoll }
        let elapsed = selectedDifficulty.config.roundSeconds - timeRemaining
        return effectiveTargetRoll + (sin(elapsed * selectedDifficulty.config.greenBarSpeed) * selectedDifficulty.config.greenBarAmplitude)
    }
    
    func normalizedBarPosition(for degrees: Double, maxDisplay: Double) -> Double {
        ((degrees.clamped(to: -maxDisplay...maxDisplay) + maxDisplay) / (maxDisplay * 2)).clamped(to: 0...1)
    }
    
    // UI change based on visual sensitivity (meterDisplayRangeDegrees)
    var meterOrangeTargetPosition: Double {
        guard phase == .playing else { return 0.5 } // stays centered during countdown
        return normalizedBarPosition(for: displayedTargetRoll, maxDisplay: selectedDifficulty.config.meterDisplayRangeDegrees)
    }
    
    var meterGreenTargetPosition: Double {
        guard phase == .playing else { return 0.5 } // freeze during countdown
        return normalizedBarPosition(for: -greenTargetRoll, maxDisplay: selectedDifficulty.config.meterDisplayRangeDegrees)
    }
    
    var meterCurrentPosition: Double {
        guard phase == .playing else { return 0.5 }
        return normalizedBarPosition(for: displayedHorizontalTiltDegrees, maxDisplay: selectedDifficulty.config.meterDisplayRangeDegrees)
    }
    
    var meterVerticalPosition: Double {
        guard phase == .playing else { return 0.5 }
        return normalizedBarPosition(for: currentVerticalTiltDegrees, maxDisplay: 32.0)
    }

    private func wrappedTiltDelta(_ current: Double, _ baseline: Double) -> Double {
        var delta = (current - baseline).truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        return delta
    }
    
}
