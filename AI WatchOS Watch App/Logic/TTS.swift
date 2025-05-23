//
//  TTS.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-07.
//

import SwiftUI
import AVFoundation
import OpenAI

// MARK: - TTS Class
class TTS: ObservableObject {
    @Published var isPlaying = false
    @Published var errorMessage: String?

    private var audioPlayer: AVAudioPlayer?
    private let openAI = OpenAI(apiToken: getChatGPTKey() ?? "")
    
    public func generateAndPlayAudio(from text: String, voice: String) {
        // Fetch the volume from AppSettings
        let volumePercentage = AppSettings.shared.volume
        
        // If volume is zero, do not proceed
        if volumePercentage == 0 {
            isPlaying = false
            return
        }

        isPlaying = true
        errorMessage = nil

        // Set up the audio session
        setupAudioSession()

        // Create query for audio generation
        let selectedVoice = mapVoiceToEnum(voice: voice)

        let query = AudioSpeechQuery(
            model: .tts_1,
            input: String(text.prefix(2000)),
            voice: selectedVoice,
            responseFormat: .mp3,
            speed: 1.15
        )

        Task {
            do {
                // Generate audio using OpenAI's API
                let result = try await openAI.audioCreateSpeech(query: query)

                // Play audio data
                try playAudio(data: result.audio, volumePercentage: volumePercentage)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
            DispatchQueue.main.async {
                self.isPlaying = false
            }
        }
    }

    // Helper method to map the voice string to the correct enum value
    private func mapVoiceToEnum(voice: String) -> AudioSpeechQuery.AudioSpeechVoice {
        switch voice {
        case ".alloy":
            return .alloy
        case ".echo":
            return .echo
        case ".fable":
            return .fable
        case ".onyx":
            return .onyx
        case ".nova":
            return .nova
        case ".shimmer":
            return .shimmer
        default:
            return .alloy // Default voice if no match is found
        }
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    private func playAudio(data: Data, volumePercentage: Double) throws {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.volume = Float(volumePercentage / 100.0)  // Set the player volume (0.0 to 1.0)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to initialize AVAudioPlayer: \(error)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
