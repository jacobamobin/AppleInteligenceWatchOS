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

// MARK: The main handler for all the views
struct ContentView: View {
    // assistantName || What the LLM refers to itself as
    // selectedVoice || The voice OpenAI's Whisper API uses, default is .alloy
    // state || Boolean that decides bettween home screen (false) and response screen (True)
    // recognizedText || Holds the text that OpenAI Transcribes from the microphone
    // tts || An instance of the TTS Handler
    // displayText || The response from Perplexity
    // rewriteTect || A Modified response from Perplexity that works best with TTS Models
    // isPressed || A boolean to tell if the user is tapping the screen
    @State private var assistantName: String = UserDefaults.standard.string(forKey: "AssistantName") ?? "Jarvis"
    @State private var selectedVoice: String = UserDefaults.standard.string(forKey: "SelectedVoice") ?? ".alloy"
    @State private var state = false
    @State private var recognizedText = ""
    @State private var tts = TTS()
    @State private var displayText = ""
    @State private var rewriteText = ""
    @State private var isPressed = false

    var body: some View {
        ZStack {
            if !state { // If Home screen State
                VStack {
                    Button { } label: {
                        ZStack {
                            if isPressed {
                                AssistantIcon()
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                GlowEffect(freeze: false)
                            } else {
                                Clock()
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                GlowEffect(freeze: true)
                            }
                            
                        }
                    }
                    .foregroundStyle(Color.clear)
                    .onLongPressGesture(minimumDuration: 0.1, pressing: { isPressing in
                        if isPressing {
                            Microphone.startRecording()
                            isPressed = true
                        } else {
                            Microphone.stopRecording { text in
                                recognizedText = text // Capture transcribed text
                                withAnimation { // Smooth transition to Result view
                                    state = true // Transition to Result view
                                    isPressed = false
                                }
                                // Fetch displayText after recording stops
                                displayText = RemoveCitations(prompt: sendRequest(userPrompt: recognizedText))
                            }
                        }
                    }, perform: {})
                }
                .transition(.opacity)
            } else { // If Response Screen state
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
                    .foregroundStyle(Color.clear)
                    .padding()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: state)
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
