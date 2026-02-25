//
//  HangugoAppApp.swift
//  HangugoApp
//
//  Created by Gleb Monetchikov on 10.01.2026.
//

import SwiftUI

@main
struct HangugoAppApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(\.appContainer, container)
        }
    }
}
