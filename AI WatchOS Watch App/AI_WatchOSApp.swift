//
//  AI_WatchOSApp.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-05.
//
import SwiftUI

@main
struct AI_WatchOS_Watch_AppApp: App {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false
    @State private var showTutorial: Bool = true
    
    var body: some Scene {
        WindowGroup {
            if hasLaunchedBefore {
                ContentView()
            } else {
                FirstOpen(showTutorial: $showTutorial)
                    .onAppear {
                        hasLaunchedBefore = true
                    }
            }
        }
    }
}
