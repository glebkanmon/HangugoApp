import SwiftUI

struct OnboardingView: View {
    @AppStorage("isOnboardingDone") private var isOnboardingDone: Bool = false
    @AppStorage("userLevel") private var userLevelRaw: String = UserLevel.beginner.rawValue
    
    private var userLevelBinding: Binding<UserLevel> {
        Binding(
            get: {
                UserLevel(rawValue: userLevelRaw) ?? .beginner
            },
            set: {
                userLevelRaw = $0.rawValue
            }
        )
    }

    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Корейский без рутины")
                            .font(.title2).bold()
                        Text("Учи слова с удовольствием и понимай, как язык устроен. Практикуй предложения и получай ясные объяснения конструкций и «мышления носителей» с помощью AI.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                Section("Уровень") {
                    Picker("Уровень", selection: userLevelBinding) {
                        ForEach(UserLevel.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Button("Продолжить") {
                        isOnboardingDone = true
                    }
                }
            }
        }
        .navigationTitle("Добро пожаловать!")
    }
}

#Preview {
    OnboardingView()
}
