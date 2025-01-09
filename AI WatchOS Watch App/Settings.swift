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
    
    let demoOptions = ["Alloy":".alloy", "Echo":".echo", "Fable":".fable", "Luna":".luna", "Onyx":".onyx", "Nova":".nova", "Shimmer":".shimmer"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Assistant Name Input
                Text("Assistant Name")
                    .font(.headline)
                TextField("Enter name", text: $assistantName)
                    .textFieldStyle(.automatic)

                // Assistant Voice
                Text("Assistant Voice")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    ForEach(0..<demoOptions.count, id: \.self) { index in
                        HStack {
                            Button(action: {
                                selectedOption = index
                            }) {
                                HStack {
                                    Text(demoOptions.keys.sorted()[index])
                                        .font(.body)
                                        .foregroundColor(selectedOption == index ? .white : .white)
                                    Spacer()
                                }
                                .padding()
                                .background(selectedOption == index ? Color.blue : Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                let greeting = "Hi, I'm \(assistantName), here to help you with your everyday needs."
                                tts.generateAndPlayAudio(from: greeting)
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title)
                                    .foregroundColor(selectedOption == index ? .blue : .gray)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
                
                // Privacy Policy Button
                Button(action: {
                    showPrivacyPolicy.toggle()
                }) {
                    Text("Privacy Policy")
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 16)
                
                // Restore Purchases Button
                Button(action: {
                    restorePurchases()
                }) {
                    Text("Restore Purchases")
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Open GitHub Button
                Button(action: {
                    if let url = URL(string: "https://github.com") {
                        //UIApplication.shared.open(url)
                    }
                }) {
                    Text("Open GitHub")
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // App Version
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
        .sheet(isPresented: $showRestorePurchases) {

        }
    }
    
    // Function to get app version
    func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"
    }
    
    // Restore purchases placeholder
    func restorePurchases() {
        // Implement restore purchases functionality here
        print("Restoring purchases...")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        VStack {
            Text("Privacy Policy")
                .font(.headline)
                .padding(.top)
            ScrollView {
                Text("Assistant for apple watch sends all your queries to ChatGPT (Voice) and Perplexity (Text). Therefore this application's privacy is governed by OpenAI's privacy policy and Perplexitys privacy policy. This app does not collect any personal information or data.")
                    .padding()
            }
        }
    }
}


#Preview {
    Settings()
}


