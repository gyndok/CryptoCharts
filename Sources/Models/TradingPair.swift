import Foundation

struct TradingPair: Codable, Hashable, Identifiable {
    var id: String { symbol }
    let symbol: String      // Kraken WS format: "BTC/USD"
    let restPair: String    // Kraken REST format: "XBTUSD"
    let baseAsset: String
    let quoteAsset: String

    var displayName: String { "\(baseAsset)/\(quoteAsset)" }
}
