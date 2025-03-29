//
//  Result.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//

import Foundation

// MARK: Uses the perplexity API to get a response to the user's question
func sendRequest(userPrompt: String) -> String {
    // Load api key from Config.plist
    let apiKey: String = loadAPIKey() ?? "Invalid API Key"
    // Get assistant name from UserDefaults
    let assistantName: String = UserDefaults.standard.string(forKey: "AssistantName") ?? "Jarvis"
    
    // This is the URL for Perplexity
    guard let url = URL(string: "https://api.perplexity.ai/chat/completions") else {
        print("Invalid URL")
        return "Error: Invalid URL"
    }
    
    // Start building the Request
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") // Using apiKey instead of perplexityApiKey
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Payload for the API with parameters as defined on Perplexity's API documentation
    let payload: [String: Any] = [
        "model": "sonar-pro",
        "messages": [
            ["role": "system", "content": "Dont greet the user get to the point. Your name is \(assistantName) and you are a WatchOS assistant on the user's wrist, act like you are having a normal conversation with the user, and answer any questions the user asks. Be a helpful, useful assistant and remember your name is \(assistantName), Keep your answers under 150 words if possible. If you get a sound error, like 0.1 seconds related, ignore it and return 'I couldn't hear that, sorry'."],
            ["role": "user", "content": userPrompt]
        ],
        "max_tokens": 300,
        "temperature": 0.2,
        "top_p": 0.9,
        "return_images": false,
        "return_related_questions": false,
        "search_recency_filter": "month",
        "top_k": 0,
        "stream": false,
        "presence_penalty": 0,
        "frequency_penalty": 1
    ]
    
    // Send the request
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
    } catch {
        print("Error serializing JSON payload: \(error.localizedDescription)")
        return "Error: Failed to serialize JSON payload"
    }
    
    var responseText = ""
    
    // Capture self weakly to avoid retain cycles
    let semaphore = DispatchSemaphore(value: 0) // To wait for the completion of the async call
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error making API call: \(error.localizedDescription)")
            responseText = "Error: \(error.localizedDescription)"
            semaphore.signal()
            return
        }
        
        guard let data = data else {
            print("No data received")
            responseText = "Error: No data received from server."
            semaphore.signal()
            return
        }
        
        // Debugging: Print the raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw response: \(responseString)")
        }
        
        // Debugging and parsing
        do {
            if let responseObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                // Check the structure of the response
                print("Response JSON structure: \(responseObject)")
                
                // Try to parse the response based on expected structure
                if let choices = responseObject["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    responseText = content
                } else if let errorMessage = responseObject["error"] as? String {
                    // Handle errors returned in response
                    responseText = "API Error: \(errorMessage)"
                } else {
                    print("Unable to find expected keys in the response.")
                    responseText = "Error decoding response."
                }
            } else {
                print("Response is not valid JSON.")
                responseText = "Error parsing server response."
            }
        } catch {
            print("Error decoding JSON response: \(error.localizedDescription)")
            responseText = "Error decoding server response."
        }
        semaphore.signal()
    }.resume()
    
    semaphore.wait() // Wait for the API call to finish
    return RemoveCitations(prompt: responseText)
    // TODO: Remove citations from return
}

// Helper function to load Perplexity API key from the plist
func loadAPIKey() -> String? {
    if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
       let config = NSDictionary(contentsOfFile: path),
       let apiKey = config["Perplexity"] as? String {
        return apiKey
    }
    return nil
}
