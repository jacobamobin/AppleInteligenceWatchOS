//
//  test.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 1/8/25.
//

import SwiftUI

struct test: View {
    @State private var tts = TTS() // Instance of TTS
    var body: some View {
        Button {
            tts.generateAndPlayAudio(from: "Hello what is your name jacob")
        } label: {
            Text("Hello")
        }
    }
}

#Preview {
    test()
}
