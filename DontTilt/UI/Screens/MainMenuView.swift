//
//  MainMenuView.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 16/03/26.
//
// MARK: - START SCREEN: LEVEL/DIFFICULTY SELECTOR & TUTORIAL VIEWS

import SwiftUI

struct MainMenuView: View {
    @ObservedObject var vm: GameViewModel
    @State private var logoSwaying = false
    @State private var menuPulse = false

    private let panelWidth: CGFloat = 1100
    private let panelHeight: CGFloat = 540
    private let cornerRadius: CGFloat = 38

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 1200, geo.size.height / 700)
            let finalPanelWidth = min(panelWidth * scale, geo.size.width - 60)
            let finalPanelHeight = min(panelHeight * scale, geo.size.height - 70)

            ZStack {
                Image(vm.selectedLevel.gameplayBackground)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .blur(radius: 16)
                    .overlay(Color.black.opacity(0.20))
                    .ignoresSafeArea()

                ZStack(alignment: .top) {
                    Image("menu_bg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: finalPanelWidth, height: finalPanelHeight)
                        .clipped()
                        .clipShape(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(Palette.brown, lineWidth: 6)
                        )

                    VStack(spacing: 0) {
                        Spacer().frame(height: 100 * scale)

                        HStack(alignment: .top, spacing: 26 * scale) {
                            leftColumn(scale: scale)
                            rightTutorialCard(scale: scale)
                        }
                        .padding(.horizontal, 34 * scale)

                        Spacer()

                        startButtonSection(scale: scale)
                            .padding(.bottom, 24 * scale)
                    }

                    Image("app_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 215 * scale)
                        .rotationEffect(.degrees(logoSwaying ? 1.95 : -1.95))
                        .shadow(color: .black.opacity(0.10), radius: 10 * scale)
                        .offset(y: -44 * scale)
                        .zIndex(10)
                }
                .frame(width: finalPanelWidth, height: finalPanelHeight)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                ) {
                    logoSwaying = true
                }

                withAnimation(
                    .easeInOut(duration: 1)
                    .repeatForever(autoreverses: true)
                ) {
                    menuPulse = true
                }
            }
        }
    }

    // MARK: - Left side (Scaled Down)

    private func leftColumn(scale: CGFloat) -> some View {
        VStack(spacing: 20 * scale) {
            
            // MARK: LEVEL CARD
            VStack(spacing: 12 * scale) {
                
                // TOP Row: Title and Preview Image
                ZStack(alignment: .top) {
                    Image(vm.selectedLevel.previewImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 400 * scale, height: 96 * scale)
                        .clipped()
                        .clipShape(
                            RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                        )

                    Text(vm.selectedLevel.title)
                        .font(.custom(AppFonts.body, size: 26 * scale))
                        .fontWeight(.bold)
                        .foregroundStyle(Palette.brown)
                        .padding(.horizontal, 16 * scale)
                        .padding(.vertical, 6 * scale)
                        .background(Color.white.opacity(0.96))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                                .stroke(Palette.brown, lineWidth: 2)
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                        )
                        .offset(y: -24 * scale)
                        .zIndex(1)
                }
                .padding(.top, 16 * scale)
                
                // BOTTOM Row: Level Selector
                HStack {
                    Text("Level")
                        .font(.custom(AppFonts.heading, size: 28 * scale))
                        .fontWeight(.bold)
                        .foregroundStyle(Palette.brown)

                    Spacer()

                    HStack(spacing: 16 * scale) {
                        arrowButton(system: "chevron.left", scale: scale) {
                            vm.cycleLevel(next: false)
                        }

                        selectedLevelIcon(scale: 1.1 * scale)

                        arrowButton(system: "chevron.right", scale: scale) {
                            vm.cycleLevel(next: true)
                        }
                    }
                }
                
            }
            .padding(.horizontal, 16 * scale)
            .padding(.vertical, 16 * scale)
            .frame(width: 440 * scale)
            .background(
                RoundedRectangle(cornerRadius: 24 * scale, style: .continuous)
                    .fill(Color.white.opacity(0.80))
            )

            // MARK: DIFFICULTY CARD
            selectorCard(
                title: "Difficulty",
                scale: scale
            ) {
                HStack(spacing: 16 * scale) {
                    arrowButton(system: "chevron.left", scale: scale) {
                        vm.cycleDifficulty(next: false)
                    }

                    difficultyBadge(scale: scale)

                    arrowButton(system: "chevron.right", scale: scale) {
                        vm.cycleDifficulty(next: true)
                    }
                }
            }
        }
        .frame(width: 440 * scale, alignment: .topLeading)
        .padding(.top, 12 * scale)
        .bold()
    }

    private func selectorCard<Content: View>(
        title: String,
        scale: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Text(title)
                .font(.custom(AppFonts.heading, size: 26 * scale))
                .fontWeight(.bold)
                .foregroundStyle(Palette.brown)

            Spacer()

            content()
        }
        .padding(.horizontal, 16 * scale)
        .frame(width: 440 * scale, height: 86 * scale) // Scaled down from 540x102
        .background(
            RoundedRectangle(cornerRadius: 24 * scale, style: .continuous)
                .fill(Color.white.opacity(0.80))
        )
    }

    @ViewBuilder
    private func selectedLevelIcon(scale: CGFloat) -> some View {
        Group {
            switch vm.selectedLevel {
            case .server:
                Image("server_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100 * scale, height: 50 * scale) // Scaled down

            case .babysitter:
                Image("baby_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100 * scale, height: 50 * scale) // Scaled down
            }
        }
        .scaleEffect(menuPulse ? 1.05 : 0.97)
    }

    private func difficultyBadge(scale: CGFloat) -> some View {
        Text(vm.selectedDifficulty.title)
            .font(.custom(AppFonts.body, size: 20 * scale))
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .frame(width: 110 * scale, height: 38 * scale)
            .background(vm.selectedDifficulty.badgeColor)
            .overlay(
                RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                    .stroke(Palette.brown.opacity(0.25), lineWidth: 1.5)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
            )
            .scaleEffect(menuPulse ? 1.035 : 0.985)
    }
    

    // MARK: - Right side (Text Top, Images Bottom)

    private func rightTutorialCard(scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // TOP: Instructions Text
            VStack(alignment: .leading, spacing: 8 * scale) {
                Text("INSTRUCTIONS:")
                    .font(.custom(AppFonts.heading, size: 26 * scale))
                    .fontWeight(.bold)
                    .foregroundStyle(Palette.brown)

                VStack(alignment: .leading, spacing: 6 * scale) {
                    ForEach(holdTips, id: \.self) { tip in
                        Text("• \(tip)")
                            .font(.custom(AppFonts.body, size: 16 * scale))
                            .fontWeight(.semibold)
                            .foregroundStyle(Palette.brown)
                    }
                }
            }
            .padding(.horizontal, 26 * scale)
            .padding(.top, 22 * scale)

            Spacer()

            // BOTTOM: Tutorial Images
            HStack(spacing: 20 * scale) {
                
                // LEFT IMAGE: IRL Actions
                tutorialImageBox(imageName: vm.selectedLevel.actionTutorialImage, scale: scale)
                
                // RIGHT IMAGE: How to Hold
                tutorialImageBox(imageName: vm.selectedLevel.tutorialImage, scale: scale)
                
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 10 * scale)
        }
        .frame(width: 530 * scale, height: 312 * scale, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 24 * scale, style: .continuous)
                .fill(Color.white.opacity(0.80))
        )
        .padding(.top, 12 * scale)
    }

    private func tutorialImageBox(imageName: String, scale: CGFloat) -> some View {
        ZStack {
            Color.clear

            Image(imageName)
                .resizable()
                .scaledToFit()
        }
        .frame(width: 210 * scale, height: 160 * scale)
        .clipped()
        .scaleEffect(menuPulse ? 1.02 : 0.98)
    }

    private var holdTips: [String] {
        switch vm.selectedLevel {
        case .server:
            return ["!!! Finish the task to WIN !!!", "STAND UP & Do the Tasks IN REAL LIFE", "Place Phone on ONE Hand", "Open Palm"]
        case .babysitter:
            return ["!!! Finish the task to WIN !!!", "STAND UP & Do the Tasks IN REAL LIFE", "Place Phone on BOTH Hands", "Cradle Phone"]
        }
    }

    // MARK: - Bottom button

//    private func startButton(scale: CGFloat) -> some View {
//        Button {
//            vm.startGame()
//        } label: {
//            Text("Start")
//                .font(.custom(AppFonts.heading, size: 32 * scale))
//                .fontWeight(.bold)
//                .foregroundStyle(.white)
//                .frame(width: 164 * scale, height: 64 * scale)
//                .background(Palette.periwinkle)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 18 * scale, style: .continuous)
//                        .stroke(Palette.brown, lineWidth: 3)
//                )
//                .clipShape(
//                    RoundedRectangle(cornerRadius: 18 * scale, style: .continuous)
//                )
//        }
//        .buttonStyle(.plain)
//    }
    
    private func startButtonSection(scale: CGFloat) -> some View {
        HStack(spacing: 16 * scale) {
            
            // SECONDARY: TUTORIAL BUTTON
            Button {
                vm.startGame(isTutorial: true)
            } label: {
                HStack(spacing: 8 * scale) {
                    Image(systemName: vm.selectedLevel == .server ? "fork.knife.circle" : "stroller.fill")
                        .font(.system(size: 24 * scale, weight: .bold))
                    Text(vm.selectedLevel == .server ? "Tutorial" : "Tutorial")
                        .font(.custom(AppFonts.heading, size: 22 * scale))
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
                .frame(height: 64 * scale)
                .padding(.horizontal, 20 * scale)
                .background(Palette.periwinkle)
                .overlay(
                    RoundedRectangle(cornerRadius: 18 * scale, style: .continuous)
                        .stroke(Palette.brown, lineWidth: 3)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18 * scale, style: .continuous))
            }
            .buttonStyle(.plain)

            // PRIMARY: START BUTTON
            Button {
                vm.startGame(isTutorial: false)
            } label: {
                Text("Start")
                    .font(.custom(AppFonts.heading, size: 32 * scale))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 164 * scale, height: 64 * scale)
                    .background(Palette.sage)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18 * scale, style: .continuous)
                            .stroke(Palette.brown, lineWidth: 3)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18 * scale, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Shared UI

    private func arrowButton(
        system: String,
        scale: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 26 * scale, weight: .black))
                .scaleEffect(x: 1.15, y: 1.25)
        }
        // apply custom animation v
        .buttonStyle(ArrowButtonStyle(scale: scale))
    }
}

// MARK: - CUSTOM BUTTON STYLES

struct ArrowButtonStyle: ButtonStyle {
    let scale: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // bg inverse
            RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                .fill(configuration.isPressed ? Palette.brown : Color.white.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                        .stroke(Palette.brown, lineWidth: 2.5 * scale)
                )

            // icon inverse
            configuration.label
                .foregroundStyle(configuration.isPressed ? .white : Palette.brown)
        }
        .frame(width: 50 * scale, height: 50 * scale)
        .contentShape(RoundedRectangle(cornerRadius: 14 * scale, style: .continuous))
        
        // squish scale effect
        .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
        
        // smooth out
        .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - CANVAS PREVIEWS
/// (cmd + opt + enter / p)

#Preview("Main Menu - The Server") {
    let vm = GameViewModel()
    vm.phase = .menu
    vm.selectedLevel = .server
    vm.selectedDifficulty = .medium
    
    return MainMenuView(vm: vm)
        .ignoresSafeArea()
}

#Preview("Main Menu - The Babysitter") {
    let vm = GameViewModel()
    vm.phase = .menu
    vm.selectedLevel = .babysitter
    vm.selectedDifficulty = .hard
    
    return MainMenuView(vm: vm)
        .ignoresSafeArea()
}
