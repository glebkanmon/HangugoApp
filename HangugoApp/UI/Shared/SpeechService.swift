// UI/Shared/SpeechService.swift

import Foundation
import AVFoundation
import Combine

@MainActor
final class SpeechService: ObservableObject {
    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()

    private let rateKey = "ttsSpeechRate"
    private let voiceIdKey = "ttsVoiceIdentifier" // optional saved voice identifier

    private init() {}

    func speakKorean(_ text: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: cleaned)

        // Voice
        utterance.voice = resolveKoreanVoice()

        // Rate (stored as Double)
        let defaultRate = AVSpeechUtteranceDefaultSpeechRate
        let initialRate = max(AVSpeechUtteranceMinimumSpeechRate, defaultRate / 1.5)

        let stored = UserDefaults.standard.double(forKey: rateKey) // 0 if unset
        let effective = (stored == 0) ? Double(initialRate) : stored

        let clamped = min(
            Double(defaultRate),
            max(Double(AVSpeechUtteranceMinimumSpeechRate), effective)
        )
        utterance.rate = Float(clamped)

        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }

    // MARK: - Voice selection

    /// Returns a voice identifier list for Settings UI.
    func availableKoreanVoices() -> [AVSpeechSynthesisVoice] {
        // Filter Korean voices (ko-*), prefer ko-KR ordering later.
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("ko") }

        // Stable ordering for UI: ko-KR first, then by name.
        return voices.sorted {
            if $0.language != $1.language {
                if $0.language == "ko-KR" { return true }
                if $1.language == "ko-KR" { return false }
                return $0.language < $1.language
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func currentVoiceIdentifier() -> String? {
        UserDefaults.standard.string(forKey: voiceIdKey)
    }

    func setVoiceIdentifier(_ id: String?) {
        if let id {
            UserDefaults.standard.set(id, forKey: voiceIdKey)
        } else {
            UserDefaults.standard.removeObject(forKey: voiceIdKey)
        }
    }

    private func resolveKoreanVoice() -> AVSpeechSynthesisVoice? {
        // 1) If user selected a specific voice, use it.
        if let savedId = UserDefaults.standard.string(forKey: voiceIdKey),
           let v = AVSpeechSynthesisVoice(identifier: savedId) {
            return v
        }

        // 2) Auto: pick the “best” available.
        let korean = availableKoreanVoices()
        if korean.isEmpty {
            return AVSpeechSynthesisVoice(language: "ko-KR")
        }

        // Heuristic:
        // - Prefer ko-KR
        // - Prefer voices that look like "Enhanced" / "Premium" in name (if present)
        // - Otherwise just first in sorted list
        let koKR = korean.filter { $0.language == "ko-KR" }
        let candidates = koKR.isEmpty ? korean : koKR

        if let enhanced = candidates.first(where: { nameLooksEnhanced($0.name) }) {
            return enhanced
        }

        // Sometimes male voices are clearer; we can't reliably detect gender in API.
        // So just return the first candidate.
        return candidates.first
    }

    private func nameLooksEnhanced(_ name: String) -> Bool {
        let n = name.lowercased()
        return n.contains("enhanced") || n.contains("premium")
    }
}
