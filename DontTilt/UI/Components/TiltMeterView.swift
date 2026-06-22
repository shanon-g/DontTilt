//
//  TiltMeterView.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 17/03/26.
//
// MARK: - CUSTOM UI COMPONENT: DYNAMIC TILT BAR & PHONE INDICATOR

import SwiftUI

struct TiltMeterView: View {
    let orangeTargetPosition: Double
    let greenTargetPosition: Double // NEW: Independent green tracking
    let currentXPosition: Double
    let currentYPosition: Double
    let screenColor: Color
    
    let safeZoneRatio: CGFloat
    let warningZoneRatio: CGFloat

    private let barHeight: CGFloat = 32

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            let orangeX = CGFloat(orangeTargetPosition) * width
            let greenX = CGFloat(greenTargetPosition) * width
            let phoneX = CGFloat(currentXPosition) * width
            let phoneY = CGFloat(currentYPosition) * height

            ZStack {
                // MARK: 1. The Background Track
                ZStack {
                    Capsule()
                        .fill(Palette.danger)

                    // Moving Yellow/Orange Warning Zone
                    Rectangle()
                        .fill(Palette.peach)
                        .frame(width: width * warningZoneRatio)
                        .position(x: orangeX, y: barHeight / 2)

                    // Moving Green Safe Zone (Moves separately)
                    Rectangle()
                        .fill(Palette.green)
                        .frame(width: width * safeZoneRatio)
                        .position(x: greenX, y: barHeight / 2)
                }
                .clipShape(Capsule())
                .frame(height: barHeight)
                .overlay(Capsule().stroke(Palette.ink, lineWidth: 3))
                .background(Capsule().stroke(Palette.cream, lineWidth: 6).padding(-3))
                .position(x: width / 2, y: height / 2)

                // MARK: 2. The Phone Indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(screenColor)
                        .frame(width: 22, height: 44)

                    Image("phone_bezel")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 70)
                }
                .position(x: phoneX.clamped(to: 12...(width - 12)), y: phoneY)
            }
        }
    }
}
