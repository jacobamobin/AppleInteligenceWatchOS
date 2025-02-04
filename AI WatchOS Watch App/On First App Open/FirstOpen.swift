//
//  FirstOpen.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 1/10/25.
//

import SwiftUI

struct FirstOpen: View {
    @Binding var showTutorial: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Tutorial")
                    .font(.title)
                    .bold()
                    .padding(.bottom)

                Text("1. On the time screen, start holding to talk.")
                Text("2. Release your finger to send the message.")
                Text("3. Tap on the response text to go back to the clock screen, or long hold to talk right away.")
                Text("4. Add the complication to your stock watchscreen.")
                Text("5. Allow this app to stay open by default.")
            }
            .padding()

            Button("Close Tutorial") {
                showTutorial = false
            }
            .padding()
        }
    }
}

// Preview
struct FirstOpen_Previews: PreviewProvider {
    static var previews: some View {
        FirstOpen(showTutorial: .constant(true))
    }
}

