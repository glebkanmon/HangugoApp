// UI/Settings/SettingsView.swift

import SwiftUI
import AVFoundation

struct SettingsView: View {
    private let container: AppContainer

    @AppStorage("newWordsPerSession") private var newWordsPerSession: Int = 10
    @AppStorage("firstReviewTomorrow") private var firstReviewTomorrow: Bool = true

    @AppStorage("ttsSpeechRate") private var ttsSpeechRate: Double = {
        let defaultRate = Double(AVSpeechUtteranceDefaultSpeechRate)
        let minRate = Double(AVSpeechUtteranceMinimumSpeechRate)
        return max(minRate, defaultRate / 1.5)
    }()

    @State private var voices: [AVSpeechSynthesisVoice] = []
    @State private var selectedVoiceId: String?
    @State private var isVoiceHelpPresented: Bool = false

    private let speech: SpeechService

    init(container: AppContainer) {
        self.container = container
        self.speech = container.speechService
        _selectedVoiceId = State(initialValue: container.speechService.currentVoiceIdentifier())
    }

    var body: some View {
        Form {
            newWordsSection
            speechSection
        }
        .navigationTitle(L10n.Settings.navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadVoices)
        .alert(L10n.Settings.voiceHelpTitle, isPresented: $isVoiceHelpPresented) {
            Button(L10n.Settings.voiceHelpOk, role: .cancel) {}
        } message: {
            Text(L10n.Settings.voiceHelpMessage)
        }
    }

    // MARK: - Sections

    private var newWordsSection: some View {
        Section(L10n.Settings.newWordsSessionSection) {
            Stepper(value: $newWordsPerSession, in: 1...50, step: 1) {
                HStack {
                    Text(L10n.Settings.wordsPerSession)
                    Spacer()
                    Text("\(newWordsPerSession)")
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(L10n.Settings.firstReviewTomorrow, isOn: $firstReviewTomorrow)

            Text(firstReviewTomorrow
                 ? L10n.Settings.firstReviewTomorrowOnHint
                 : L10n.Settings.firstReviewTomorrowOffHint)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private var speechSection: some View {
        Section(L10n.Settings.speechSection) {
            speedSlider
            voicePicker
            testRow
            Text(L10n.Settings.speechHint)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Subviews

    private var speedSlider: some View {
        Slider(
            value: speechRateBinding,
            in: minRate...defaultRate,
            step: rateStep
        ) {
            Text(L10n.Settings.speechSpeed)
        } minimumValueLabel: {
            Text(L10n.Settings.speechSlow)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } maximumValueLabel: {
            Text(L10n.Settings.speechFast)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var voicePicker: some View {
        Picker(L10n.Settings.speechVoice, selection: voiceSelectionBinding) {
            Text(L10n.Settings.speechVoiceAuto).tag("auto")
            ForEach(voices, id: \.identifier) { v in
                Text("\(v.name) (\(v.language))").tag(v.identifier)
            }
        }
    }

    private var testRow: some View {
        HStack(spacing: 12) {
            Button(L10n.Settings.speechTest) {
                speech.speakKorean("안녕하세요. 반갑습니다.")
            }
            .buttonStyle(.bordered)

            Button {
                isVoiceHelpPresented = true
            } label: {
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(.secondary)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Settings.voiceHelpAccessibilityLabel)

            Spacer()
        }
        .padding(.vertical, 2)
    }

    // MARK: - Bindings

    private var speechRateBinding: Binding<Double> {
        Binding(
            get: { clampRate(ttsSpeechRate) },
            set: { ttsSpeechRate = clampRate($0) }
        )
    }

    private var voiceSelectionBinding: Binding<String> {
        Binding(
            get: { selectedVoiceId ?? "auto" },
            set: { newValue in
                if newValue == "auto" {
                    selectedVoiceId = nil
                    speech.setVoiceIdentifier(nil)
                } else {
                    selectedVoiceId = newValue
                    speech.setVoiceIdentifier(newValue)
                }
            }
        )
    }

    // MARK: - Helpers

    private var defaultRate: Double { Double(AVSpeechUtteranceDefaultSpeechRate) }
    private var minRate: Double { Double(AVSpeechUtteranceMinimumSpeechRate) }

    private var rateStep: Double {
        let range = defaultRate - minRate
        return max(0.005, range / 20.0)
    }

    private func clampRate(_ rate: Double) -> Double {
        min(defaultRate, max(minRate, rate))
    }

    private func loadVoices() {
        voices = speech.availableKoreanVoices()
        selectedVoiceId = speech.currentVoiceIdentifier()
    }
}

#Preview {
    NavigationStack { SettingsView(container: AppContainer()) }
}
