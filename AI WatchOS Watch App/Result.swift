//
//  Result.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import SwiftUI
import AVFoundation

struct Result: View {
    let speechSynthesizer = AVSpeechSynthesizer() // TTS Synthesizer
    
    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    func speakText() {
        let utterance = AVSpeechUtterance(string: "Hello, this is a test of Text-to-Speech in SwiftUI.")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        
        if !speechSynthesizer.isSpeaking {
            speechSynthesizer.speak(utterance)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Hello, World!")
                .font(.title)
                .padding()
            
            Button(action: {
                setupAudioSession() // Ensure the audio session is configured
                speakText()
            }) {
                Text("Speak")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

#Preview {
    Result()
}

