//
//  Clock.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 1/9/25.
//

import SwiftUI

// MARK: Simple view for the HOUR/MINUITE clock on the homescreen
struct Clock: View {
    @State private var currentTime = CurrentTime()

    var body: some View {
        VStack(alignment: .center, spacing: -30) {
            Text(currentTime.hour)
                .font(.system(size: 90, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(currentTime.minute)
                .font(.system(size: 90, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }.padding(.bottom, 20)
        .onAppear {
            startClock()
        }
    }

    //Starts the clock on view load
    private func startClock() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            currentTime = CurrentTime()
        }
    }
}

// Gets the current time
struct CurrentTime {
    let hour: String
    let minute: String

    init() {
        let now = Date()
        let calendar = Calendar.current
        let hourInt = calendar.component(.hour, from: now)
        let minuteInt = calendar.component(.minute, from: now)

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
