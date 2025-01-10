//
//  AssistantIcon.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 1/9/25.
//

import SwiftUI

// MARK: A Placeholder when you are holding the screen and talking to the AI
struct ThinkingIcon: View {
    //Get the assistant name from UserDefaults
    @State private var assistantName: String = UserDefaults.standard.string(forKey: "AssistantName") ?? "Jarvis"

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Microphone Circle
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)

                Image(systemName: "brain")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }

            //Text below
            VStack(spacing: 4) {
                Text(assistantName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Generating Response")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

#Preview {
    ThinkingIcon()
}

