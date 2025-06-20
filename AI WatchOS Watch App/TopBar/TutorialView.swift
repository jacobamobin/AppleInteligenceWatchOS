//
//  TutorialView.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import SwiftUI
import WatchKit

// MARK: - Tutorial View for App Instructions
struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How to Use")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    // Instructions with icons
                    TutorialStep(
                        icon: "hand.point.up.fill",
                        title: "Start Recording",
                        description: "Hold down on the clock screen to start voice recording"
                    )
                    
                    TutorialStep(
                        icon: "mic.fill",
                        title: "Speak Clearly",
                        description: "Speak your question or command (30 seconds max)"
                    )
                    
                    TutorialStep(
                        icon: "hand.point.up.left.fill",
                        title: "Release to Send",
                        description: "Release your finger to stop recording and send"
                    )
                    
                    TutorialStep(
                        icon: "brain.head.profile",
                        title: "AI Processing",
                        description: "Watch the thinking animation while AI processes"
                    )
                    
                    TutorialStep(
                        icon: "text.bubble.fill",
                        title: "Read Response",
                        description: "Scroll through the AI response text"
                    )
                    
                    TutorialStep(
                        icon: "speaker.wave.2.fill",
                        title: "Listen to Audio",
                        description: "Audio plays automatically with streaming TTS"
                    )
                    
                    TutorialStep(
                        icon: "hand.tap.fill",
                        title: "Return to Home",
                        description: "Tap the response or long press to go back"
                    )
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // New features
                    Text("✨ New Features")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("• 💭 Memory: AI remembers your conversation")
                        Text("• ⚡ Streaming: Faster responses")
                        Text("• 🎯 Smart Limits: 30s recording, 200 tokens")
                        Text("• 🔊 Enhanced Audio: Chunked playback")
                        Text("• 📊 Performance Tracking")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Tutorial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Tutorial Step Component
struct TutorialStep: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TutorialView()
} 