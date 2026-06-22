//
//  GameplayView.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 16/03/26.
//
// MARK: - CORE GAME UI: RENDERS TRAY, HUD, & INTERACTIVE GESTURES

import SwiftUI

struct GameplayView: View {
    @ObservedObject var vm: GameViewModel

    // Server tray sizing
    private let trayWidth: CGFloat = 420
    private let foodWidth: CGFloat = 280

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. Background & Level Items (blur at countdown)
                ZStack {
                    backgroundLayer
                    itemLayer
                }
                .blur(radius: vm.phase == .countdown ? 10 : 0)
                .overlay(Color.black.opacity(vm.tutorial.isActive && vm.tutorial.step <= 4 ? 0.6 : 0))

                // 2. HUD Layer (handles internal blurring)
                if vm.showHUD && vm.phase != .result {
                    hudLayer
                }
                
                // 3. Vignette
                if vm.phase == .playing {
                    RadialGradient(
                        gradient: Gradient(colors: [.clear, vm.visualDangerVignetteColor]),
                        center: .center,
                        startRadius: 36,
                        endRadius: 500   // fit screen geometry
                    )
                    .ignoresSafeArea()
                    .opacity(vm.babyWarningActive ? 0 : 1)
                }
                
                // 4. Full Screen Interaction Layer
                Color.clear
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 24)
                            .onEnded { value in
                                let distance = hypot(value.translation.width, value.translation.height)
                                vm.registerSwipe(distance: distance)
                            }
                    )
                    .onTapGesture {
                        vm.registerTap()
                    }

                // 5. Overlays (Win/Loss/Countdown)
                if vm.phase == .countdown {
                    CountdownOverlay(numberText: vm.countdownText)
                }
                
                // FREEZE Warning
                if vm.selectedLevel == .babysitter && vm.babyWarningActive {
                    freezeOverlay
                }

                if vm.phase == .result {
                    ResultOverlay(didWin: vm.didWin)
                }
                
                // TUTORIAL
                if vm.tutorial.isActive {
                    TutorialOverlay(
                        tutorial: vm.tutorial,
                        level: vm.selectedLevel
                    )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var backgroundLayer: some View {
        Image(vm.currentBackgroundAsset)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }

    @ViewBuilder
    private var itemLayer: some View {
        if vm.showGameplayItem {
            switch vm.selectedLevel {
            case .server:
                serverTrayView
                    .offset(y: 130)

            case .babysitter:
                Image(vm.activeBabyAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 730)
                    .offset(y: 36)
                    .offset(x: 12)
            }
        }
    }

    private var serverTrayView: some View {
        ZStack {
            Image("tray_clean")
                .resizable()
                .scaledToFit()
                .frame(width: trayWidth)

            Image("tray_food")
                .resizable()
                .scaledToFit()
                .frame(width: foodWidth)
                .offset(serverFoodOffset)
        }
    }

    private var serverFoodOffset: CGSize {
        CGSize(
            width: vm.trayFoodOffset.width * 0.42,
            height: -108 + (vm.trayFoodOffset.height * 0.22)
        )
    }

    // MARK: - THE HUD
    @ViewBuilder
    private var hudLayer: some View {
        VStack {
            // MARK: 1. THE TOP: WIDE TILT BAR (Blurred during countdown)
            TiltMeterView(
                orangeTargetPosition: vm.meterOrangeTargetPosition,
                greenTargetPosition: vm.meterGreenTargetPosition,
                currentXPosition: vm.meterCurrentPosition,
                currentYPosition: vm.meterVerticalPosition,
                screenColor: vm.dangerColor,
                safeZoneRatio: vm.safeZoneWidthRatio,
                warningZoneRatio: vm.warningZoneWidthRatio
            )
            .frame(height: 90)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .shadow(color: .black.opacity(0.50), radius: 10, x: 0, y: 8)
            .blur(radius: vm.phase == .countdown ? 10 : 0)
            .tutorialSpotlight(tutorial: vm.tutorial, component: .tiltMeter)

            Spacer()

            // MARK: 2. THE BOTTOM: TIMER & TASK BUBBLE
            HStack(alignment: .bottom) {
                
                // LEFT: Timer Capsule (Blurred during countdown)
                HStack(spacing: 8) {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text(vm.timerText)
                        .font(.custom(AppFonts.heading, size: 24))
                        .fontWeight(.black)
                }
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Palette.cream)
                .overlay(Capsule().stroke(Palette.ink, lineWidth: 3))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.50), radius: 10, x: 0, y: 8)
                .blur(radius: vm.phase == .countdown ? 10 : 0)
                .tutorialSpotlight(tutorial: vm.tutorial, component: .timer)

                Spacer()

                // RIGHT: Combined Task Box (not blurred)
                taskBubble
                    .tutorialSpotlight(tutorial: vm.tutorial, component: .taskBubble)
            }
            .padding(24)
        }
    }

    // MARK: - BOTTOM RIGHT TASK BUBBLE
    private var taskBubble: some View {
        HStack(spacing: 16) {
            
            // Instruction Texts (Right-aligned to point towards the icon)
            VStack(alignment: .trailing, spacing: 4) {
                
                // 1. Simplified Action ("JUMP")
                Text(vm.displayTaskText)
                    .font(.custom(AppFonts.heading, size: 20))
                    .fontWeight(.black)
                    .foregroundStyle(Palette.ink)
                
                // 2. Normal Instructions ("Jump 10 times")
                Text(vm.task.instructions)
                    .font(.custom(AppFonts.body, size: 12))
                    .fontWeight(.bold)
                    .foregroundStyle(Palette.ink.opacity(0.65))
                
                // 3. Exact Goal Progress ("Jumps 5 / 10")
                Text(vm.taskProgressText)
                    .font(.custom(AppFonts.body, size: 16))
                    .fontWeight(.heavy)
                    .foregroundStyle(Palette.ink)
            }
            .multilineTextAlignment(.trailing)

            // Circular Progress & Icon
            ZStack {
                Circle()
                    .stroke(Palette.ink.opacity(0.15), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: CGFloat(vm.taskProgressFraction))
                    .stroke(
                        vm.babyWarningActive ? Palette.danger : Palette.green,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: vm.taskProgressFraction)

                Image(vm.task.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            }
            .frame(width: 64, height: 64)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Palette.cream)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.ink, lineWidth: 3))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.50), radius: 10, x: 0, y: 8)
    }
    
    // MARK: - FULL SCREEN FREEZE OVERLAY
    private var freezeOverlay: some View {
        ZStack {
            // Darken the background slightly to make the red text pop
            Color.blue.opacity(0.25).ignoresSafeArea()
            
            ZStack {
                // stroke outline
                Group {
                    Text("FREEZE!").offset(x: 6, y: 6)
                    Text("FREEZE!").offset(x: -6, y: -6)
                    Text("FREEZE!").offset(x: 6, y: -6)
                    Text("FREEZE!").offset(x: -6, y: 6)
                    Text("FREEZE!").offset(x: 6, y: 0)
                    Text("FREEZE!").offset(x: -6, y: 0)
                    Text("FREEZE!").offset(x: 0, y: 6)
                    Text("FREEZE!").offset(x: 0, y: -6)
                }
                .foregroundStyle(Palette.ink)
                
                // main text
                Text("FREEZE!")
                    .foregroundStyle(Palette.danger)
                    .opacity(0.8)
            }
            .font(.custom(AppFonts.heading, size: 120))
            .fontWeight(.black)
        }
    }
}

// MARK: - CUSTOM SPOTLIGHT MODIFIER
extension View {
    func tutorialSpotlight(tutorial: TutorialConfig, component: TutorialComponent) -> some View {
        // Only dim/blur during steps 1, 2, 3, 4
        let isSpotlightActive = tutorial.isActive && tutorial.step <= 4
        let isActiveComponent = tutorial.highlightedComponent == component
        
        return self
            .opacity(isSpotlightActive ? (isActiveComponent ? 1.0 : 0.3) : 1.0)
            .blur(radius: isSpotlightActive && !isActiveComponent ? 6 : 0)
            .animation(.easeInOut(duration: 0.6), value: isActiveComponent)
            .animation(.easeInOut(duration: 0.6), value: isSpotlightActive)
    }
}

// MARK: - CANVAS PREVIEWS
/// (cmd + opt +enter / p)

#Preview("1. Countdown Phase") {
    let vm = GameViewModel()
    vm.phase = .countdown
    vm.selectedLevel = .server
    vm.introCountdown = 2.0
    vm.task = .stroll
    
    return GameplayView(vm: vm)
}

#Preview("2. Playing (Danger Zone)") {
    let vm = GameViewModel()
    vm.phase = .playing
    vm.selectedLevel = .server
    vm.timeRemaining = 12.0
    vm.task = .moonwalk
    vm.taskProgressText = "5 / 15"
    vm.taskProgressFraction = 0.33
    vm.sensor.horizontalTiltDegrees = 8.5
    vm.sensor.verticalTiltDegrees = -4.0
    vm.serverTargetRoll = 2.0
    
    return GameplayView(vm: vm)
}

#Preview("3. Result (Win)") {
    let vm = GameViewModel()
    vm.phase = .result
    vm.selectedLevel = .babysitter
    vm.didWin = true
    
    return GameplayView(vm: vm)
}
