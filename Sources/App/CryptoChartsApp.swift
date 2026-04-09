import SwiftUI

@main
struct CryptoChartsApp: App {
    @StateObject private var dashboard = DashboardViewModel()

    var body: some Scene {
        WindowGroup {
            DashboardView(viewModel: dashboard)
                .frame(minWidth: 800, minHeight: 500)
        }
        .defaultSize(width: 1200, height: 800)
    }
}
