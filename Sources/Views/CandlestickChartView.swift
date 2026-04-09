import SwiftUI

struct CandlestickChartView: View {
    let candles: [Candle]

    private let priceAreaRatio: CGFloat = 0.78
    private let volumeAreaRatio: CGFloat = 0.18
    private let gapRatio: CGFloat = 0.04
    private let priceLabelWidth: CGFloat = 70

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                guard !candles.isEmpty else { return }
                drawChart(context: context, size: size)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private func drawChart(context: GraphicsContext, size: CGSize) {
        let chartWidth = size.width - priceLabelWidth
        let priceAreaHeight = size.height * priceAreaRatio
        let volumeAreaTop = size.height * (priceAreaRatio + gapRatio)
        let volumeAreaHeight = size.height * volumeAreaRatio

        guard candles.count > 0, chartWidth > 0 else { return }

        let candleStep = chartWidth / CGFloat(candles.count)
        let bodyWidth = max(1, candleStep * 0.6)

        // Price range
        let allHighs = candles.map(\.high)
        let allLows = candles.map(\.low)
        let maxPrice = allHighs.max()!
        let minPrice = allLows.min()!
        let pricePadding = (maxPrice - minPrice) * 0.05
        let priceTop = maxPrice + pricePadding
        let priceBottom = minPrice - pricePadding
        let priceRange = priceTop - priceBottom

        // Volume range
        let maxVolume = candles.map(\.volume).max() ?? 1

        // Helper: price -> Y
        func priceY(_ price: Double) -> CGFloat {
            guard priceRange > 0 else { return priceAreaHeight / 2 }
            return CGFloat((priceTop - price) / priceRange) * priceAreaHeight
        }

        // Draw grid lines
        let gridLineCount = 5
        for i in 0...gridLineCount {
            let y = priceAreaHeight * CGFloat(i) / CGFloat(gridLineCount)
            let price = priceTop - (priceRange * Double(i) / Double(gridLineCount))
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: chartWidth, y: y))
            context.stroke(path, with: .color(.gray.opacity(0.2)), lineWidth: 0.5)

            // Price label
            let labelText = formatPrice(price)
            context.draw(
                Text(labelText).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary),
                at: CGPoint(x: chartWidth + priceLabelWidth / 2, y: y),
                anchor: .center
            )
        }

        // Draw candles
        for (index, candle) in candles.enumerated() {
            let x = CGFloat(index) * candleStep + candleStep / 2
            let color: Color = candle.isBullish ? Constants.bullishColor : Constants.bearishColor

            // Wick
            let wickTop = priceY(candle.high)
            let wickBottom = priceY(candle.low)
            var wickPath = Path()
            wickPath.move(to: CGPoint(x: x, y: wickTop))
            wickPath.addLine(to: CGPoint(x: x, y: wickBottom))
            context.stroke(wickPath, with: .color(color), lineWidth: 1)

            // Body
            let bodyTop = priceY(max(candle.open, candle.close))
            let bodyBottom = priceY(min(candle.open, candle.close))
            let bodyHeight = max(1, bodyBottom - bodyTop)
            let bodyRect = CGRect(
                x: x - bodyWidth / 2,
                y: bodyTop,
                width: bodyWidth,
                height: bodyHeight
            )
            context.fill(Path(bodyRect), with: .color(color))

            // Volume bar
            let volHeight = maxVolume > 0
                ? CGFloat(candle.volume / maxVolume) * volumeAreaHeight
                : 0
            let volRect = CGRect(
                x: x - bodyWidth / 2,
                y: volumeAreaTop + volumeAreaHeight - volHeight,
                width: bodyWidth,
                height: volHeight
            )
            context.fill(Path(volRect), with: .color(color.opacity(Constants.volumeOpacity)))
        }

        // Current price line
        if let lastCandle = candles.last {
            let y = priceY(lastCandle.close)
            var priceLine = Path()
            priceLine.move(to: CGPoint(x: 0, y: y))
            priceLine.addLine(to: CGPoint(x: chartWidth, y: y))
            context.stroke(
                priceLine,
                with: .color(lastCandle.isBullish ? Constants.bullishColor : Constants.bearishColor),
                style: StrokeStyle(lineWidth: 0.5, dash: [4, 2])
            )

            // Current price label
            let priceLabel = formatPrice(lastCandle.close)
            let labelColor: Color = lastCandle.isBullish ? Constants.bullishColor : Constants.bearishColor
            context.draw(
                Text(priceLabel).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(labelColor),
                at: CGPoint(x: chartWidth + priceLabelWidth / 2, y: y),
                anchor: .center
            )
        }
    }

    private func formatPrice(_ price: Double) -> String {
        if price >= 1000 {
            return String(format: "%.1f", price)
        } else if price >= 1 {
            return String(format: "%.2f", price)
        } else if price >= 0.01 {
            return String(format: "%.4f", price)
        } else {
            return String(format: "%.6f", price)
        }
    }
}
