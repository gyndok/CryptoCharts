import Foundation

struct Candle: Identifiable, Equatable {
    var id: Date { openTime }
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
        openTime: Date,
        open: Double,
        high: Double,
        low: Double,
        close: Double,
        volume: Double,
        closeTime: Date,
        isClosed: Bool = true
    ) {
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
