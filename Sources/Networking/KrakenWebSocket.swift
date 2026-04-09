import Foundation
import os

private let logger = Logger(subsystem: "com.cryptocharts", category: "WebSocket")

actor KrakenWebSocket {
    private var session: URLSession?
    private var task: URLSessionWebSocketTask?
    private var continuation: AsyncStream<Candle>.Continuation?
    private var isConnected = false
    private var shouldReconnect = false
    private var currentSymbol: String?
    private var currentInterval: Int?
    private var reconnectDelay: TimeInterval = 3

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

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
        session?.invalidateAndCancel()
        session = nil
        continuation?.finish()
        continuation = nil
    }

    private func establishConnection() {
        guard let symbol = currentSymbol,
              let interval = currentInterval,
              let url = URL(string: Constants.wsURL) else {
            return
        }

        let urlSession = URLSession(configuration: .default)
        self.session = urlSession
        let wsTask = urlSession.webSocketTask(with: url)
        self.task = wsTask
        wsTask.resume()

        // Subscribe to OHLC channel — connection confirmed by first successful send
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
            wsTask.send(.string(text)) { [weak self] error in
                Task {
                    guard let self else { return }
                    if let error {
                        logger.error("WebSocket subscribe send failed: \(error.localizedDescription)")
                        await self.handleConnectionFailure()
                    } else {
                        await self.markConnected()
                    }
                }
            }
        }

        Task { receiveLoop() }
    }

    private func markConnected() {
        isConnected = true
        reconnectDelay = 3
        logger.info("WebSocket connected for \(self.currentSymbol ?? "unknown")")
    }

    private func handleConnectionFailure() {
        isConnected = false
        guard shouldReconnect else { return }
        Task {
            do {
                try await Task.sleep(for: .seconds(reconnectDelay))
                reconnectDelay = min(reconnectDelay * 2, 30)
                if shouldReconnect {
                    establishConnection()
                }
            } catch {
                // Task cancelled — stop reconnecting
            }
        }
    }

    private func receiveLoop() {
        guard let task = task else { return }

        Task {
            do {
                while shouldReconnect {
                    let message = try await task.receive()
                    if !isConnected {
                        markConnected()
                    }
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
            } catch is CancellationError {
                return
            } catch {
                logger.warning("WebSocket receive error: \(error.localizedDescription)")
                guard shouldReconnect else { return }
                isConnected = false
                do {
                    try await Task.sleep(for: .seconds(reconnectDelay))
                    reconnectDelay = min(reconnectDelay * 2, 30)
                    if shouldReconnect {
                        establishConnection()
                    }
                } catch {
                    // Task cancelled during reconnect delay — stop
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

        guard let openTime = Self.dateFormatter.date(from: intervalBegin) else { return nil }

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
