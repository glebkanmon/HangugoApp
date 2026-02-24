import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                LearnView()
            }
            .tabItem {
                Label("Изучение", systemImage: "book")
            }

            NavigationStack {
                PracticeView()
            }
            .tabItem {
                Label("Практика", systemImage: "square.and.pencil")
            }

            NavigationStack {
                SettingsView()
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
