//
//  ContentView.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import SwiftUI

struct ContentView: View {
    let assistantName: String = "Aria"
    let perplexityApiKey: String = "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" // Replace with your actual API key
    
    @State private var userPrompt: String = ""  // State variable for user input
    @State private var responseText: String = "Response will appear here."
    @State private var isLoading: Bool = false // Loading state to disable UI during API calls
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text(assistantName)
                    .font(.headline)
                    .padding(.leading)
                Spacer()
            }
            .padding(.top, 17)
            
            Spacer()
            
            // User Prompt Input
            VStack {
                TextField("Enter your prompt", text: $userPrompt)
                    .padding()
                    .textFieldStyle(.automatic) // Improved styling
                
                Button(action: {
                    sendRequest(userPrompt: userPrompt) // Send the user input
                }) {
                    if isLoading {
                        ProgressView() // Show a loading spinner while waiting for a response
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else {
                        Text("Send Prompt")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
                .disabled(isLoading || userPrompt.isEmpty) // Disable button if loading or input is empty
            }
            .padding()
            
            // Response Text
            ScrollView {
                Text(responseText)
                    .padding()
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                    .shadow(radius: 5)
                    .padding()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(Color(UIColor.black)) // Background color for better contrast
    }
    
    // Function to send a request to Perplexity API
    func sendRequest(userPrompt: String) {
        guard let url = URL(string: "https://api.perplexity.ai/chat/completions") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(perplexityApiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": "llama-3.1-sonar-small-128k-online",
            "messages": [
                ["role": "system", "content": "Be precise and concise."],
                ["role": "user", "content": userPrompt]
            ],
            "max_tokens": 100,
            "temperature": 0.2,
            "top_p": 0.9,
            "search_domain_filter": ["perplexity.ai"],
            "return_images": false,
            "return_related_questions": false,
            "search_recency_filter": "month",
            "top_k": 0,
            "stream": false,
            "presence_penalty": 0,
            "frequency_penalty": 1
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Error serializing JSON payload: \(error.localizedDescription)")
            return
        }
        
        isLoading = true // Set loading state
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false // Reset loading state
            }
            
            if let error = error {
                print("Error making API call: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.responseText = "Error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    self.responseText = "Error: No data received from server."
                }
                return
            }
            
            do {
                if let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let choices = responseObject["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        DispatchQueue.main.async {
                            self.responseText = content
                        }
                    } else {
                        print("Unable to decode response JSON structure.")
                        DispatchQueue.main.async {
                            self.responseText = "Error decoding response."
                        }
                    }
                } else {
                    print("Response is not valid JSON.")
                    DispatchQueue.main.async {
                        self.responseText = "Error parsing server response."
                    }
                }
            } catch {
                print("Error decoding JSON response: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.responseText = "Error decoding server response."
                }
            }
        }.resume()
    }
}

#Preview {
    ContentView()
}





