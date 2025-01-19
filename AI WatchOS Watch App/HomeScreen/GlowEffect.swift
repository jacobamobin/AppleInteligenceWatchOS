//
//  GlowEffect.swift
//  AI WatchOS Watch App
//
//  Created by Jacob Mobin on 2025-01-06.
//

import SwiftUI
import WatchKit

// MARK: The apple inteligence glow effect function
// It is made up of 4 different layers.
struct GlowEffect: View {
    @State private var gradientStops: [Gradient.Stop] = GlowEffect.generateGradientStops()
    @State private var timers: [Timer] = []

    var freeze: Bool
    
    let cornerRoundness: Int = DeviceConfig.cornerRoundness
    let screenOffset: Int = DeviceConfig.screenOffset

    var body: some View {
        ZStack {
            // First layer is the border around the edge
            // The next 3 layers are the blurry layers closer to the middle of the screen
            EffectNoBlur(gradientStops: gradientStops, width: 5, cornerRoundness: DeviceConfig.cornerRoundness, screenOffset: DeviceConfig.screenOffset)
            Effect(gradientStops: gradientStops, width: 7, blur: 4, cornerRoundness: DeviceConfig.cornerRoundness, screenOffset: DeviceConfig.screenOffset)
            Effect(gradientStops: gradientStops, width: 9, blur: 12, cornerRoundness: DeviceConfig.cornerRoundness, screenOffset: DeviceConfig.screenOffset)
            Effect(gradientStops: gradientStops, width: 12, blur: 15, cornerRoundness: DeviceConfig.cornerRoundness, screenOffset: DeviceConfig.screenOffset)
        }
        .onAppear { // On appread
            if !freeze {
                startTimers()
            }
        }
        // Check if the view should be frozen
        .onChange(of: freeze) { isFrozen in
            if isFrozen {
                stopTimers()
            } else {
                startTimers()
            }
        }
        .onDisappear {
            stopTimers()
        }
    }

    // MARK: Function to start the timers for the gradients
    private func startTimers() {
        stopTimers() // Ensure no existing timers are running
        timers.append(
            Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.6)) {
                    gradientStops = GlowEffect.generateGradientStops()
                }
            }
        )
    }

    // MARK: Function to stop the timers for the gradients
    private func stopTimers() {
        timers.forEach { $0.invalidate() }
        timers.removeAll()
    }

    // Function to generate random gradient stops on an Angular Gradient
    // MARK: Function to generate the colours of the Glow Effect
    // Change the hex codes to change the colours
    static func generateGradientStops() -> [Gradient.Stop] {
        [
            Gradient.Stop(color: Color(hex: "BC82F3"), location: Double.random(in: 0...1)),
            Gradient.Stop(color: Color(hex: "F5B9EA"), location: Double.random(in: 0...1)),
            //Gradient.Stop(color: Color(hex: "8D9FFF"), location: Double.random(in: 0...1)),
            Gradient.Stop(color: Color(hex: "FF6778"), location: Double.random(in: 0...1)),
            Gradient.Stop(color: Color(hex: "FFBA71"), location: Double.random(in: 0...1)),
            Gradient.Stop(color: Color(hex: "C686FF"), location: Double.random(in: 0...1))
        ].sorted { $0.location < $1.location }
    }
    
    // MARK: Calculate paramaters for the glow effect based on screen size of the watch
    
}

// MARK: These Effect Functions generate the different layers that make up the gradient effect
//Effect means the layers have a Blur (inner 3 layers)
struct Effect: View {
    var gradientStops: [Gradient.Stop]
    var width: Double
    var blur: Double
    var cornerRoundness: Int
    var screenOffset: Int

    var body: some View {
        RoundedRectangle(cornerRadius: CGFloat(cornerRoundness))
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(stops: gradientStops),
                    center: .center
                ),
                lineWidth: width
            )
            .frame(
                width: WKInterfaceDevice.current().screenBounds.width,
                height: WKInterfaceDevice.current().screenBounds.height
            )
            .padding(.top, -1 * CGFloat(screenOffset))
            .blur(radius: blur)
    }
}

//Effect no blur if for the last layer on the very edge of the screen
struct EffectNoBlur: View {
    var gradientStops: [Gradient.Stop]
    var width: Double
    var cornerRoundness: Int
    var screenOffset: Int

    var body: some View {
        RoundedRectangle(cornerRadius: CGFloat(cornerRoundness))
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(stops: gradientStops),
                    center: .center
                ),
                lineWidth: width
            )
            .frame(
                width: WKInterfaceDevice.current().screenBounds.width,
                height: WKInterfaceDevice.current().screenBounds.height
            )
            .padding(.top, -1 * CGFloat(screenOffset))
    }
}

// MARK: Color function that converts HEX (From figma) into RGB values for SwiftUI
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var hexNumber: UInt64 = 0
        scanner.scanHexInt64(&hexNumber)

        let r = Double((hexNumber & 0xff0000) >> 16) / 255
        let g = Double((hexNumber & 0x00ff00) >> 8) / 255
        let b = Double(hexNumber & 0x0000ff) / 255

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: Screen Dimension and Offset Constants
struct DeviceConfig {
    static let width = WKInterfaceDevice.current().screenBounds.width
    static let height = WKInterfaceDevice.current().screenBounds.height
    
    init() {
         print("Device Width: \(DeviceConfig.width), Height: \(DeviceConfig.height)")
    }

    // Calculate corner roundness and screen offset
    static let cornerRoundness: Int = {
        print("Device Width: \(Int(width)), Height: \(Int(height))")
        switch (Int(width), Int(height)) {
        case (208, 248): // Apple Watch Series 10 (46mm)
            return 50
        case (187, 223): // Apple Watch Series 10 (42mm)
            return 45
        case (162, 197): // Apple Watch SE (2nd gen) (44mm), Series 6, 7, 8, 9 (44mm)
            return 28
        case (184, 224): // Apple Watch Series 6
            return 34
        case (352, 430): // Apple Watch Series 7, 8, 9 (41mm) UNUSED
            return 16
        case (205, 251): //Apple watch Ultra
            return 55
        case (324, 394): // Apple Watch SE (2nd gen) (40mm), Series 6 (40mm) UNUSED
            return 14
        default: // Fallback for unknown screen sizes
            return 28
        }
    }()

    static let screenOffset: Int = {
        print("Device Width: \(Int(width)), Height: \(Int(height))")
        switch (Int(width), Int(height)) {
        case (208, 248): // Apple Watch Series 10 (46mm)
            return 17
        case (187, 223): // Apple Watch Series 10 (42mm)
            return 17
        case (162, 197): // Apple Watch SE (2nd gen) (44mm), Series 6, 7, 8, 9 (44mm)
            return 20
        case (184, 224): // Apple Watch Series 6
            return 24
        case (352, 430): // Apple Watch Series 7, 8, 9 (41mm) UNUSED
            return 6
        case (205, 251): // Apple Watch Ultra
            return 17
        case (324, 394): // Apple Watch SE (2nd gen) (40mm), Series 6 (40mm) UNUSED
            return 5
        default: // Fallback for unknown screen sizes
            return 5
        }
    }()
}

// Preview
#Preview {
    GlowEffect(freeze: false) // Toggle `freeze` to test behavior
}
