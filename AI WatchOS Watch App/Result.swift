//
//  Result.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import Foundation

// Function to send a request to Perplexity API and return the response as a string
public func sendRequest(userPrompt: String) -> String {
    
    let apiKey: String = getChatGPTKey() ?? "Invalid API Key"
    let assistantName: String = "Jarvis"
    
    guard let url = URL(string: "https://api.perplexity.ai/chat/completions") else {
        return "Invalid URL"
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let payload: [String: Any] = [
        "model": "llama-3.1-sonar-small-128k-online",
        "messages": [
            ["role": "system", "content": "Your name is \(assistantName) and you are a watchOS assistant. Be helpful and conversational."],
            ["role": "user", "content": userPrompt]
        ],
        "max_tokens": 100,
        "temperature": 0.2
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
    } catch {
        return "Error serializing JSON payload: \(error.localizedDescription)"
    }
    
    // Synchronously perform the API request to simplify the function (for demo purposes)
    let semaphore = DispatchSemaphore(value: 0)
    var responseText = "No response"
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            responseText = "Error: \(error.localizedDescription)"
            semaphore.signal()
            return
        }
        
        guard let data = data else {
            responseText = "Error: No data received from server."
            semaphore.signal()
            return
        }
        
        do {
            if let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = responseObject["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                responseText = content
            } else {
                responseText = "Error decoding response."
            }
        } catch {
            responseText = "Error decoding server response."
        }
        
        semaphore.signal()
    }.resume()
    
    semaphore.wait() // Block the thread until the response is received
    return responseText
}

// Helper function to load API key from the plist
func loadAPIKey() -> String? {
    if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
       let config = NSDictionary(contentsOfFile: path),
       let apiKey = config["PerplexityAPIKey"] as? String {
        return apiKey
    }
    return nil
}

