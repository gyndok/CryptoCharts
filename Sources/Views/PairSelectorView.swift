import SwiftUI

struct PairSelectorView: View {
    @Binding var selectedPair: TradingPair
    let allPairs: [TradingPair]
    var onAddCustom: ((String) -> Void)?

    @State private var customSymbol = ""
    @State private var showingCustomInput = false

    var body: some View {
        Menu {
            ForEach(allPairs) { pair in
                Button(pair.displayName) {
                    selectedPair = pair
                }
            }
            Divider()
            Button("Add Custom Pair...") {
                showingCustomInput = true
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedPair.displayName)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingCustomInput) {
            VStack(spacing: 12) {
                Text("Custom Trading Pair")
                    .font(.headline)
                TextField("e.g. PEPEUSDT", text: $customSymbol)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .onSubmit { addCustom() }
                HStack {
                    Button("Cancel") { showingCustomInput = false }
                    Button("Add") { addCustom() }
                        .buttonStyle(.borderedProminent)
                        .disabled(customSymbol.isEmpty)
                }
            }
            .padding()
        }
    }

    private func addCustom() {
        let symbol = customSymbol.trimmingCharacters(in: .whitespaces)
        guard !symbol.isEmpty else { return }
        onAddCustom?(symbol)
        // Find and select the new pair
        if let pair = allPairs.first(where: { $0.symbol == symbol.uppercased() }) {
            selectedPair = pair
        } else {
            // It was just added, construct it
            let upper = symbol.uppercased()
            if upper.hasSuffix("USDT") {
                selectedPair = TradingPair(symbol: upper, baseAsset: String(upper.dropLast(4)), quoteAsset: "USDT")
            } else {
                selectedPair = TradingPair(symbol: upper, baseAsset: upper, quoteAsset: "USDT")
            }
        }
        customSymbol = ""
        showingCustomInput = false
    }
}
