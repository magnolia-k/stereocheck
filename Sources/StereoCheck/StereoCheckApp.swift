import SwiftUI

@main
struct StereoCheckApp: App {
    @StateObject private var monitor = AudioMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(monitor)
        } label: {
            Image(systemName: "hifispeaker.2.fill")
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(monitor.hasSwapped ? .orange : .primary)
        }
        .menuBarExtraStyle(.window)
    }
}
