import SwiftUI

struct MainTabView: View {
    @Environment(\.appContainer) private var container

    var body: some View {
        TabView {
            NavigationStack {
                LearnView(container: container)
            }
            .tabItem {
                Label("Изучение", systemImage: "book")
            }

            NavigationStack {
                PracticeView(container: container)
            }
            .tabItem {
                Label("Практика", systemImage: "square.and.pencil")
            }

            NavigationStack {
                SettingsView(container: container)
            }
            .tabItem {
                Label("Настройки", systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    MainTabView()
}
