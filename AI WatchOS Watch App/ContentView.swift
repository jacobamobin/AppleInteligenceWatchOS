//
//  ContentView.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import SwiftUI

struct ContentView: View {
    @State private var state = false // State to toggle between views
    @State private var recognizedText = "" // Holds the transcribed text from Microphone

    var body: some View {
        if !state {
            // Microphone view
            ZStack {
                Button { } label: {
                    GlowEffect()
                }
                .foregroundStyle(Color.clear)
                .onLongPressGesture(minimumDuration: 1.0, pressing: { isPressing in
                    if isPressing {
                        Microphone.startRecording()
                    } else {
                        Microphone.stopRecording { text in
                            recognizedText = text // Capture transcribed text
                            state = true // Transition to Result view
                        }
                    }
                }, perform: {})
            }
        } else {
            // Result view
            ScrollView {
                Text(sendRequest(userPrompt: recognizedText))
            }
            
        }
    }
}

#Preview {
    ContentView()
}


