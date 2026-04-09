import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 8),
            count: viewModel.layout.columns
        )

        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.panels) { panel in
                    ChartPanelView(
                        viewModel: panel,
                        allPairs: viewModel.allPairs,
                        onAddCustomPair: { symbol in
                            viewModel.addCustomPair(symbol: symbol)
                        }
                    )
                    .frame(minHeight: 300)
                }
            }
            .padding(8)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                LayoutSelectorView(layout: $viewModel.layout)
            }
        }
        .onAppear {
            viewModel.startAll()
        }
        .onDisappear {
            viewModel.stopAll()
        }
    }
}
