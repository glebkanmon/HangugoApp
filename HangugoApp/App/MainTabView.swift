import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            LearnView().tabItem {
                Label("Learn", systemImage: "book")
            }
            PracticeView().tabItem {
                Label("Practice", systemImage: "square.and.pencil")
            }
            ReviewView().tabItem {
                Label("Review", systemImage: "clock.arrow.circlepath")
            }
        }
    }
}

#Preview {
    MainTabView()
}
