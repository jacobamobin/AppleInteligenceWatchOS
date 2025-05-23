//
//  Microphone.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//
import Foundation
import AVFoundation
import OpenAI

// MARK: Microphone holds functions that take the users current input and send it to open AI's speech-to-text model
struct Microphone {
    static var audioRecorder: AVAudioRecorder?
    static var audioFileURL: URL?
    // For the OpenAI Swift Package
    static let openAI = OpenAI(apiToken: getChatGPTKey() ?? "")

    // Setup the initial audio setup
    static func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Audio session setup failed: \(error.localizedDescription)")
        }
    }

    // MARK: Function to start the recording
    static func startRecording() {
        setupAudioSession()
        // Save the audio file to a temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        let audioFileName = UUID().uuidString + ".m4a"
        let audioFilePath = tempDir.appendingPathComponent(audioFileName)
        audioFileURL = audioFilePath

        // Modify recording settings here
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        // Try to record the audio
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilePath, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
        } catch {
            print("Recording failed: \(error.localizedDescription)")
        }
    }

    // MARK: Function to stop the recording
    static func stopRecording(completion: @escaping (String) -> Void) {
        audioRecorder?.stop()
        guard let audioFileURL = audioFileURL else {
            completion("Error: No audio file found")
            return
        }

        Task {
            do {
                let transcription = try await transcribeAudio(audioFileURL: audioFileURL)
                DispatchQueue.main.async {
                    completion(transcription)
                }
                // Clean up audio file
                try FileManager.default.removeItem(at: audioFileURL)
            } catch {
                DispatchQueue.main.async {
                    completion("Error: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: This function sends the saved recording to Open AI to transcribe into text
    private static func transcribeAudio(audioFileURL: URL) async throws -> String {
        // This function uses the Open AI Package by Macpaw, for more documentation go see their repo
        let data = try Data(contentsOf: audioFileURL)

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
            throw URLError(.unsupportedURL)
        }

        let query = AudioTranscriptionQuery(
            file: data,
            fileType: fileType,
            model: .whisper_1
        )

        let result = try await openAI.audioTranscriptions(query: query)
        return result.text
    }
}

// Simple function to get the ChatGPT key from the Config.plist
public func getChatGPTKey() -> String? {
    if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
       let config = NSDictionary(contentsOfFile: path),
       let apiKey = config["ChatGPT"] as? String {
        return apiKey
    }
    return nil
}
