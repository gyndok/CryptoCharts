import SwiftUI

enum Constants {
    static let restBaseURL = "https://api.kraken.com"
    static let wsURL = "wss://ws.kraken.com/v2"
    static let maxCandles = 200

    static let bullishColor = Color.green
    static let bearishColor = Color.red
    static let volumeOpacity: Double = 0.3
    static let backgroundColor = Color(nsColor: .controlBackgroundColor)

    static let defaultPairs: [TradingPair] = [
        TradingPair(symbol: "BTC/USD", restPair: "XBTUSD", baseAsset: "BTC", quoteAsset: "USD"),
        TradingPair(symbol: "ETH/USD", restPair: "ETHUSD", baseAsset: "ETH", quoteAsset: "USD"),
        TradingPair(symbol: "SOL/USD", restPair: "SOLUSD", baseAsset: "SOL", quoteAsset: "USD"),
        TradingPair(symbol: "XRP/USD", restPair: "XRPUSD", baseAsset: "XRP", quoteAsset: "USD"),
        TradingPair(symbol: "ADA/USD", restPair: "ADAUSD", baseAsset: "ADA", quoteAsset: "USD"),
        TradingPair(symbol: "DOGE/USD", restPair: "DOGEUSD", baseAsset: "DOGE", quoteAsset: "USD"),
        TradingPair(symbol: "AVAX/USD", restPair: "AVAXUSD", baseAsset: "AVAX", quoteAsset: "USD"),
        TradingPair(symbol: "DOT/USD", restPair: "DOTUSD", baseAsset: "DOT", quoteAsset: "USD"),
    ]
}
