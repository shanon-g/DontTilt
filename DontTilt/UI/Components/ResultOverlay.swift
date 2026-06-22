//
//  ResultOverlay.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 17/03/26.
//
// MARK: - UI OVERLAY: DISPLAYS WIN/LOSS SCREEN

import SwiftUI

struct ResultOverlay: View {
    let didWin: Bool
//    let title: String
//    let subtitle: String

    @State private var flashing = false

    var body: some View {
        ZStack {
            // The flashing background (Green for win, Red for loss)
            (didWin ? Palette.green : Palette.danger)
                .opacity(flashing ? 0.16 : 0.32)
                .ignoresSafeArea()

            // Only show if the player lost
//            if !didWin {
//                VStack(spacing: 14) {
//                    Text(title)
//                        .font(.custom(AppFonts.heading, size: 44))
//                        .fontWeight(.black)
//                        .foregroundStyle(.white)
//
//                    Text(subtitle)
//                        .font(.custom(AppFonts.body, size: 22))
//                        .fontWeight(.semibold)
//                        .foregroundStyle(.white.opacity(0.95))
//                }
//                .padding(.horizontal, 30)
//                .padding(.vertical, 22)
//                .background(
//                    RoundedRectangle(cornerRadius: 26)
//                        .fill(Palette.ink.opacity(0.65))
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 26)
//                                .stroke(.white.opacity(0.75), lineWidth: 2.5)
//                        )
//                )
//            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                flashing.toggle()
            }
        }
    }
}
