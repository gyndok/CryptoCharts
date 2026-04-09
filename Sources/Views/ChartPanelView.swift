import SwiftUI

struct ChartPanelView: View {
    @ObservedObject var viewModel: ChartPanelViewModel
    let allPairs: [TradingPair]
    var onAddCustomPair: ((String) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                PairSelectorView(
                    selectedPair: Binding(
                        get: { viewModel.pair },
                        set: { viewModel.changePair($0) }
                    ),
                    allPairs: allPairs,
                    onAddCustom: onAddCustomPair
                )

                IntervalSelectorView(
                    selectedInterval: Binding(
                        get: { viewModel.interval },
                        set: { viewModel.changeInterval($0) }
                    )
                )

                Spacer()

                // Status indicator
                statusView
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Chart area
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Retry") { viewModel.start() }
                            .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    CandlestickChartView(candles: viewModel.candles)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var statusView: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(viewModel.isConnected ? Color.green : Color.orange)
                .frame(width: 6, height: 6)

            if let lastCandle = viewModel.candles.last {
                Text(formatPrice(lastCandle.close))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(lastCandle.isBullish ? Constants.bullishColor : Constants.bearishColor)
            }
        }
    }

    private func formatPrice(_ price: Double) -> String {
        if price >= 1000 {
            return String(format: "$%.1f", price)
        } else if price >= 1 {
            return String(format: "$%.2f", price)
        } else {
            return String(format: "$%.4f", price)
        }
    }
}
