import Foundation
import SwiftUI
import os

private let logger = Logger(subsystem: "com.cryptocharts", category: "Dashboard")

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

        self.panels = settings.panels.map { config in
            let vm = ChartPanelViewModel(config: config)
            vm.onConfigChanged = { [weak self] in self?.save() }
            return vm
        }

        adjustPanels()
    }

    func startAll() {
        for panel in panels {
            panel.startIfNeeded()
        }
    }

    func stopAll() {
        for panel in panels {
            panel.stop()
        }
    }

    @discardableResult
    func addCustomPair(symbol: String) -> TradingPair? {
        let cleaned = symbol.trimmingCharacters(in: .whitespaces).uppercased()
        if let existing = allPairs.first(where: { $0.symbol == cleaned || $0.restPair == cleaned }) {
            return existing
        }

        let base: String
        let quote: String
        let wsSymbol: String
        let restPair: String

        if cleaned.contains("/") {
            let parts = cleaned.split(separator: "/")
            base = String(parts[0])
            quote = parts.count > 1 ? String(parts[1]) : "USD"
            wsSymbol = "\(base)/\(quote)"
            restPair = "\(base)\(quote)"
        } else if cleaned.hasSuffix("USD") {
            base = String(cleaned.dropLast(3))
            quote = "USD"
            wsSymbol = "\(base)/\(quote)"
            restPair = cleaned
        } else {
            base = cleaned
            quote = "USD"
            wsSymbol = "\(base)/\(quote)"
            restPair = "\(base)USD"
        }

        let pair = TradingPair(symbol: wsSymbol, restPair: restPair, baseAsset: base, quoteAsset: quote)
        customPairs.append(pair)
        save()
        logger.info("Added custom pair: \(wsSymbol)")
        return pair
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
