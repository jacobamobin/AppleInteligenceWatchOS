//
//  TTS.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-07.
//

import SwiftUI
import AVFoundation
import OpenAI

struct TTS: View {
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var errorMessage: String?
    
    let openAI = OpenAI(apiToken: getChatGPTKeyB() ?? "")
    let demoSentence = "This is a demo sentence being converted to audio."

    var body: some View {
        VStack {
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button(action: {
                generateAndPlayAudio(from: demoSentence)
            }) {
                Text(isPlaying ? "Playing Audio..." : "Play Demo Sentence")
                    .padding()
                    .background(isPlaying ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }

    private func generateAndPlayAudio(from text: String) {
        isPlaying = true
        errorMessage = nil

        // Create query for audio generation
        let query = AudioSpeechQuery(
            model: .tts_1,
            input: text,
            voice: .alloy,
            responseFormat: .mp3, // Request mp3 format
            speed: 1.0
        )

        Task {
            do {
                // Generate audio using OpenAI's API
                let result = try await openAI.audioCreateSpeech(query: query)

                // Directly access audio data since it's non-optional
                try playAudio(data: result.audio)
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

    private func playAudio(data: Data) throws {
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    }
}

func getChatGPTKeyB() -> String? {
    if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
       let config = NSDictionary(contentsOfFile: path),
       let apiKey = config["ChatGPT"] as? String {
        return apiKey
    }
    return nil
}

#Preview {
    TTS()
}

