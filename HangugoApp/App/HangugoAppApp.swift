import SwiftUI
import FirebaseCore

@main
struct HangugoAppApp: App {
    private let container: AppContainer

    init() {
        FirebaseApp.configure()
        self.container = AppContainer()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(\.appContainer, container)
        }
    }
}
