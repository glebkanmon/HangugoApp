import SwiftUI

struct AppRootView: View {
    @AppStorage("isOnboardingDone") private var isOnboardingDone: Bool = false
    
    var body: some View {
        if isOnboardingDone {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    AppRootView()
}
