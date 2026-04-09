import Foundation

actor BinanceWebSocket {
    private var task: URLSessionWebSocketTask?
    private var continuation: AsyncStream<Candle>.Continuation?
    private var isConnected = false
    private var shouldReconnect = false
    private var currentSymbol: String?
    private var currentInterval: String?
    private var reconnectDelay: TimeInterval = 3

    func connect(symbol: String, interval: String) -> AsyncStream<Candle> {
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
              let url = URL(string: "\(Constants.wsBaseURL)/\(symbol)@kline_\(interval)") else {
            return
        }

        let session = URLSession(configuration: .default)
        let wsTask = session.webSocketTask(with: url)
        self.task = wsTask
        wsTask.resume()
        isConnected = true

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
                        if let candle = parseKlineMessage(text) {
                            continuation?.yield(candle)
                        }
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8),
                           let candle = parseKlineMessage(text) {
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

    private func parseKlineMessage(_ text: String) -> Candle? {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let k = json["k"] as? [String: Any] else {
            return nil
        }

        guard let openTimeMs = k["t"] as? Double,
              let openStr = k["o"] as? String, let open = Double(openStr),
              let highStr = k["h"] as? String, let high = Double(highStr),
              let lowStr = k["l"] as? String, let low = Double(lowStr),
              let closeStr = k["c"] as? String, let close = Double(closeStr),
              let volStr = k["v"] as? String, let volume = Double(volStr),
              let closeTimeMs = k["T"] as? Double,
              let isClosed = k["x"] as? Bool else {
            return nil
        }

        return Candle(
            openTime: Date(timeIntervalSince1970: openTimeMs / 1000),
            open: open,
            high: high,
            low: low,
            close: close,
            volume: volume,
            closeTime: Date(timeIntervalSince1970: closeTimeMs / 1000),
            isClosed: isClosed
        )
    }
}
