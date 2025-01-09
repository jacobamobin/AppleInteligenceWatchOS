//
//  TopBar.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 1/9/25.
//

import SwiftUI

struct TopBar: View {
    @State private var assistantName: String = UserDefaults.standard.string(forKey: "AssistantName") ?? "Jarvis"
    @State private var showVolumeControl = false
    @State private var volume: Double = 50.0 // Default volume
    @State private var showTutorial = false // State for tutorial view
    @FocusState private var isVolumeFocused: Bool // For Digital Crown focus

    var body: some View {
        NavigationView {
            VStack {
                // Top Navigation Bar
                HStack {
                    // Left side with Volume, Settings, and Tutorial buttons
                    HStack(spacing: -5) { // Added spacing between buttons
                        // Volume Button
                        Button(action: {
                            showVolumeControl.toggle()
                        }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title3) // Smaller icon
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.2)) // Circular background with slight opacity
                                )
                        }
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.clear)
                        .sheet(isPresented: $showVolumeControl) {
                            VolumeControlView(volume: $volume)
                        }

                        // Settings Button
                        NavigationLink(destination: Settings()) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3) // Smaller icon
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.2)) // Circular background with slight opacity
                                )
                        }
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.clear)

                        // Tutorial Button
                        Button(action: {
                            showTutorial.toggle()
                        }) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.title3) // Smaller icon
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.2)) // Circular background with slight opacity
                                )
                        }
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.clear)
                        .sheet(isPresented: $showTutorial) {
                            TutorialView()
                        }
                    }

                    Spacer()

                    // Assistant Name (aligned to the far right)
                    Text(assistantName)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.top, 20) // Added padding to the right edge
                }
                .padding(.top, 10) // Optional: Add padding to the top of the HStack for better spacing
            }
        }
    }
}

struct VolumeControlView: View {
    @Binding var volume: Double
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            Text("Adjust Volume")
                .font(.headline)
                .padding()

            Text("Using Digital Crown")
                .font(.subheadline)

            // Volume Display
            Text("\(Int(volume))%")
                .font(.largeTitle)
                .padding()
                .focusable(true)
                .focused($isFocused)
                .digitalCrownRotation($volume, from: 0, through: 100, by: 1, sensitivity: .medium, isContinuous: false)

            Spacer()
        }
        .onAppear {
            isFocused = true
        }
        .padding()
    }
}

struct TutorialView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Tutorial")
                    .font(.title)
                    .bold()
                    .padding(.bottom)

                Text("Here's a brief guide on how to use the app:")
                    .font(.headline)

                Text("1. On the time screen start holding to talk")
                Text("2. Release your finger to send the message")
                Text("3. Tap on the response text to go back to the clock screen, or long hold to talk right away")
                Text("4. Adjust volume with the volume button")
                Text("5. Go to settings to customize assistant name and voice")

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    TopBar()
}
