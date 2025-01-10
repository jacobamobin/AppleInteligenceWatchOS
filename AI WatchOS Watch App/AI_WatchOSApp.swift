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
    @AppStorage("gradientOffset") private var gradientOffset: CGFloat = 0.0
    @AppStorage("gradientCornerRadius") private var gradientCornerRadius: CGFloat = 0.0

    var body: some Scene {
        WindowGroup {
            if hasLaunchedBefore && gradientOffset != 0.0 && gradientCornerRadius != 0.0 {
                ContentView()
            } else {
                if hasLaunchedBefore {
                    Setup()
                } else {
                    FirstOpen()
                        .onAppear {
                            hasLaunchedBefore = true
                        }
                }
            }
        }
    }
}
