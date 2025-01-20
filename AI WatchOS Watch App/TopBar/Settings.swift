//
//  Settings.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 1/8/25.
//

import SwiftUI
import WatchKit

// MARK: The main settings page view
struct Settings: View {
    @State private var assistantName: String = UserDefaults.standard.string(forKey: "AssistantName") ?? "Jarvis"
    @State private var selectedOption: Int = UserDefaults.standard.integer(forKey: "SelectedOption")
    @State private var tts = TTS()
    @State private var showPrivacyPolicy = false
    @State private var showTutorial = false  // Added state to track tutorial visibility
    
    let demoOptions = ["Alloy": ".alloy", "Echo": ".echo", "Fable": ".fable", "Onyx": ".onyx", "Nova": ".nova", "Shimmer": ".shimmer"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AssistantNameInput(assistantName: $assistantName)
                    .onChange(of: assistantName) { newValue in
                        saveAssistantName(newValue)
                    }
                
                AssistantVoiceSelector(selectedOption: $selectedOption, demoOptions: demoOptions, assistantName: assistantName, tts: tts)
                    .onChange(of: selectedOption) { newValue in
                        saveSelectedOption(newValue)
                    }
            }
            .padding()
            
            VStack (spacing: 5){
                SettingsButton(title: "How to Use", action: {
                    showTutorial.toggle()  // Toggle tutorial visibility
                })
                
                SettingsButton(title: "Privacy Policy", action: {
                    showPrivacyPolicy.toggle()
                })
                
                SettingsButton(title: "Restore Purchases", action: {
                    restorePurchases()
                })
                /*
                SettingsButton(title: "Open GitHub", action: {
                    openGitHub()
                })*/
                
                Text("App Version: \(getAppVersion())")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 16)
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTutorial) {  // Show Tutorial view as a sheet
            TutorialView()
        }
    }
    
    func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"
    }
    
    func restorePurchases() {
        print("Restoring purchases...")
    }
    
    func openGitHub() {
        if let url = URL(string: "https://github.com/jacobamobin/AppleIntelligenceWatchOS") {
            WKExtension.shared().openSystemURL(url)
        }
    }
    
    // Save assistant Name
    func saveAssistantName(_ name: String) {
        UserDefaults.standard.set(name, forKey: "AssistantName")
    }
    
    // Save assistant Voice
    func saveSelectedOption(_ option: Int) {
        UserDefaults.standard.set(option, forKey: "SelectedOption")
    }
}


// MARK: THe text field in which you chose the assistant name
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

// MARK: The assistant voice selector builder (Voice Testing + Name)
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
                            UserDefaults.standard.set(demoOptions.values.sorted()[index], forKey: "SelectedVoice")
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


// MARK: Shows the assistant voices, whichever one is selected is in Blue
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

// MARK: The play button for the Audio Showcase
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

// MARK: A settings button view
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

// MARK: Displays the privacy policy
struct PrivacyPolicyView: View {
    var body: some View {
        VStack {
            Text("Privacy Policy")
                .font(.headline)
                .padding(.top)
            ScrollView {
                Text("Assistant for Apple Watch sends all your queries to ChatGPT (Voice) and Perplexity (Text). Therefore this application's privacy is governed by OpenAI's privacy policy and Perplexity's privacy policy. This app does not collect any personal information or data.")
                    .padding()
            }
        }
    }
}

 // MARK: How to use View
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
    Settings()
}
