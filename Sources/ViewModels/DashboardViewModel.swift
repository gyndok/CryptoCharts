import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var layout: GridLayout {
        didSet { adjustPanels(); save() }
    }
    @Published var panels: [ChartPanelViewModel] = []
    @Published var customPairs: [TradingPair] = []

    var allPairs: [TradingPair] {
        Constants.defaultPairs + customPairs
    }

    init() {
        let settings = AppSettings.load()
        self.layout = settings.layout
        self.customPairs = settings.customPairs

        // Create panel VMs from saved configs
        self.panels = settings.panels.map { config in
            let vm = ChartPanelViewModel(config: config)
            vm.onConfigChanged = { [weak self] in self?.save() }
            return vm
        }

        adjustPanels()
    }

    func startAll() {
        for panel in panels {
            panel.start()
        }
    }

    func stopAll() {
        for panel in panels {
            panel.stop()
        }
    }

    func addCustomPair(symbol: String) {
        let upper = symbol.uppercased()
        guard !allPairs.contains(where: { $0.symbol == upper }) else { return }

        // Try to split: assume quote is USDT if not obvious
        let base: String
        let quote: String
        if upper.hasSuffix("USDT") {
            base = String(upper.dropLast(4))
            quote = "USDT"
        } else if upper.hasSuffix("BTC") {
            base = String(upper.dropLast(3))
            quote = "BTC"
        } else if upper.hasSuffix("ETH") {
            base = String(upper.dropLast(3))
            quote = "ETH"
        } else if upper.hasSuffix("BUSD") {
            base = String(upper.dropLast(4))
            quote = "BUSD"
        } else {
            base = upper
            quote = "USDT"
        }

        let pair = TradingPair(symbol: upper, baseAsset: base, quoteAsset: quote)
        customPairs.append(pair)
        save()
    }

    func save() {
        let settings = AppSettings(
            layout: layout,
            panels: panels.map(\.config),
            customPairs: customPairs
        )
        settings.save()
    }

    private func adjustPanels() {
        let needed = layout.panelCount

        while panels.count < needed {
            let pairIndex = panels.count % Constants.defaultPairs.count
            let config = PanelConfig(pair: Constants.defaultPairs[pairIndex])
            let vm = ChartPanelViewModel(config: config)
            vm.onConfigChanged = { [weak self] in self?.save() }
            panels.append(vm)
        }

        while panels.count > needed {
            let removed = panels.removeLast()
            removed.stop()
        }
    }
}
