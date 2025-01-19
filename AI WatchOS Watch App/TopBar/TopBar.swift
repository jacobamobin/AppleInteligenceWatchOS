//
//  TopBar.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 1/9/25.
//

import SwiftUI
import WatchKit

// MARK: The main top bar view, Includes volume, settings, tutorial, and AssistantName
struct TopBar: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var assistantName: String = UserDefaults.standard.string(forKey: "AssistantName") ?? "Jarvis"
    @State private var showVolumeControl = false // State for volume control sheet
    @State private var showTutorial = false // State for tutorial view
    @FocusState private var isVolumeFocused: Bool // For Digital Crown focus
    @State private var isSmallWatch: Bool = false

    var body: some View {
        VStack {
            // Top Navigation Bar
            HStack {
                // Left side with Volume, Settings, and Tutorial buttons
                HStack(spacing: -5) {
                    // Volume Button
                    Button(action: {
                        showVolumeControl.toggle()
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                            )
                    }
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.clear)
                    .sheet(isPresented: $showVolumeControl) {
                        VolumeControlView()
                    }

                    // Settings Button
                    NavigationLink(destination: Settings()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                            )
                    }
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.clear)

                    // Tutorial Button
                    Button(action: {
                        showTutorial.toggle()
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                            )
                    }
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.clear)
                    .sheet(isPresented: $showTutorial) {
                        TutorialView()
                    }
                }

                Spacer()

                // Assistant Name (conditionally displayed based on screen size)
                if !isSmallWatch {
                    Text(assistantName)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                }
            }
            .padding(.top, 10)
            .onAppear {
                // Determine if the watch is small (adjust the width threshold if necessary)
                isSmallWatch = WKInterfaceDevice.current().screenBounds.width < 184 // Adjust based on device
            }
        }
    }
}

// MARK: The volume selector view, controlled with the Digital Crown
struct VolumeControlView: View {
    @ObservedObject var settings = AppSettings.shared
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            Text("Adjust Volume")
                .font(.headline)
                .padding()

            Text("Use Digital Crown")
                .font(.subheadline)

            // Volume Display
            Text("\(Int(settings.volume))%")
                .font(.largeTitle)
                .padding()
                .focusable(true)
                .focused($isFocused)
                .digitalCrownRotation($settings.volume, from: 0, through: 100, by: 1, sensitivity: .medium, isContinuous: false)

            Spacer()
        }
        .onAppear {
            isFocused = true
        }
        .padding()
    }
}

#Preview {
    TopBar()
}
