import SwiftUI

@main
struct MasrafPaylasApp: App {
    @State private var store = TripStore()

    var body: some Scene {
        WindowGroup {
            TripsView()
                .environment(store)
                .tint(.appTeal)
        }
    }
}

extension Color {
    /// Android sürümüyle aynı ana renk (#0F766E)
    static let appTeal = Color(red: 15 / 255, green: 118 / 255, blue: 110 / 255)
}
