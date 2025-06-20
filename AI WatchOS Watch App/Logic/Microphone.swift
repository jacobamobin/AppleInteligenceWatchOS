//
//  Microphone.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//
import Foundation
import AVFoundation
import OpenAI
import CoreMotion

// MARK: Microphone holds functions that take the users current input and send it to open AI's speech-to-text model
class Microphone: ObservableObject {
    static let shared = Microphone()
    
    @Published var isRecording = false
    @Published var isRaisedToMouth = false
    @Published var isWristDown = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private var motionManager = CMMotionManager()
    private var silenceTimer: Timer?
    private var lastAudioLevel: Float = 0.0
    
    // For the OpenAI Swift Package
    private let openAI = OpenAI(apiToken: getChatGPTKey() ?? "")
    
    private init() {
        setupMotionDetection()
    }

    // MARK: Setup motion detection for raise-to-speak
    private func setupMotionDetection() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, let self = self else { return }
            
            // Detect watch raised to mouth (gravity pointing up, user acceleration minimal)
            let gravity = motion.gravity
            let userAccel = motion.userAcceleration
            
            // Watch is raised when gravity.y is high (wrist up) and relatively stable
            let isRaised = gravity.y > 0.6 && abs(userAccel.x) < 0.5 && abs(userAccel.y) < 0.5 && abs(userAccel.z) < 0.5
            
            // Removed wrist down detection - only use tap to navigate
            
            if isRaised && !self.isRaisedToMouth && !self.isRecording {
                // Just raised to mouth - start recording
                DispatchQueue.main.async {
                    self.isRaisedToMouth = true
                    self.isWristDown = false
                    self.startRecording(autoStop: true)
                    // Notify UI that raise-to-speak started
                    NotificationCenter.default.post(name: .raiseToSpeakStarted, object: nil)
                }
            } else if !isRaised && self.isRaisedToMouth && self.isRecording {
                // Lowered from mouth - stop recording
                DispatchQueue.main.async {
                    self.isRaisedToMouth = false
                    self.stopRecording { text in
                        // Notify UI with the transcribed text
                        NotificationCenter.default.post(name: .raiseToSpeakEnded, object: text)
                    }
                }
            }
            
            // Removed all wrist down navigation - only use tap to go back
        }
    }

    // Setup the initial audio setup
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Audio session setup failed: \(error.localizedDescription)")
        }
    }

    // MARK: Function to start the recording (with optional auto-stop)
    func startRecording(autoStop: Bool = false) {
        guard !isRecording else { return }
        
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
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            isRecording = true
            
            // Setup silence detection for auto-stop
            if autoStop {
                startSilenceDetection()
            }
        } catch {
            print("Recording failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: Silence detection for auto-stop
    private var silenceCount = 0
    
    private func startSilenceDetection() {
        silenceCount = 0
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            
            recorder.updateMeters()
            let currentLevel = recorder.averagePower(forChannel: 0)
            
            // Detect silence (adjust threshold as needed)
            if currentLevel < -40.0 { // Silence threshold
                self.silenceCount += 1
                // Wait for 5 seconds of silence (50 * 0.1 = 5 seconds) instead of 2 seconds
                if self.silenceCount >= 50 {
                    // Stop recording due to extended silence
                    DispatchQueue.main.async {
                        self.stopRecording { _ in }
                    }
                }
            } else {
                // Reset silence counter if we detect sound
                self.silenceCount = 0
            }
            
            self.lastAudioLevel = currentLevel
        }
    }

    // MARK: Function to stop the recording
    func stopRecording(completion: @escaping (String) -> Void) {
        guard isRecording else {
            completion("No recording in progress")
            return
        }
        
        isRecording = false
        silenceTimer?.invalidate()
        silenceTimer = nil
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
    private func transcribeAudio(audioFileURL: URL) async throws -> String {
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
            model: .whisper_1,
            language: "en" // Explicitly set English language
        )

        let result = try await openAI.audioTranscriptions(query: query)
        return result.text
    }
    
    // MARK: - Legacy static methods for compatibility
    static func startRecording() {
        shared.startRecording(autoStop: false)
    }
    
    static func stopRecording(completion: @escaping (String) -> Void) {
        shared.stopRecording(completion: completion)
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let raiseToSpeakStarted = Notification.Name("raiseToSpeakStarted")
    static let raiseToSpeakEnded = Notification.Name("raiseToSpeakEnded")
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
