//
//  Microphone.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import SwiftUI
import AVFoundation
import OpenAI

struct Microphone: View {
    @State private var recognizedText = "Hold the button and start speaking..."
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioFileURL: URL?
    @State private var isLoading = false

    let openAI = OpenAI(apiToken: getChatGPTKey() ?? "")

    var body: some View {
        VStack {
            // Display the recognized text
            ScrollView {
                Text(recognizedText)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 100)
            .padding()

            // Recording button
            Button(action: {}) { // Empty action as long-press gesture handles recording
                Text(isRecording ? "Release to Stop" : "Hold to Speak")
                    .padding()
                    .background(isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .onLongPressGesture(minimumDuration: .infinity, pressing: { isPressing in
                if isPressing {
                    startRecording()
                } else {
                    stopRecording()
                }
            }, perform: {})
        }
        .padding()
        .onAppear {
            setupAudioSession()
        }
    }

    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            recognizedText = "Audio session setup failed: \(error.localizedDescription)"
        }
    }

    private func startRecording() {
        isRecording = true
        recognizedText = "Listening..."
        WKInterfaceDevice.current().play(.start)

        let tempDir = FileManager.default.temporaryDirectory
        let audioFileName = UUID().uuidString + ".m4a"
        let audioFilePath = tempDir.appendingPathComponent(audioFileName)
        audioFileURL = audioFilePath

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilePath, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
        } catch {
            recognizedText = "Recording failed: \(error.localizedDescription)"
            isRecording = false
        }
    }

    private func stopRecording() {
        isRecording = false
        WKInterfaceDevice.current().play(.stop)
        recognizedText = "Processing..."
        isLoading = true // Show loading indicator

        audioRecorder?.stop()
        guard let audioFileURL = audioFileURL else { return }

        Task {
            do {
                let transcription = try await transcribeAudio(audioFileURL: audioFileURL)
                DispatchQueue.main.async {
                    recognizedText = transcription
                    isLoading = false // Hide loading indicator
                }
                // Clean up audio file
                try FileManager.default.removeItem(at: audioFileURL)
            } catch {
                DispatchQueue.main.async {
                    recognizedText = "Error: \(error.localizedDescription)"
                    isLoading = false // Hide loading indicator
                }
            }
        }
    }

    private func transcribeAudio(audioFileURL: URL) async throws -> String {
        // Step 1: Load audio data from file
        let data = try Data(contentsOf: audioFileURL)

        // Step 2: Derive file type from file extension
        let fileExtension = audioFileURL.pathExtension.lowercased()
        let fileType: AudioTranscriptionQuery.FileType

        switch fileExtension {
        case "m4a":
            fileType = .m4a
        case "mp3":
            fileType = .mp3
        case "wav":
            fileType = .wav
        default:
            throw URLError(.unsupportedURL) // Handle unsupported file types
        }

        // Step 3: Create query for transcription
        let query = AudioTranscriptionQuery(
            file: data,
            fileType: fileType, // Use the derived file type
            model: .whisper_1 // Specify the model
        )

        // Step 4: Call OpenAI's audio transcription API
        let result = try await openAI.audioTranscriptions(query: query)

        // Step 5: Return transcribed text
        return result.text
    }

}


func getChatGPTKey() -> String? {
    if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
       let config = NSDictionary(contentsOfFile: path),
       let apiKey = config["ChatGPT"] as? String {
        return apiKey
    }
    return nil
}

#Preview {
    Microphone()
}

