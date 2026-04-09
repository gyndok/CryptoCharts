import Foundation
import SwiftUI

@MainActor
final class ChartPanelViewModel: ObservableObject, Identifiable {
    let id: UUID
    @Published var pair: TradingPair
    @Published var interval: ChartInterval
    @Published var candles: [Candle] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isConnected = false

    private var webSocket = KrakenWebSocket()
    private var streamTask: Task<Void, Never>?

    var onConfigChanged: (() -> Void)?

    init(config: PanelConfig) {
        self.id = config.id
        self.pair = config.pair
        self.interval = config.interval
    }

    var config: PanelConfig {
        PanelConfig(id: id, pair: pair, interval: interval)
    }

    func start() {
        stop()
        isLoading = true
        error = nil

        streamTask = Task {
            // Fetch history
            do {
                let historical = try await KrakenAPI.fetchOHLC(
                    pair: pair.restPair,
                    interval: interval.rawValue,
                    limit: Constants.maxCandles
                )
                self.candles = historical
                self.isLoading = false
            } catch {
                self.error = error.localizedDescription
                self.isLoading = false
                return
            }

            // Subscribe to live updates
            let stream = await webSocket.connect(
                symbol: pair.symbol,
                interval: interval.rawValue
            )
            self.isConnected = true

            for await candle in stream {
                self.updateCandle(candle)
            }

            self.isConnected = false
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        Task { await webSocket.disconnect() }
        isConnected = false
    }

    func changePair(_ newPair: TradingPair) {
        guard newPair != pair else { return }
        pair = newPair
        onConfigChanged?()
        start()
    }

    func changeInterval(_ newInterval: ChartInterval) {
        guard newInterval != interval else { return }
        interval = newInterval
        onConfigChanged?()
        start()
    }

    private func updateCandle(_ incoming: Candle) {
        if let lastIndex = candles.indices.last,
           candles[lastIndex].openTime == incoming.openTime {
            // Update existing candle in place
            candles[lastIndex].high = incoming.high
            candles[lastIndex].low = incoming.low
            candles[lastIndex].close = incoming.close
            candles[lastIndex].volume = incoming.volume
            candles[lastIndex].isClosed = incoming.isClosed
        } else {
            // New candle
            candles.append(incoming)
            if candles.count > Constants.maxCandles {
                candles.removeFirst(candles.count - Constants.maxCandles)
            }
        }
    }
}
