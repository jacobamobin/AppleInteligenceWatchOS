//
//  AppSettings.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 1/19/25.
//

import Foundation
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var volume: Double {
        didSet {
            // Save the volume to UserDefaults so it's persistent
            UserDefaults.standard.set(volume, forKey: "Volume")
        }
    }
    
    private init() {
        // Load the volume from UserDefaults or default to 100%
        self.volume = UserDefaults.standard.double(forKey: "Volume")
        if self.volume == 0 {
            self.volume = 100.0  // Default volume at 100% if not set
        }
    }
}
