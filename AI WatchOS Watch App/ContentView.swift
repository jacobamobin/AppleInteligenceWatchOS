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
    @State private var assistantName: String = UserDefaults.standard.string(forKey: "AssistantName") ?? "Jarvis"
    @State private var selectedVoice: String = UserDefaults.standard.string(forKey: "SelectedVoice") ?? ".alloy"
    @State private var state = false
    @State private var recognizedText = ""
    @StateObject private var tts = TTS.shared
    @State private var displayText = ""
    @State private var rewriteText = ""
    @State private var isPressed = false
    @State private var reactivateMic = false
    @State private var isThinking = false
    
    // Enhanced components (hidden from UI)
    @StateObject private var microphone = Microphone.shared
    @StateObject private var apiManager = APIManager.shared
    @StateObject private var chatMemory = ChatMemory.shared
    
    // Streaming state
    @State private var isStreamingTTS = false

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
                            } else if isThinking {
                                ThinkingIcon()
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
                            tts.stopPlayback()
                            tts.clearProcessedSentences()
                            WKInterfaceDevice.current().play(.success)
                            microphone.startRecording(autoStop: false)
                            isPressed = true
                        } else {
                            withAnimation {
                                WKInterfaceDevice.current().play(.success)
                                isThinking = true
                                isPressed = false
                            }
                            
                            microphone.stopRecording { text in
                                recognizedText = text
                            
                                // Clear any existing TTS before starting new request
                                tts.clearAllTTS()
                                
                                // Use async streaming API for real-time response
                                Task {
                                    isStreamingTTS = true
                                    let response = await sendRequestAsync(userPrompt: recognizedText)
                                    
                                    await MainActor.run {
                                        displayText = response
                                        WKInterfaceDevice.current().play(.success)
                                        
                                        withAnimation {
                                            state = true
                                            WKInterfaceDevice.current().play(.success)
                                        }
                                        isThinking = false
                                        isStreamingTTS = false
                                    }
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
                                ScrollView {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(RemoveCitations(prompt: (apiManager.currentResponse.isEmpty ? displayText : apiManager.currentResponse)))
                                                .multilineTextAlignment(.leading)
                                                .foregroundStyle(Color.white)
                                                .font(.system(size: 14))
                                                .lineLimit(nil)
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.top, 4)
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
                                    state = false
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
            selectedVoice = UserDefaults.standard.string(forKey: "SelectedVoice") ?? ".alloy"
        }
        .onChange(of: reactivateMic) { newValue in
            if newValue {
                microphone.startRecording(autoStop: false)
                WKInterfaceDevice.current().play(.click)
                reactivateMic = false
            }
        }
        .onChange(of: displayText) { newText in
            // Only trigger TTS if we're not streaming and text wasn't set by streaming API
            if !newText.isEmpty && !isStreamingTTS && apiManager.currentResponse.isEmpty {
                tts.generateAndPlayAudio(from: sendRewriteRequest(prompt: displayText), voice: selectedVoice)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .streamingSentence)) { notification in
            if let sentence = notification.object as? String {
                // Remove citations and use sentence directly for faster TTS
                let cleanSentence = RemoveCitations(prompt: sentence)
                print("Received streaming sentence: '\(cleanSentence)'") // Debug
                tts.addSentenceToQueue(cleanSentence, voice: selectedVoice)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .raiseToSpeakStarted)) { _ in
            // Handle raise-to-speak started
            tts.stopPlayback()
            tts.clearProcessedSentences()
            WKInterfaceDevice.current().play(.success)
            withAnimation {
                isPressed = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .raiseToSpeakEnded)) { notification in
            // Handle raise-to-speak ended with transcribed text
            if let text = notification.object as? String {
                recognizedText = text
                
                withAnimation {
                    isThinking = true
                    isPressed = false
                }
                
                // Clear any existing TTS before starting new request
                tts.clearAllTTS()
                
                // Use async streaming API for real-time response
                Task {
                    isStreamingTTS = true
                    let response = await sendRequestAsync(userPrompt: recognizedText)
                    
                    await MainActor.run {
                        displayText = response
                        WKInterfaceDevice.current().play(.success)
                        
                        withAnimation {
                            state = true
                            WKInterfaceDevice.current().play(.success)
                        }
                        isThinking = false
                        isStreamingTTS = false
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillResignActiveNotification)) { _ in
            // Clean up when app goes to background
            microphone.stopRecording { _ in }
            tts.stopPlayback()
        }
    }
}




#Preview {
    ContentView()
}
