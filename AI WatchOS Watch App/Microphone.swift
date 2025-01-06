//
//  Microphone.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import SwiftUI
import WatchKit

struct Microphone: View {
    @State private var recognizedText = ""
    @State private var isRecording = false

    var body: some View {
        VStack {
            Text(recognizedText)
                .foregroundStyle(.white)
                .padding()

            Button(action: {}) { // Empty action because the long press gesture is handling the logic
                Text(isRecording ? "Stop" : "Hold to Speak")
                    .padding()
                    .background(isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .onLongPressGesture(minimumDuration: .infinity, pressing: { isPressing in
                if isPressing {
                    startDictation()
                } else {
                    stopDictation()
                }
            }, perform: {})
        }
    }

    private func startDictation() {
        WKInterfaceDevice.current().play(.start)
        isRecording = true

        // Start dictation, even though it may show the keyboard, we will handle this
        WKExtension.shared().rootInterfaceController?.presentTextInputController(withSuggestions: nil, allowedInputMode: .plain) { response in
            if let result = response as? [String] {
                // Capture the transcribed text
                recognizedText = result.joined(separator: " ")
            }
        }
    }

    private func stopDictation() {
        WKInterfaceDevice.current().play(.stop)
        isRecording = false
    }
}

#Preview {
    Microphone()
}
