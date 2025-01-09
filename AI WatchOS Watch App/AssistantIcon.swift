//
//  AssistantIcon.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 1/9/25.
//

import SwiftUI

struct AssistantIcon: View {
    @State private var assistantName: String = UserDefaults.standard.string(forKey: "AssistantName") ?? "Jarvis"

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)

                Image(systemName: "mic.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text(assistantName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Speak Now")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

#Preview {
    AssistantIcon()
}

