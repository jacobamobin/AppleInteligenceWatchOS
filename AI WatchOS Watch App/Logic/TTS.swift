//
//  TTS.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-07.
//

import SwiftUI
import AVFoundation
import OpenAI

// MARK: - Enhanced TTS Class with Streaming Support
class TTS: NSObject, ObservableObject {
    static let shared = TTS()
    @Published var isPlaying = false
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var generationProgress: Double = 0.0

    private var audioPlayer: AVAudioPlayer?
    private var audioQueue: [Data] = []
    private var sentenceQueue: [String] = []
    private var processedSentences: Set<String> = []
    private var isProcessingQueue = false
    private var isProcessingSentences = false
    private let openAI = OpenAI(apiToken: getChatGPTKey() ?? "")
    
    override init() {
        super.init()
        setupStreamingObserver()
    }
    
    // MARK: - Setup streaming sentence observer
    private func setupStreamingObserver() {
        NotificationCenter.default.addObserver(
            forName: .streamingSentence,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let sentence = notification.object as? String else { return }
            let voice = UserDefaults.standard.string(forKey: "VoiceSelection") ?? ".alloy"
            self?.addSentenceToQueue(sentence, voice: voice)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Enhanced audio generation with streaming and caching
    public func generateAndPlayAudio(from text: String, voice: String) {
        // Fetch the volume from AppSettings
        let volumePercentage = AppSettings.shared.volume
        
        // If volume is zero, do not proceed
        if volumePercentage == 0 {
            isPlaying = false
            return
        }

        // Stop any current playback
        stopPlayback()
        
        isGenerating = true
        isPlaying = true
        errorMessage = nil
        generationProgress = 0.0

        // Set up the audio session for optimal performance
        setupAudioSession()

        // Create query for audio generation with optimized settings
        let selectedVoice = mapVoiceToEnum(voice: voice)
        
        // Process text in chunks for faster streaming if text is long
        let chunks = splitTextIntoChunks(text: text, maxLength: 500)
        
        Task {
            await generateAudioChunks(chunks: chunks, voice: selectedVoice, volumePercentage: volumePercentage)
        }
    }
    
    // MARK: - Split text into manageable chunks for streaming
    private func splitTextIntoChunks(text: String, maxLength: Int) -> [String] {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanText.count <= maxLength {
            return [cleanText]
        }
        
        var chunks: [String] = []
        let sentences = cleanText.components(separatedBy: ". ")
        var currentChunk = ""
        
        for sentence in sentences {
            if currentChunk.count + sentence.count + 2 <= maxLength {
                currentChunk += sentence + ". "
            } else {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk.trimmingCharacters(in: .whitespaces))
                }
                currentChunk = sentence + ". "
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk.trimmingCharacters(in: .whitespaces))
        }
        
        return chunks.isEmpty ? [cleanText] : chunks
    }
    
    // MARK: - Generate audio chunks with streaming playback
    private func generateAudioChunks(chunks: [String], voice: AudioSpeechQuery.AudioSpeechVoice, volumePercentage: Double) async {
        let totalChunks = chunks.count
        
        for (index, chunk) in chunks.enumerated() {
            do {
                let query = AudioSpeechQuery(
                    model: .tts_1,
                    input: String(chunk.prefix(1000)), // Limit to 1000 characters
                    voice: voice,
                    responseFormat: .mp3,
                    speed: 1.15
                )
                
                let result = try await openAI.audioCreateSpeech(query: query)
                
                // Update progress
                await MainActor.run {
                    self.generationProgress = Double(index + 1) / Double(totalChunks)
                }
                
                // Add to queue for sequential playback
                audioQueue.append(result.audio)
                
                // Start playing the first chunk immediately
                if index == 0 {
                    await playNextInQueue(volumePercentage: volumePercentage)
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Audio generation failed: \(error.localizedDescription)"
                    self.isGenerating = false
                    self.isPlaying = false
                }
                return
            }
        }
        
        await MainActor.run {
            self.isGenerating = false
        }
    }
    
    // MARK: - Play audio queue sequentially
    private func playNextInQueue(volumePercentage: Double) async {
        guard !audioQueue.isEmpty && !isProcessingQueue else { return }
        
        isProcessingQueue = true
        let audioData = audioQueue.removeFirst()
        
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.volume = Float(volumePercentage / 100.0)
            audioPlayer?.prepareToPlay()
            
            // Set up completion handler for seamless playback
            audioPlayer?.delegate = self
            audioPlayer?.play()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Playback failed: \(error.localizedDescription)"
                self.isPlaying = false
            }
        }
        
        isProcessingQueue = false
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
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .allowBluetooth, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - Add sentence to streaming queue (with request cancellation)
    func addSentenceToQueue(_ sentence: String, voice: String) {
        let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Be more lenient with sentence acceptance
        guard !trimmedSentence.isEmpty && trimmedSentence.count > 5 else { return }
        
        // Prevent duplicate sentences
        if processedSentences.contains(trimmedSentence) {
            return
        }
        
        print("Adding sentence to TTS queue: '\(trimmedSentence)'") // Debug
        
        processedSentences.insert(trimmedSentence)
        sentenceQueue.append(trimmedSentence)
        
        // Immediately start processing if not already processing
        if !isProcessingSentences {
            processSentenceQueue(voice: voice)
        }
    }
    
    // MARK: - Clear all TTS for new request
    func clearAllTTS() {
        stopPlayback()
        sentenceQueue.removeAll()
        processedSentences.removeAll()
        isProcessingSentences = false
        print("Cleared all TTS for new request")
    }
    
    // MARK: - Process sentence queue for streaming TTS (improved continuity)
    private func processSentenceQueue(voice: String) {
        guard !sentenceQueue.isEmpty && !isProcessingSentences else { return }
        
        isProcessingSentences = true
        let sentence = sentenceQueue.removeFirst()
        
        print("Processing TTS for: '\(sentence)'") // Debug
        
        Task {
            do {
                let selectedVoice = mapVoiceToEnum(voice: voice)
                let query = AudioSpeechQuery(
                    model: .tts_1_hd, // Use HD model for better quality
                    input: String(sentence.prefix(500)), // Limit sentence length
                    voice: selectedVoice,
                    responseFormat: .mp3,
                    speed: 1.2 // Slightly faster for responsiveness
                )
                
                let result = try await openAI.audioCreateSpeech(query: query)
                
                // Add to audio queue
                audioQueue.append(result.audio)
                
                // Start playing if not already playing
                if !isPlaying {
                    await MainActor.run {
                        self.isPlaying = true
                    }
                    await playNextInQueue(volumePercentage: AppSettings.shared.volume)
                }
                
                // CRITICAL: Always continue processing the queue
                await MainActor.run {
                    self.isProcessingSentences = false
                }
                
                // Process next sentence immediately
                if !sentenceQueue.isEmpty {
                    processSentenceQueue(voice: voice)
                }
                
            } catch {
                print("Error generating TTS for sentence: \(error)")
                await MainActor.run {
                    self.isProcessingSentences = false
                }
                
                // Even on error, continue with next sentence
                if !sentenceQueue.isEmpty {
                    processSentenceQueue(voice: voice)
                }
            }
        }
    }
    
    // MARK: - Enhanced stop playback with queue clearing
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        audioQueue.removeAll()
        sentenceQueue.removeAll()
        processedSentences.removeAll()
        isProcessingQueue = false
        isProcessingSentences = false
        
        DispatchQueue.main.async {
            self.isPlaying = false
            self.isGenerating = false
            self.generationProgress = 0.0
        }
    }
    
    // MARK: - Clear processed sentences for new conversation
    func clearProcessedSentences() {
        processedSentences.removeAll()
    }
    
    // MARK: - Quick TTS for short responses (< 100 characters)
    func quickTTS(text: String, voice: String, volumePercentage: Double) {
        guard text.count < 100 else {
            generateAndPlayAudio(from: text, voice: voice)
            return
        }
        
        let selectedVoice = mapVoiceToEnum(voice: voice)
                 let query = AudioSpeechQuery(
             model: .tts_1,
             input: String(text.prefix(1000)), // Limit to 1000 characters
             voice: selectedVoice,
             responseFormat: .mp3,
             speed: 1.15
         )
        
        Task {
            do {
                let result = try await openAI.audioCreateSpeech(query: query)
                
                await MainActor.run {
                    self.isPlaying = true
                }
                
                try await playAudio(data: result.audio, volumePercentage: volumePercentage)
                
                await MainActor.run {
                    self.isPlaying = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isPlaying = false
                }
            }
        }
    }

    private func playAudio(data: Data, volumePercentage: Double) async throws {
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.volume = Float(volumePercentage / 100.0)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
        
        // Wait for completion
        while audioPlayer?.isPlaying == true {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
    }
}

// MARK: - AVAudioPlayerDelegate for seamless queue playback
extension TTS: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Only process next if playback was successful
        if flag && !audioQueue.isEmpty {
            Task {
                await playNextInQueue(volumePercentage: AppSettings.shared.volume)
            }
        } else if audioQueue.isEmpty {
            DispatchQueue.main.async {
                self.isPlaying = false
            }
        } else {
            // If playback failed but there are more items, try the next one
            Task {
                await playNextInQueue(volumePercentage: AppSettings.shared.volume)
            }
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
        // Try to continue with next item in queue if available
        if !audioQueue.isEmpty {
            Task {
                await playNextInQueue(volumePercentage: AppSettings.shared.volume)
            }
        } else {
            DispatchQueue.main.async {
                self.errorMessage = error?.localizedDescription ?? "Audio decode error"
                self.isPlaying = false
            }
        }
    }
}
