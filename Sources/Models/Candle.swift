import Foundation

struct Candle: Identifiable {
    let id: UUID
    let openTime: Date
    var open: Double
    var high: Double
    var low: Double
    var close: Double
    var volume: Double
    let closeTime: Date
    var isClosed: Bool

    var isBullish: Bool { close >= open }

    init(
        id: UUID = UUID(),
        openTime: Date,
        open: Double,
        high: Double,
        low: Double,
        close: Double,
        volume: Double,
        closeTime: Date,
        isClosed: Bool = true
    ) {
        self.id = id
        self.openTime = openTime
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.closeTime = closeTime
        self.isClosed = isClosed
    }
}
