import Foundation

enum ChartInterval: Int, Codable, CaseIterable, Identifiable {
    case oneMinute = 1
    case fiveMinutes = 5
    case fifteenMinutes = 15
    case oneHour = 60
    case fourHours = 240
    case oneDay = 1440

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .oneMinute: return "1m"
        case .fiveMinutes: return "5m"
        case .fifteenMinutes: return "15m"
        case .oneHour: return "1h"
        case .fourHours: return "4h"
        case .oneDay: return "1d"
        }
    }
}
