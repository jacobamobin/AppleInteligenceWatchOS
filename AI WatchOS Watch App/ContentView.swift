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
import WatchKit

// MARK: The main handler for all the views
struct ContentView: View {
    // assistantName || What the LLM refers to itself as
    // selectedVoice || The voice OpenAI's Whisper API uses, default is .alloy
    // state || Boolean that decides between home screen (false) and response screen (True)
    // recognizedText || Holds the text that OpenAI Transcribes from the microphone
    // tts || An instance of the TTS Handler
    // displayText || The response from Perplexity
    // rewriteText || A Modified response from Perplexity that works best with TTS Models
    // isPressed || A boolean to tell if the user is tapping the screen
    // reactivateMic || Boolean that controls jumping from response
    @State private var assistantName: String = UserDefaults.standard.string(forKey: "AssistantName") ?? "Jarvis"
    @State private var selectedVoice: String = UserDefaults.standard.string(forKey: "SelectedVoice") ?? ".alloy"
    @State private var state = true
    @State private var recognizedText = ""
    @State private var tts = TTS()
    @State private var displayText = ""
    @State private var rewriteText = ""
    @State private var isPressed = false
    @State private var reactivateMic = false
    @State private var isThinking = false // State to track "thinking" animation

    var body: some View {
        ZStack {
            if !state { // If Home screen State
                VStack {
                    Button { } label: {
                        ZStack {
                            if isPressed {
                                AssistantIcon()
                                    .transition(.move(edge: .bottom).combined(with: .opacity)) // Assistant icon moves out
                                GlowEffect(freeze: false)
                            } else if isThinking {
                                ThinkingIcon()
                                    .transition(.move(edge: .bottom).combined(with: .opacity)) // Thinking icon moves in
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
                            tts.stopPlayback()
                            WKInterfaceDevice.current().play(.success)
                            Microphone.startRecording()
                            isPressed = true
                        } else {
                            withAnimation {
                                // Transition to thinking state when the button is released
                                WKInterfaceDevice.current().play(.success)
                                isThinking = true // Show thinking animation
                                isPressed = false // Hide assistant animation
                            }

                            Microphone.stopRecording { text in
                                recognizedText = text // Capture transcribed text

                                displayText = sendRequest(userPrompt: recognizedText) // Fetch result
                                WKInterfaceDevice.current().play(.success)

                                withAnimation {
                                    state = true // Transition to Result view
                                    WKInterfaceDevice.current().play(.success)
                                }
                                isThinking = false // Hide thinking animation after processing

                            }
                        }
                    }, perform: {})
                }
                .transition(.opacity)
            } else { // If Response Screen state
                VStack {
                    NavigationView {
                        VStack(spacing: 0) {
                            TopBar()
                                .padding(.top, -30)
                                .frame(height: 40)

                            // ScrollView with gestures attached
                            ScrollView {
                                Text(displayText + "\n\n\n")
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(Color.white)
                                    .padding(.top, 15)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(
                                width: WKInterfaceDevice.current().screenBounds.width,
                                height: WKInterfaceDevice.current().screenBounds.height - 75 // Adjusted height to account for TopBar
                            )
                            .onTapGesture {
                                withAnimation {
                                    state = false
                                }
                            }
                            .onLongPressGesture(minimumDuration: 0.1, pressing: { isPressing in
                                if isPressing {
                                    tts.stopPlayback()
                                    WKInterfaceDevice.current().play(.success)
                                    Microphone.startRecording()
                                    isThinking = false // Ensure thinking animation is off while recording
                                } else {
                                    withAnimation {
                                        isThinking = true // Show thinking animation
                                    }
                                    Microphone.stopRecording { text in
                                        recognizedText = text // Capture transcribed text

                                        displayText = sendRequest(userPrompt: recognizedText) // Fetch result
                                        WKInterfaceDevice.current().play(.success)
                                        isThinking = false // Hide thinking animation after processing
                                    }
                                }
                            }, perform: {})
                        }
                    }
                    .frame(
                        width: WKInterfaceDevice.current().screenBounds.width,
                        height: WKInterfaceDevice.current().screenBounds.height
                    )
                }
                // Show progress indicator when isThinking is true
                .overlay(
                    Group {
                        if isThinking {
                            ZStack {
                                Color.black.opacity(0.5)
                                    .edgesIgnoringSafeArea(.all)
                                ProgressView("Thinking...")
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .foregroundColor(.white)
                            }
                        }
                    }
                )
            }
        }
        .animation(.smooth(duration: 0.2), value: state)
        .onAppear {
            // Ensure selected voice is updated when the view appears
            selectedVoice = UserDefaults.standard.string(forKey: "SelectedVoice") ?? ".alloy"
        }
        .onChange(of: reactivateMic) { newValue in
            // Reactivate the microphone if necessary after long press
            if newValue {
                Microphone.startRecording()
                WKInterfaceDevice.current().play(.click)
                reactivateMic = false // Reset the flag after activation
            }
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
