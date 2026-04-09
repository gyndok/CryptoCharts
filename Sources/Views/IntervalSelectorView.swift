import SwiftUI

struct IntervalSelectorView: View {
    @Binding var selectedInterval: ChartInterval

    var body: some View {
        HStack(spacing: 2) {
            ForEach(ChartInterval.allCases) { interval in
                Button(interval.displayName) {
                    selectedInterval = interval
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: selectedInterval == interval ? .bold : .regular, design: .monospaced))
                .foregroundStyle(selectedInterval == interval ? .primary : .secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(selectedInterval == interval ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(4)
            }
        }
    }
}
