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
    @FocusState private var isVolumeFocused: Bool // For Digital Crown focus

    var body: some View {
        NavigationView {
            VStack {
                // Top Navigation Bar
                HStack {
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
                    }.foregroundStyle(.clear)
                    .sheet(isPresented: $showVolumeControl) {
                        VolumeControlView(volume: $volume)
                    }

                    Spacer()

  
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
                    }.foregroundStyle(.clear)
                    
                    Spacer()
                    
                    // Time and Assistant Name
                    VStack {
                        Text(assistantName)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }.padding(.top, 15)
                }
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

#Preview {
    TopBar()
}



