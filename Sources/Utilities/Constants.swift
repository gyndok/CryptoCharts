import SwiftUI

enum Constants {
    static let restBaseURL = "https://api.binance.us"
    static let wsBaseURL = "wss://stream.binance.us:9443/ws"
    static let maxCandles = 200

    static let bullishColor = Color.green
    static let bearishColor = Color.red
    static let volumeOpacity: Double = 0.3
    static let backgroundColor = Color(nsColor: .controlBackgroundColor)

    static let defaultPairs: [TradingPair] = [
        TradingPair(symbol: "BTCUSDT", baseAsset: "BTC", quoteAsset: "USDT"),
        TradingPair(symbol: "ETHUSDT", baseAsset: "ETH", quoteAsset: "USDT"),
        TradingPair(symbol: "SOLUSDT", baseAsset: "SOL", quoteAsset: "USDT"),
        TradingPair(symbol: "BNBUSDT", baseAsset: "BNB", quoteAsset: "USDT"),
        TradingPair(symbol: "XRPUSDT", baseAsset: "XRP", quoteAsset: "USDT"),
        TradingPair(symbol: "ADAUSDT", baseAsset: "ADA", quoteAsset: "USDT"),
        TradingPair(symbol: "DOGEUSDT", baseAsset: "DOGE", quoteAsset: "USDT"),
        TradingPair(symbol: "AVAXUSDT", baseAsset: "AVAX", quoteAsset: "USDT"),
    ]
}
