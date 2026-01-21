import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                LearnView()
            }
            .tabItem {
                Label("Learn", systemImage: "book")
            }

            NavigationStack {
                PracticeView()
            }
            .tabItem {
                Label("Practice", systemImage: "square.and.pencil")
            }

            NavigationStack {
                ReviewView()
            }
            .tabItem {
                Label("Review", systemImage: "clock.arrow.circlepath")
            }
        }
    }
}

#Preview {
    MainTabView()
}
