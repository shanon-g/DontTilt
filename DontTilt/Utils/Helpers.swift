//
//  Helpers.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 16/03/26.
//
// MARK: - GLOBAL EXTENSIONS: NUMBER CLAMPING & HEX COLOR CONVERSIONS

import SwiftUI

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)

        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
