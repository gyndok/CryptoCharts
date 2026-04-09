import Foundation

actor KrakenWebSocket {
    private var task: URLSessionWebSocketTask?
    private var continuation: AsyncStream<Candle>.Continuation?
    private var isConnected = false
    private var shouldReconnect = false
    private var currentSymbol: String?
    private var currentInterval: Int?
    private var reconnectDelay: TimeInterval = 3

    func connect(symbol: String, interval: Int) -> AsyncStream<Candle> {
        disconnect()
        currentSymbol = symbol
        currentInterval = interval
        shouldReconnect = true
        reconnectDelay = 3

        return AsyncStream { continuation in
            self.continuation = continuation
            continuation.onTermination = { @Sendable _ in
                Task { await self.disconnect() }
            }
            Task { self.establishConnection() }
        }
    }

    func disconnect() {
        shouldReconnect = false
        isConnected = false
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        continuation?.finish()
        continuation = nil
    }

    private func establishConnection() {
        guard let symbol = currentSymbol,
              let interval = currentInterval,
              let url = URL(string: Constants.wsURL) else {
            return
        }

        let session = URLSession(configuration: .default)
        let wsTask = session.webSocketTask(with: url)
        self.task = wsTask
        wsTask.resume()
        isConnected = true

        // Subscribe to OHLC channel after connection
        let subscribeMsg: [String: Any] = [
            "method": "subscribe",
            "params": [
                "channel": "ohlc",
                "symbol": [symbol],
                "interval": interval
            ] as [String: Any]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: subscribeMsg),
           let text = String(data: data, encoding: .utf8) {
            wsTask.send(.string(text)) { _ in }
        }

        Task { receiveLoop() }
    }

    private func receiveLoop() {
        guard let task = task else { return }

        Task {
            do {
                while isConnected {
                    let message = try await task.receive()
                    switch message {
                    case .string(let text):
                        if let candle = parseOHLCMessage(text) {
                            continuation?.yield(candle)
                        }
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8),
                           let candle = parseOHLCMessage(text) {
                            continuation?.yield(candle)
                        }
                    @unknown default:
                        break
                    }
                }
            } catch {
                guard shouldReconnect else { return }
                isConnected = false
                try? await Task.sleep(for: .seconds(reconnectDelay))
                reconnectDelay = min(reconnectDelay * 2, 30)
                if shouldReconnect {
                    establishConnection()
                }
            }
        }
    }

    /// Kraken WS v2 OHLC message format:
    /// {"channel":"ohlc","type":"update","data":[{
    ///   "symbol":"BTC/USD","open":71037.4,"high":71116.3,"low":70964.7,
    ///   "close":70988.4,"volume":14.02,"interval_begin":"2026-04-09T07:00:00.000000000Z",
    ///   "interval":60,"timestamp":"2026-04-09T08:00:00.000000Z"
    /// }]}
    private func parseOHLCMessage(_ text: String) -> Candle? {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let channel = json["channel"] as? String,
              channel == "ohlc",
              let dataArray = json["data"] as? [[String: Any]],
              let ohlc = dataArray.first else {
            return nil
        }

        guard let open = ohlc["open"] as? Double,
              let high = ohlc["high"] as? Double,
              let low = ohlc["low"] as? Double,
              let close = ohlc["close"] as? Double,
              let volume = ohlc["volume"] as? Double,
              let intervalBegin = ohlc["interval_begin"] as? String,
              let interval = ohlc["interval"] as? Int else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let openTime = formatter.date(from: intervalBegin) else { return nil }

        let closeTime = openTime.addingTimeInterval(TimeInterval(interval * 60))
        let msgType = json["type"] as? String ?? "update"

        return Candle(
            openTime: openTime,
            open: open,
            high: high,
            low: low,
            close: close,
            volume: volume,
            closeTime: closeTime,
            isClosed: msgType == "snapshot"
        )
    }
}
