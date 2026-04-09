import Foundation

struct PanelConfig: Codable, Identifiable {
    let id: UUID
    var pair: TradingPair
    var interval: ChartInterval

    init(id: UUID = UUID(), pair: TradingPair, interval: ChartInterval = .oneHour) {
        self.id = id
        self.pair = pair
        self.interval = interval
    }
}
