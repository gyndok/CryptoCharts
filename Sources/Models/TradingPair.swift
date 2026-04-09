import Foundation

struct TradingPair: Codable, Hashable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let baseAsset: String
    let quoteAsset: String

    var displayName: String { "\(baseAsset)/\(quoteAsset)" }
    var wsSymbol: String { symbol.lowercased() }
}
