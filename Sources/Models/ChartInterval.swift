import Foundation

enum ChartInterval: String, Codable, CaseIterable, Identifiable {
    case oneMinute = "1m"
    case fiveMinutes = "5m"
    case fifteenMinutes = "15m"
    case oneHour = "1h"
    case fourHours = "4h"
    case oneDay = "1d"

    var id: String { rawValue }
    var displayName: String { rawValue }
}
