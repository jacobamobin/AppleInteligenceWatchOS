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
// TODO: Fix reactivate Mic
struct ContentView: View {
    // assistantName || What the LLM refers to itself as
    // selectedVoice || The voice OpenAI's Whisper API uses, default is .alloy
    // state || Boolean that decides between home screen (false) and response screen (True)
    // recognizedText || Holds the text that OpenAI Transcribes from the microphone
    // tts || An instance of the TTS Handler
    // displayText || The response from Perplexity
    // isPressed || A boolean to tell if the user is tapping the screen
    // reactivateMic || Boolean that controls jumping from response
    @State private var assistantName: String = UserDefaults.standard.string(forKey: "AssistantName") ?? "Jarvis"
    @State private var selectedVoice: String = UserDefaults.standard.string(forKey: "SelectedVoice") ?? ".alloy"
    @State private var state = false
    @State private var recognizedText = ""
    @State private var tts = TTS()
    @State private var displayText = ""
    @State private var isPressed = false
    @State private var reactivateMic = false
    @State private var isThinking = false // New state to track "thinking" animation

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
                            Microphone.startRecording()
                            isPressed = true
                        } else {
                            withAnimation {
                                isThinking = true // Show thinking animation
                                isPressed = false // Hide assistant animation
                            }
                            
                            Microphone.stopRecording { text in
                                recognizedText = text // Capture transcribed text
                                displayText = "" // Clear previous response
                                tts.stopPlayback() // Stop any ongoing TTS and clear buffers
                                
                                sendRequest(userPrompt: recognizedText, onDataReceived: { chunk in
                                    DispatchQueue.main.async {
                                        // Remove citations from display text
                                        let cleanChunk = chunk.replacingOccurrences(of: "\\[\\d+\\]", with: "", options: .regularExpression)
                                        displayText += cleanChunk
                                        tts.addTextChunk(chunk, voice: selectedVoice) // TTS handles citation removal internally
                                    }
                                }, onCompletion: { error in
                                    DispatchQueue.main.async {
                                        if let error = error {
                                            displayText = "Error: \(error.localizedDescription)"
                                        } else {
                                            // Additional cleanup for any remaining citations in display
                                            displayText = displayText.replacingOccurrences(of: "\\[\\d+\\]", with: "", options: .regularExpression)
                                            tts.finishText() // Process any remaining text in buffer
                                        }
                                        isThinking = false // Hide thinking animation after processing
                                    }
                                })
                                
                                withAnimation {
                                    state = true // Transition to Result view
                                }
                            }
                        }
                    }, perform: {})
                }
                .transition(.opacity)
            } else { // If Response Screen state
                VStack {
                    NavigationView {
                        VStack {
                            TopBar()
                                .padding(.bottom, 110)
                                .padding(.trailing, 10)
                                .padding(.top, 10)
                                .frame(height: 50)
                            Button {
                                withAnimation {
                                    state = false
                                }
                            } label: {
                                // ScrollView with long press gesture
                                ScrollView {
                                    Text(displayText + "\n \n \n")
                                        .multilineTextAlignment(.leading)
                                        .foregroundStyle(Color.white)
                                }.frame(
                                    width: WKInterfaceDevice.current().screenBounds.width,
                                    height: WKInterfaceDevice.current().screenBounds.height-25
                                )
                            }
                            .foregroundStyle(Color.clear)
                            .onLongPressGesture {
                                withAnimation {
                                    tts.stopPlayback()
                                    reactivateMic = true
                                    state = false // Transition to Home screen
                                }
                            }
                        }
                    }
                    .frame(
                        width: WKInterfaceDevice.current().screenBounds.width,
                        height: WKInterfaceDevice.current().screenBounds.width
                    )
                }
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
                reactivateMic = false // Reset the flag after activation
            }
        }
    }
}

#Preview {
    ContentView()
}
