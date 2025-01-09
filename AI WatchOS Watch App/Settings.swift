//
//  Settings.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 1/8/25.
//

import SwiftUI

struct Settings: View {
    @State private var assistantName: String = ""
    @State private var selectedOption: Int = 0
    @State private var tts = TTS()
    @State private var showPrivacyPolicy = false
    @State private var showRestorePurchases = false
    
    let demoOptions = ["Alloy": ".alloy", "Echo": ".echo", "Fable": ".fable", "Onyx": ".onyx", "Nova": ".nova", "Shimmer": ".shimmer"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AssistantNameInput(assistantName: $assistantName)
                
                AssistantVoiceSelector(selectedOption: $selectedOption, demoOptions: demoOptions, assistantName: assistantName, tts: tts)
                
                SettingsButton(title: "Privacy Policy", action: {
                    showPrivacyPolicy.toggle()
                })
                
                SettingsButton(title: "Restore Purchases", action: {
                    restorePurchases()
                })
                
                SettingsButton(title: "Open GitHub", action: {
                    openGitHub()
                })
                
                Text("App Version: \(getAppVersion())")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 16)
            }
            .padding()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
    }
    
    func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"
    }
    
    func restorePurchases() {
        // Implement restore purchases functionality here
        print("Restoring purchases...")
    }
    
    func openGitHub() {
        if let url = URL(string: "https://github.com") {
            // UIApplication.shared.open(url)
        }
    }
}

struct AssistantNameInput: View {
    @Binding var assistantName: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Assistant Name")
                .font(.headline)
            TextField("Enter name", text: $assistantName)
                .textFieldStyle(.automatic)
        }
    }
}

struct AssistantVoiceSelector: View {
    @Binding var selectedOption: Int
    let demoOptions: [String: String]
    let assistantName: String
    let tts: TTS
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Assistant Voice")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(0..<demoOptions.count, id: \.self) { index in
                    HStack {
                        VoiceButton(title: demoOptions.keys.sorted()[index], selected: selectedOption == index) {
                            selectedOption = index
                        }
                        
                        PlayButton {
                            let selectedVoice = demoOptions.values.sorted()[index]
                            let greeting = "Hi, I'm \(assistantName), here to help you with your everyday needs."
                            tts.generateAndPlayAudio(from: greeting, voice: selectedVoice)
                        }
                    }
                }
            }
        }
    }
}

struct VoiceButton: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .foregroundColor(selected ? .white : .white)
            Spacer()
        }
        .padding()
        .background(selected ? Color.blue : Color.gray.opacity(0.2))
        .cornerRadius(8)
        .buttonStyle(PlainButtonStyle())
    }
}

struct PlayButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "play.circle.fill")
                .font(.title)
                .foregroundColor(.blue)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

struct SettingsButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding(.top, 16)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        VStack {
            Text("Privacy Policy")
                .font(.headline)
                .padding(.top)
            ScrollView {
                Text("Assistant for apple watch sends all your queries to ChatGPT (Voice) and Perplexity (Text). Therefore this application's privacy is governed by OpenAI's privacy policy and Perplexity's privacy policy. This app does not collect any personal information or data.")
                    .padding()
            }
        }
    }
}

#Preview {
    Settings()
}
