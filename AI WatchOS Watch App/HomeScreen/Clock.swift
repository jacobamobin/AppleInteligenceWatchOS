//
//  Clock.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 1/9/25.
//

import SwiftUI

// MARK: Simple view for the HOUR/MINUTE clock on the homescreen
struct Clock: View {
    @State private var currentTime = CurrentTime()
    @State private var timer: Timer?

    var body: some View {
        VStack(alignment: .center, spacing: -30) {
            Text(currentTime.hour)
                .font(.system(size: 90, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(currentTime.minute)
                .font(.system(size: 90, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            /*
            if let ampm = currentTime.ampm {
                Text(ampm)
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.top, -20)
            }
             */
        }
        .padding(.bottom, 20)
        .onAppear {
            startClock()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            // Update current time when UserDefaults changes
            currentTime = CurrentTime()
        }
    }

    // Starts the clock on view load
    private func startClock() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            currentTime = CurrentTime()
        }
    }
}

// Gets the current time
struct CurrentTime {
    let hour: String
    let minute: String
    let ampm: String?

    init() {
        let now = Date()
        let calendar = Calendar.current

        // Read use24HourFormat from UserDefaults
        let use24HourFormat = UserDefaults.standard.bool(forKey: "Use24HourFormat")

        var hourInt = calendar.component(.hour, from: now)
        let minuteInt = calendar.component(.minute, from: now)

        if !use24HourFormat {
            // Convert to 12-hour format
            let isPM = hourInt >= 12
            ampm = isPM ? "PM" : "AM"
            hourInt = hourInt % 12
            if hourInt == 0 {
                hourInt = 12
            }
        } else {
            ampm = nil
        }

        hour = String(format: "%02d", hourInt)
        minute = String(format: "%02d", minuteInt)
    }
}

#Preview {
    Clock()
}

#Preview {
    ContentView()
}
