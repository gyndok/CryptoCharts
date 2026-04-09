import SwiftUI

struct LayoutSelectorView: View {
    @Binding var layout: GridLayout

    var body: some View {
        Picker("Layout", selection: $layout) {
            ForEach(GridLayout.allCases) { gridLayout in
                Text(gridLayout.displayName).tag(gridLayout)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 250)
    }
}
