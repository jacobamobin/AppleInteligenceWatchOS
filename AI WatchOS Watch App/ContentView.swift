//
//  ContentView.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import SwiftUI
import AVFoundation
import Foundation
import OpenAI

struct ContentView: View {
    @State private var assistantName: String = UserDefaults.standard.string(forKey: "AssistantName") ?? "Jarvis"
    @State private var selectedVoice: String = UserDefaults.standard.string(forKey: "SelectedVoice") ?? ".alloy"
    @State private var state = false // State to toggle between views
    @State private var recognizedText = "" // Holds the transcribed text from Microphone
    @State private var tts = TTS() // Instance of TTS
    @State private var displayText = ""
    @State private var rewriteText = ""
    @State private var isPressed = false

    var body: some View {
        ZStack {
            if !state {
                // Microphone view with smooth transition
                VStack {
                    Button {
                        // Empty action for tap effect
                    } label: {
                        ZStack {
                            if isPressed {
                                AssistantIcon()
                                    .transition(.move(edge: .bottom).combined(with: .opacity)) // Animation for assistant icon
                            } else {
                                Clock()
                                    .transition(.move(edge: .top).combined(with: .opacity)) // Animation for clock
                            }
                            GlowEffect()
                        }
                    }
                    .foregroundStyle(Color.clear)
                    .onLongPressGesture(minimumDuration: 0.2, pressing: { isPressing in
                        if isPressing {
                            Microphone.startRecording() // Assuming Microphone is set
                            isPressed = true
                        } else {
                            Microphone.stopRecording { text in
                                recognizedText = text // Capture transcribed text
                                withAnimation { // Smooth transition to Result view
                                    state = true // Transition to Result view
                                    isPressed = false
                                }
                                // Fetch displayText after recording stops
                                displayText = sendRequest(userPrompt: recognizedText)
                            }
                        }
                    }, perform: {})
                }
                .transition(.opacity) // Fade out effect
            } else {
                VStack {
                    TopBar()
                    Button {
                        // Transition to clock screen when the ScrollView is tapped
                        withAnimation {
                            state = false
                        }
                    } label: {
                        ScrollView {
                            Text(displayText)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(Color.white)
                        }
                    }
                    .foregroundStyle(Color.clear) // Make sure the button's default style doesn't affect text
                    .padding()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: state) // Apply animation to the state change
        .onAppear {
            // Ensure selected voice is updated when the view appears
            selectedVoice = UserDefaults.standard.string(forKey: "SelectedVoice") ?? ".alloy"
        }
        .onChange(of: displayText) { newText in
            // Trigger TTS to play audio when `displayText` is updated
            if !newText.isEmpty {
                tts.generateAndPlayAudio(from: sendRewriteRequest(prompt: displayText), voice: selectedVoice)
            }
            print(displayText)
        }
    }
}

#Preview {
    ContentView()
}
