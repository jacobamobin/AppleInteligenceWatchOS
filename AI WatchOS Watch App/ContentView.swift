//
//  ContentView.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import SwiftUI
import AVFoundation
import Foundation

struct ContentView: View {
    @State private var state = false // State to toggle between views
    @State private var recognizedText = "" // Holds the transcribed text from Microphone
    @State private var tts = TTS() // Instance of TTS

    var body: some View {
        ZStack {
            if !state {
                // Microphone view with smooth transition
                VStack {
                    Button { } label: {
                        GlowEffect() // Assuming GlowEffect is defined elsewhere
                    }
                    .foregroundStyle(Color.clear)
                    .onLongPressGesture(minimumDuration: 0.3, pressing: { isPressing in
                        if isPressing {
                            Microphone.startRecording() // Assuming Microphone is set up
                        } else {
                            Microphone.stopRecording { text in
                                recognizedText = text // Capture transcribed text
                                withAnimation { // Smooth transition to Result view
                                    state = true // Transition to Result view
                                }
                            }
                        }
                    }, perform: {})
                }
                .transition(.opacity) // Fade out effect
            } else {
                // Result view with smooth transition
                VStack {
                    Button {
                        withAnimation {
                            state = false
                        }
                    } label: {
                        ScrollView {
                            Text(sendRequest(userPrompt: recognizedText))
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(Color.white)
                        }
                        
                    }.foregroundStyle(Color.clear)
                }
                .ignoresSafeArea()
                .padding(.top, 5)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: state) // Apply animation to the state change
        .onChange(of: recognizedText) { newText in
            // Trigger TTS to play audio when recognizedText is updated
            if !newText.isEmpty {
                tts.generateAndPlayAudio(from: recognizedText)
            }
        }
    }
}

#Preview {
    ContentView()
}

