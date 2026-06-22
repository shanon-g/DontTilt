//
//  TutorialOverlay.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 31/03/26.
//

import SwiftUI

struct TutorialOverlay: View {
    @ObservedObject var tutorial: TutorialConfig
    var level: LevelPage

    var body: some View {
        // GEOMETRY READER: Makes sizing bulletproof across all iPhone models
        GeometryReader { geo in
            ZStack {
                // MARK: - THE "VIEW ALL TASKS" MODAL
                if tutorial.showTasksModal {
                    AllTasksModalView(isShowing: $tutorial.showTasksModal)
                        .zIndex(200)
                }

                // MARK: - DYNAMIC TOOLTIP PLACEMENT
                VStack {
                    // 1. TOP SPACER: Pushes tooltip to the BOTTOM
                    if tutorial.step >= 3 { Spacer() }
                    
                    HStack {
                        // 2. LEFT SPACER: Pushes tooltip to the RIGHT
                        if tutorial.step == 3 { Spacer() }
                        
                        tooltipCard(geo: geo) // text box card thingy
                        
                        // 3. RIGHT SPACER: Pushes tooltip to the LEFT
                        if tutorial.step == 4 { Spacer() }
                    }
                    
                    .padding(.leading, tutorial.step == 4 ? 2 : 0)
                    .padding(.trailing, tutorial.step == 3 ? 24 : 0)
                    
                    // 4. BOTTOM SPACER: Pushes tooltip to the TOP
                    if tutorial.step == 1 || tutorial.step == 2 { Spacer() }
                }
                // 5. PIXEL ADJUSTMENTS:
                .padding(.top, (tutorial.step == 1 || tutorial.step == 2) ? 100 : 0)
//                .padding(.leading, (tutorial.step == 1 || tutorial.step == 2) ? 50 : 0)
                
                .padding(.bottom, (tutorial.step == 3) ? 140 : 0)
//                .padding(.horizontal, (tutorial.step == 3) ? -30 : 0)
                
                .padding(.bottom, (tutorial.step == 4) ? 90 : 0)
                .padding(.leading, (tutorial.step == 4) ? 40 : 0)
                
                .padding(.bottom, (tutorial.step == 5 || tutorial.step == 6) ? 5 : 0)
//                .padding(.leading, (tutorial.step == 5 || tutorial.step == 6) ? 50 : 0)
                
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .zIndex(100)
            .animation(.spring(response: 0.6, dampingFraction: 0.75), value: tutorial.step)
            .ignoresSafeArea()
        }
    }
    
    // MARK: - THE TOOLTIP CARD
    private func tooltipCard(geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(tutorial.message(for: level))
                .font(.custom(AppFonts.body, size: 12))
                .fontWeight(.bold)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
            
            HStack(spacing: 8) {
                
                // "VIEW ALL TASKS" Button (Left Side)
                if tutorial.step == 3 {
                    Button(action: { tutorial.showTasksModal = true }) {
                        Text("View All Tasks")
                            .font(.custom(AppFonts.body, size: 12).bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Palette.periwinkle)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // "BACK" BUTTON (Right Side)
                if tutorial.step > 1 {
                    Button(action: { tutorial.previousStep() }) {
                        Text("Back")
                            .font(.custom(AppFonts.heading, size: 14))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Palette.danger)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                
                // "NEXT" BUTTON (Right Side)
                let isDisabled = (tutorial.step == 6) || (tutorial.step == 3 && !tutorial.tutTaskComplete)
                
                Button(action: { tutorial.nextStep() }) {
                    Text(tutorial.step == 6 ? "Wait to Fail..." : "Next (\(tutorial.step)/6)")
                        .font(.custom(AppFonts.heading, size: 14))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(isDisabled ? Palette.ink.opacity(0.4) : Palette.periwinkle)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
            }
        }
        .padding(14)
        .frame(width: safeTooltipWidth(geo: geo))
        .background(Color.white.opacity(0.95))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.brown, lineWidth: 3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
    }
    
    // MARK: - DYNAMIC SIZING LOGIC
    private func safeTooltipWidth(geo: GeometryProxy) -> CGFloat {
        // Prevents card from breaking the screen bounds on smaller phones
        let maxSafeWidth = geo.size.width * 0.90
        
        var desiredWidth: CGFloat = 350
        switch tutorial.step {
        case 1: desiredWidth = 350
        case 2: desiredWidth = 320
        case 3: desiredWidth = 350
        case 4: desiredWidth = 230
        case 5, 6: desiredWidth = 280
        default: desiredWidth = 350
        }
        
        return min(desiredWidth, maxSafeWidth)
    }
}

// MARK: - ALL TASKS MODAL POPUP
struct AllTasksModalView: View {
    @Binding var isShowing: Bool
    
    let allTasks: [TaskKind] = [.stroll, .moonwalk, .elevator, .kangaroo, .compass, .radar, .wiperAndStroll, .takeOrder]
    
    var body: some View {
        ZStack {
            // Background dimming layer
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { isShowing = false }
            
            HStack {
                // actual Modal Card
                VStack(spacing: 10) {
                    Text("Available Tasks")
                        .font(.custom(AppFonts.heading, size: 14))
                        .foregroundStyle(Palette.brown)
                    
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(allTasks, id: \.self) { task in
                                HStack(spacing: 6) {
                                    Image(task.iconAsset)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.simplifiedInstructions)
                                            .font(.custom(AppFonts.heading, size: 12))
                                            .foregroundStyle(Palette.ink)
                                        Text(task.instructions)
                                            .font(.custom(AppFonts.body, size: 10))
                                            .foregroundStyle(Palette.ink.opacity(0.6))
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.ink.opacity(0.1), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 6)
                    }
                    .frame(maxWidth: 280, maxHeight: 250)
                    
                    Button("Close") { isShowing = false }
                        .font(.custom(AppFonts.heading, size: 14))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Palette.danger)
                        .clipShape(Capsule())
                }
                .padding(10)
                .background(Palette.cream)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.3), radius: 20)
                .padding(.leading, 30)
                
                Spacer()
            }
        }
        .animation(.easeInOut, value: isShowing)
    }
}

// MARK: - CANVAS PREVIEWS
/// cmd + opt + enter

#Preview("Step 1 & 2: Tilt Meter") {
    let vm = GameViewModel()
    vm.selectedLevel = .server
    vm.startGame(isTutorial: true)
    vm.tutorial.step = 1
    
    vm.sensor.horizontalTiltDegrees = 2.0
    vm.sensor.verticalTiltDegrees = -1.0
    
    return GameplayView(vm: vm)
}

#Preview("Step 3: Task") {
    let vm = GameViewModel()
    vm.selectedLevel = .server
    vm.startGame(isTutorial: true)
    vm.tutorial.step = 3
    vm.taskProgressFraction = 0.5
    
    return GameplayView(vm: vm)
}

#Preview("All Tasks") {
    let vm = GameViewModel()
    vm.selectedLevel = .server
    vm.startGame(isTutorial: true)
    vm.tutorial.step = 3
    
    vm.tutorial.showTasksModal = true   // force the modal to open
    
    return GameplayView(vm: vm)
}

#Preview("Step 4: Timer") {
    let vm = GameViewModel()
    vm.selectedLevel = .server
    vm.startGame(isTutorial: true)
    vm.tutorial.step = 4
    vm.timeRemaining = 45.0
    
    return GameplayView(vm: vm)
}

#Preview("Step 5 & 6: Gimmick / Fail") {
    let vm = GameViewModel()
    vm.selectedLevel = .babysitter
    vm.startGame(isTutorial: true)
    vm.tutorial.step = 5
    
    return GameplayView(vm: vm)
}
