//
//  RootView.swift
//  DontTilt
//
//  Created by Shanon Giuly Istanto on 16/03/26.
//
// MARK: - TRAFFIC COP: SWITCHES BETWEEN MAIN MENU & GAMEPLAY VIEWS

import SwiftUI

struct RootView: View {
    @StateObject private var vm = GameViewModel()

    var body: some View {
        ZStack {
            if vm.phase == .menu {
                MainMenuView(vm: vm)
            } else {
                GameplayView(vm: vm)
            }
        }
        .ignoresSafeArea()
        .background(Palette.ink)
    }
}
