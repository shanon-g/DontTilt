//
//  CountdownOverlay.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 17/03/26.
//
// MARK: - UI OVERLAY: DISPLAYS 3-SECOND START ANIMATION

import SwiftUI

struct CountdownOverlay: View {
    let numberText: String

    @State private var animateNumber = false

    var body: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()

            ZStack {
                // Stroke outline
                Group {
                    Text(numberText).offset(x: 8, y: 8)
                    Text(numberText).offset(x: -8, y: -8)
                    Text(numberText).offset(x: 8, y: -8)
                    Text(numberText).offset(x: -8, y: 8)
                    Text(numberText).offset(x: 8, y: 0)
                    Text(numberText).offset(x: -8, y: 0)
                    Text(numberText).offset(x: 0, y: 8)
                    Text(numberText).offset(x: 0, y: -8)
                }
                .foregroundStyle(Palette.brown)
                
                // Main whote fill
                Text(numberText)
                    .foregroundStyle(.white)
            }
            // Apply font and animations to the entire ZStack at once
            .font(.custom(AppFonts.heading, size: 220))
            .fontWeight(.black)
            .shadow(color: .black.opacity(0.22), radius: 12, x: 0, y: 5)
            .scaleEffect(animateNumber ? 1.06 : 0.92)
            .opacity(animateNumber ? 1.0 : 0.82)
        }
        .onAppear {
            animateNumber = false
            withAnimation(.easeOut(duration: 0.85)) {
                animateNumber = true
            }
        }
        .onChange(of: numberText) {
            animateNumber = false
            withAnimation(.easeOut(duration: 0.85)) {
                animateNumber = true
            }
        }
    }
}
