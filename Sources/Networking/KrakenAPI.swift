import Foundation

enum KrakenAPI {
    enum APIError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case decodingError(String)
        case httpError(Int)
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .invalidResponse: return "Invalid response"
            case .decodingError(let msg): return "Decoding error: \(msg)"
            case .httpError(let code): return "HTTP error: \(code)"
            case .apiError(let msg): return "API error: \(msg)"
            }
        }
    }

    /// Fetch OHLC candles from Kraken REST API
    /// Kraken returns: [[timestamp, open, high, low, close, vwap, volume, count], ...]
    static func fetchOHLC(pair: String, interval: Int, limit: Int = 200) async throws -> [Candle] {
        // Kraken doesn't have a limit param — it returns up to 720 candles.
        // We use `since` to control how far back we go.
        let secondsPerCandle = interval * 60
        let since = Int(Date().timeIntervalSince1970) - (limit * secondsPerCandle)

        guard let url = URL(string: "\(Constants.restBaseURL)/0/public/OHLC?pair=\(pair)&interval=\(interval)&since=\(since)") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.decodingError("Expected JSON object")
        }

        // Check for errors
        if let errors = json["error"] as? [String], !errors.isEmpty {
            throw APIError.apiError(errors.joined(separator: ", "))
        }

        guard let result = json["result"] as? [String: Any] else {
            throw APIError.decodingError("Missing result")
        }

        // The result key is the pair name (which Kraken may alter, e.g. XXBTZUSD)
        // Find the first key that isn't "last"
        guard let pairKey = result.keys.first(where: { $0 != "last" }),
              let candles = result[pairKey] as? [[Any]] else {
            throw APIError.decodingError("No candle data found")
        }

        let parsed = candles.compactMap { parseOHLCArray($0, intervalMinutes: interval) }

        // Return only the last `limit` candles
        if parsed.count > limit {
            return Array(parsed.suffix(limit))
        }
        return parsed
    }

    /// Kraken OHLC array: [timestamp, open, high, low, close, vwap, volume, count]
    /// All price values are strings, timestamp is an integer (seconds)
    private static func parseOHLCArray(_ arr: [Any], intervalMinutes: Int) -> Candle? {
        guard arr.count >= 8 else { return nil }

        guard let timestamp = arr[0] as? Int ?? (arr[0] as? Double).map(Int.init),
              let openStr = arr[1] as? String, let open = Double(openStr),
              let highStr = arr[2] as? String, let high = Double(highStr),
              let lowStr = arr[3] as? String, let low = Double(lowStr),
              let closeStr = arr[4] as? String, let close = Double(closeStr),
              let volStr = arr[6] as? String, let volume = Double(volStr)
        else { return nil }

        let openTime = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let closeTime = openTime.addingTimeInterval(TimeInterval(intervalMinutes * 60))

        return Candle(
            openTime: openTime,
            open: open,
            high: high,
            low: low,
            close: close,
            volume: volume,
            closeTime: closeTime,
            isClosed: true
        )
    }
}
