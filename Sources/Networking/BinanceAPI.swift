import Foundation

enum BinanceAPI {
    enum APIError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case decodingError(String)
        case httpError(Int)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .invalidResponse: return "Invalid response"
            case .decodingError(let msg): return "Decoding error: \(msg)"
            case .httpError(let code): return "HTTP error: \(code)"
            }
        }
    }

    static func fetchKlines(symbol: String, interval: String, limit: Int = 200) async throws -> [Candle] {
        guard let url = URL(string: "\(Constants.restBaseURL)/api/v3/klines?symbol=\(symbol)&interval=\(interval)&limit=\(limit)") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[Any]] else {
            throw APIError.decodingError("Expected array of arrays")
        }

        return jsonArray.compactMap { parseKlineArray($0) }
    }

    private static func parseKlineArray(_ arr: [Any]) -> Candle? {
        guard arr.count >= 11 else { return nil }

        guard let openTimeMs = arr[0] as? Double ?? (arr[0] as? Int).map(Double.init),
              let openStr = arr[1] as? String, let open = Double(openStr),
              let highStr = arr[2] as? String, let high = Double(highStr),
              let lowStr = arr[3] as? String, let low = Double(lowStr),
              let closeStr = arr[4] as? String, let close = Double(closeStr),
              let volStr = arr[5] as? String, let volume = Double(volStr),
              let closeTimeMs = arr[6] as? Double ?? (arr[6] as? Int).map(Double.init)
        else { return nil }

        return Candle(
            openTime: Date(timeIntervalSince1970: openTimeMs / 1000),
            open: open,
            high: high,
            low: low,
            close: close,
            volume: volume,
            closeTime: Date(timeIntervalSince1970: closeTimeMs / 1000),
            isClosed: true
        )
    }
}
