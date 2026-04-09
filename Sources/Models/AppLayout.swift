import Foundation

enum GridLayout: String, Codable, CaseIterable, Identifiable {
    case oneByTwo = "1x2"
    case twoByOne = "2x1"
    case twoByTwo = "2x2"
    case threeByOne = "3x1"
    case fourByOne = "4x1"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var columns: Int {
        switch self {
        case .oneByTwo: return 1
        case .twoByOne: return 2
        case .twoByTwo: return 2
        case .threeByOne: return 3
        case .fourByOne: return 4
        }
    }

    var rows: Int {
        switch self {
        case .oneByTwo: return 2
        case .twoByOne: return 1
        case .twoByTwo: return 2
        case .threeByOne: return 1
        case .fourByOne: return 1
        }
    }

    var panelCount: Int { columns * rows }
}

struct AppSettings: Codable {
    var layout: GridLayout
    var panels: [PanelConfig]
    var customPairs: [TradingPair]

    static let defaultSettings = AppSettings(
        layout: .twoByTwo,
        panels: [
            PanelConfig(pair: Constants.defaultPairs[0]),
            PanelConfig(pair: Constants.defaultPairs[1]),
            PanelConfig(pair: Constants.defaultPairs[2]),
            PanelConfig(pair: Constants.defaultPairs[3])
        ],
        customPairs: []
    )

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: "appSettings"),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .defaultSettings
        }
        return settings
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "appSettings")
        }
    }
}
