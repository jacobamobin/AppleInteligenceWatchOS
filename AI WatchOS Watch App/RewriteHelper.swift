//
//  RewriteHelper.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-07.
//

import Foundation
import OpenAI

func sendRewriteRequest(userPrompt: String) async throws -> String {
    // Initialize OpenAI with your API key
    let openAI = OpenAI(apiToken: getChatGPTKey() ?? "Invalid API Key")
    let assistantName: String = "Jarvis"
    
    // Prepare the completion query
    let query = CompletionsQuery(
        model: .textDavinci_003,
        prompt: "\(assistantName): \(userPrompt)",
        temperature: 0.7,
        maxTokens: 150,
        topP: 1.0,
        frequencyPenalty: 0.0,
        presencePenalty: 0.0
    )
    
    // Make the request and handle the result
    do {
        let result = try await openAI.completions(query: query)
        if let choice = result.choices.first {
            return choice.text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            throw NSError(domain: "sendRequest", code: 0, userInfo: [NSLocalizedDescriptionKey: "No completions returned."])
        }
    } catch {
        throw NSError(domain: "sendRequest", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve completion: \(error.localizedDescription)"])
    }
}


