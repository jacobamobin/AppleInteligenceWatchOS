//
//  FirstOpen.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 1/10/25.
//

import SwiftUI

struct FirstOpen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Tutorial")
                    .font(.title)
                    .bold()
                    .padding(.bottom)

                Text("1. On the time screen, start holding to talk.\n")
                Text("2. Release your finger to send the message.\n")
                Text("3. Tap on the response text to go back to the clock screen, or long hold to talk right away.\n")
                Text("4. Add the complication to your stock watchscreen.\n")
                Text("5. Allow this app to stay open by default.\n")
            }
            .padding()
        }
    }
}

#Preview {
    FirstOpen()
}
