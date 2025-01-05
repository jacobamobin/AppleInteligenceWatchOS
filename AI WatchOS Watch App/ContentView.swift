//
//  ContentView.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import SwiftUI

struct ContentView: View {
    let assistantName: String = "Aria"
    let perplexityApiKey: String = "your-perplexity-api-key"
    
    @State private var userPrompt: String = ""
    @State private var responseText: String = "Response will appear here."
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text(assistantName)
                    .font(.headline)
                    .padding(.leading)
                Spacer()
                Text(Date.now, style: .time)
                    .font(.headline)
                    .padding(.trailing)
            }
            .padding(.top, 17)
            
            Spacer()
            
            // User Prompt Input
            VStack {
                TextField("Enter your prompt", text: $userPrompt)
                    .padding()
                
                Button(action: {
                    sendRequest(
                        to: "https://api.perplexity.ai/query",
                        systemPrompt: "Your a helpful WatchOS assistant names \(assistantName), You will be givent prompts by the user like it is having a normal conversation with you. Respond like a normal human conversation, You name is \(assistantName) do not go by any other name.",
                        userPrompt: userPrompt
                    )
                }) {
                    Text("Send Prompt")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            .padding()
            
            // Response Text
            Text(responseText)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 5)
                .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
    
    // Function to send a request to Perplexity API
    func sendRequest(to urlString: String, systemPrompt: String, userPrompt: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(perplexityApiKey, forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    responseText = responseString
                }
            } else {
                print("Unable to decode response")
            }
        }.resume()
    }
}

#Preview {
    ContentView()
}




