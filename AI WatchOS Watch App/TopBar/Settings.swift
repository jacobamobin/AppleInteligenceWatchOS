//
//  Settings.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import SwiftUI
import WatchKit

struct Settings: View {
    @State private var assistantName = UserDefaults.standard.string(forKey: "AssistantName") ?? "Jarvis"
    @State private var selectedVoice = UserDefaults.standard.string(forKey: "SelectedVoice") ?? ".alloy"
    @ObservedObject private var appSettings = AppSettings.shared
    @ObservedObject private var chatMemory = ChatMemory.shared
    @State private var showingClearConfirmation = false
    
    // Voice options
    let voices = [
        (".alloy", "Alloy"),
        (".echo", "Echo"),
        (".fable", "Fable"),
        (".onyx", "Onyx"),
        (".nova", "Nova"),
        (".shimmer", "Shimmer")
    ]

    var body: some View {
        NavigationView {
            List {
                // Assistant Configuration
                Section("Assistant") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Assistant Name", text: $assistantName)
                            .multilineTextAlignment(.trailing)
                            .onSubmit {
                                UserDefaults.standard.set(assistantName, forKey: "AssistantName")
                                WKInterfaceDevice.current().play(.click)
                            }
                    }
                }
                
                // Voice Configuration
                Section("Voice") {
                    Picker("Voice", selection: $selectedVoice) {
                        ForEach(voices, id: \.0) { voice in
                            Text(voice.1).tag(voice.0)
                        }
                    }
                    .pickerStyle(NavigationLinkPickerStyle())
                    .onChange(of: selectedVoice) { newVoice in
                        UserDefaults.standard.set(newVoice, forKey: "SelectedVoice")
                        WKInterfaceDevice.current().play(.click)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Volume")
                            Spacer()
                            Text("\(Int(appSettings.volume))%")
                                .foregroundColor(.gray)
                        }
                        Slider(value: $appSettings.volume, in: 0...100, step: 10)
                            .tint(.blue)
                    }
                }
                
                // Memory Management
                Section("Memory") {
                    HStack {
                        Text("Conversations")
                        Spacer()
                        Text("\(chatMemory.messages.count / 2)")
                            .foregroundColor(.gray)
                    }
                    
                    if !chatMemory.messages.isEmpty {
                        Button("Clear Memory") {
                            showingClearConfirmation = true
                        }
                        .foregroundColor(.red)
                    }
                    
                    Text("Keeps last 20 exchanges for context")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                // Performance Settings
                Section("Performance") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recording Limit")
                        Text("30 seconds maximum")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Response Limit")
                        Text("200 tokens maximum")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Streaming")
                        Text("Enabled for faster responses")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                // App Info
                Section("About") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enhanced AI Assistant")
                        Text("Streaming • Memory • Fast Response")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Clear Memory", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                chatMemory.clearMemory()
                WKInterfaceDevice.current().play(.click)
            }
        } message: {
            Text("This will delete all conversation history. This action cannot be undone.")
        }
    }
}

#Preview {
    Settings()
}
