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
class TTS: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var errorMessage: String?

    private var audioPlayer: AVAudioPlayer?
    private let openAI = OpenAI(apiToken: getChatGPTKey() ?? "")
    private var audioQueue: [(index: Int, data: Data)] = [] // Queue with ordering
    private var currentVoice: String = ".alloy"
    private var textBuffer: String = "" // Buffer for incoming text chunks
    private var sentenceIndex = 0 // Track sentence order
    private var nextPlayIndex = 0 // Track which sentence should play next
    private var hasSpokenFirst = false // Track if we've spoken the first sentence
    private var accumulatedText = "" // Accumulate text for later chunks
    
    public func addTextChunk(_ chunk: String, voice: String) {
        self.currentVoice = voice
        
        // Remove citations from the chunk before processing
        let cleanChunk = removeCitations(chunk)
        textBuffer += cleanChunk
        accumulatedText += cleanChunk
        
        // Check for complete sentences
        processBufferForSentences()
    }
    
    public func finishText() {
        // Process any remaining text in buffer when stream is complete
        if !textBuffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let finalText = rewriteForTTS(prompt: textBuffer)
            if !finalText.isEmpty {
                generateAudioForText(finalText, index: sentenceIndex)
                sentenceIndex += 1
            }
            textBuffer = ""
        }
        
        // Also process any accumulated text that wasn't sent yet
        if !hasSpokenFirst && !accumulatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let processedText = rewriteForTTS(prompt: accumulatedText)
            if !processedText.isEmpty {
                generateAudioForText(processedText, index: sentenceIndex)
                sentenceIndex += 1
            }
        }
    }
    
    private func processBufferForSentences() {
        let sentenceEnders = CharacterSet(charactersIn: ".!?")
        let sentences = textBuffer.components(separatedBy: sentenceEnders)
        
        // If we have more than one component, we have at least one complete sentence
        if sentences.count > 1 {
            if !hasSpokenFirst {
                // Speak the first sentence immediately for fast response
                let firstSentence = sentences[0].trimmingCharacters(in: .whitespacesAndNewlines)
                if !firstSentence.isEmpty {
                    let processedText = rewriteForTTS(prompt: firstSentence)
                    if !processedText.isEmpty {
                        generateAudioForText(processedText, index: sentenceIndex)
                        sentenceIndex += 1
                        hasSpokenFirst = true
                    }
                }
                
                // Keep remaining text for batching
                let remainingText = sentences.dropFirst().joined(separator: ". ")
                textBuffer = remainingText
            } else {
                // For subsequent sentences, batch them together for better flow
                let completeSentences = sentences.dropLast().joined(separator: ". ")
                if !completeSentences.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let processedText = rewriteForTTS(prompt: completeSentences)
                    if !processedText.isEmpty {
                        generateAudioForText(processedText, index: sentenceIndex)
                        sentenceIndex += 1
                    }
                }
                
                // Keep the last incomplete sentence in the buffer
                textBuffer = sentences.last ?? ""
            }
        }
    }
    
    private func removeCitations(_ text: String) -> String {
        // Remove citations like [1], [2], [3][4], etc.
        let regexPattern = "\\[\\d+\\]"
        return text.replacingOccurrences(of: regexPattern, with: "", options: .regularExpression)
    }
    
    private func generateAudioForText(_ text: String, index: Int) {
        guard !text.isEmpty else { return }
        
        // Fetch the volume from AppSettings
        let volumePercentage = AppSettings.shared.volume
        
        // If volume is zero, do not proceed
        if volumePercentage == 0 {
            return
        }

        // Create query for audio generation
        let selectedVoice = mapVoiceToEnum(voice: currentVoice)

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
                
                DispatchQueue.main.async {
                    self.addToQueue(audioData: result.audio, index: index)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    print("TTS Error: \(error)")
                }
            }
        }
    }
    
    private func addToQueue(audioData: Data, index: Int) {
        // Insert audio data in the correct position based on index
        audioQueue.append((index: index, data: audioData))
        audioQueue.sort { $0.index < $1.index }
        
        // Try to play if we're not already playing
        if !isPlaying {
            playNextInQueue()
        }
    }
    
    private func playNextInQueue() {
        // Look for the next sentence in sequence
        guard let nextItem = audioQueue.first(where: { $0.index == nextPlayIndex }) else {
            isPlaying = false
            return
        }
        
        // Remove the item from queue
        audioQueue.removeAll { $0.index == nextPlayIndex }
        nextPlayIndex += 1
        
        isPlaying = true
        
        // Set up the audio session
        setupAudioSession()
        
        // Fetch the volume from AppSettings
        let volumePercentage = AppSettings.shared.volume
        
        do {
            audioPlayer = try AVAudioPlayer(data: nextItem.data)
            audioPlayer?.delegate = self
            audioPlayer?.volume = Float(volumePercentage / 100.0)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to initialize AVAudioPlayer: \(error)")
            isPlaying = false
            playNextInQueue() // Try next item in queue
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playNextInQueue()
    }
    
    // Legacy method for compatibility with Settings
    public func speak(text: String, voice: String) {
        resetState()
        let cleanText = removeCitations(text)
        addTextChunk(cleanText, voice: voice)
        finishText()
    }
    
    private func resetState() {
        textBuffer = ""
        audioQueue.removeAll()
        sentenceIndex = 0
        nextPlayIndex = 0
        hasSpokenFirst = false
        accumulatedText = ""
    }
    
    private func rewriteForTTS(prompt: String) -> String {
        // Function to process the prompt for TTS-friendly output

        // Function to convert numbers to natural speech
        func numberToWords(_ number: String) -> String {
            guard let num = Int(number) else { return number }

            let units = ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
            let teens = ["", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
            let tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
            let thousands = ["", "thousand", "million", "billion"]

            func convertToWords(_ n: Int) -> String {
                if n == 0 { return "zero" }

                var n = n
                var result = ""
                var place = 0

                while n > 0 {
                    let chunk = n % 1000
                    if chunk > 0 {
                        let chunkText = convertChunk(chunk)
                        let placeText = thousands[place]
                        result = "\(chunkText) \(placeText) \(result)".trimmingCharacters(in: .whitespaces)
                    }
                    n /= 1000
                    place += 1
                }

                return result.trimmingCharacters(in: .whitespaces)
            }

            func convertChunk(_ n: Int) -> String {
                var n = n
                var result = ""

                if n >= 100 {
                    let hundredsPlace = n / 100
                    result += "\(units[hundredsPlace]) hundred "
                    n %= 100
                }

                if n >= 20 {
                    let tensPlace = n / 10
                    result += "\(tens[tensPlace]) "
                    n %= 10
                } else if n > 10 {
                    result += "\(teens[n - 10]) "
                    n = 0
                } else if n == 10 {
                    result += "ten "
                    n = 0
                }

                if n > 0 {
                    result += "\(units[n]) "
                }

                return result.trimmingCharacters(in: .whitespaces)
            }

            return convertToWords(num)
        }

        // Dictionary for common replacements
        let replacements: [String: String] = [
            "%": " percent",
            "°": " degree",
            "&": " and",
            "@": " at",
            "$": " dollars",
            "#": " number"
        ]

        // Regex patterns and corresponding transformations
        let patterns: [(pattern: String, transform: (String) -> String)] = [
            // Convert numbers to words
            ("\\b\\d+\\b", numberToWords),

            // Remove parentheses and brackets
            ("[\\(\\)\\[\\]]", { _ in "" })
        ]

        // Perform replacements
        var modifiedPrompt = prompt

        // Direct replacements
        for (key, value) in replacements {
            modifiedPrompt = modifiedPrompt.replacingOccurrences(of: key, with: value)
        }

        // Pattern-based transformations
        for (pattern, transform) in patterns {
            let regex = try! NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: modifiedPrompt, range: NSRange(modifiedPrompt.startIndex..., in: modifiedPrompt))
            for match in matches.reversed() {
                let matchRange = Range(match.range, in: modifiedPrompt)!
                let matchText = String(modifiedPrompt[matchRange])
                modifiedPrompt.replaceSubrange(matchRange, with: transform(matchText))
            }
        }

        // Return the refactored text
        return modifiedPrompt
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
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        resetState()
        isPlaying = false
    }
}
