//
//  AppSettings.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 1/19/25.
//

import SwiftUI
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var volume: Double {
        didSet {
            UserDefaults.standard.set(volume, forKey: "volume")
        }
    }

    private init() {
        self.volume = UserDefaults.standard.object(forKey: "volume") as? Double ?? 50.0
    }
}
