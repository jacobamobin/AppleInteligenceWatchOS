//
//  Result.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import SwiftUI
import AVFoundation

struct Result: View {
    @State private var isSpeaking = false
    @State private var errorMessage: String?

    func fetchSpeechFromGoogle(text: String, apiKey: String) {
        guard let url = URL(string: "https://texttospeech.googleapis.com/v1/text:synthesize?key=\(apiKey)") else {
            print("Invalid URL")
            return
        }

        let requestBody: [String: Any] = [
            "input": ["text": text],
            "voice": [
                "languageCode": "en-US",
                "name": "en-US-Wavenet-D"
            ],
            "audioConfig": [
                "audioEncoding": "MP3"
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to create JSON request body")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Request Error: \(error.localizedDescription)")
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let audioContent = json["audioContent"] as? String else {
                    print("Failed to parse JSON response")
                    return
                }

                guard let audioData = Data(base64Encoded: audioContent) else {
                    print("Failed to decode Base64 audioContent")
                    return
                }

                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("ttsAudio.mp3")
                do {
                    try audioData.write(to: fileURL)
                    print("Audio saved to: \(fileURL.path)")

                    let audioPlayer = try AVAudioPlayer(data: audioData)
                    audioPlayer.play()
                    print("Audio playback started")
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }



    func playAudio(base64String: String) {
        guard let audioData = Data(base64Encoded: base64String) else {
            errorMessage = "Invalid audio data"
            return
        }

        do {
            let audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer.play()
        } catch {
            errorMessage = "Failed to play audio: \(error.localizedDescription)"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Google TTS Integration")
                .font(.title)
                .padding()

            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }

            Button(action: {
                let sampleText = "Hello, this is a test of Google's Text-to-Speech API."
                let apiKey = "AIzaSyA5_icYUR-lBoa3gOZc6L6dWJ_Y1P_EYSw" // Replace with your actual API key
                fetchSpeechFromGoogle(text: sampleText, apiKey: apiKey)
            }) {
                Text(isSpeaking ? "Speaking..." : "Speak with Google TTS")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(isSpeaking ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(isSpeaking)
        }
        .padding()
    }
}

#Preview {
    Result()
}
