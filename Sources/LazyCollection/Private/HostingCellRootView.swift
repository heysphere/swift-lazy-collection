import SwiftUI

internal struct HostingCellRootView<ItemContent: View>: View {
  var content: ItemContent?
  var isSelected: Bool = false
  var isHighlighted: Bool = false
  var deselectCell: () -> Void = {}

  var cellState: CellState {
    isSelected ? .selected : (isHighlighted ? .highlighted : .normal)
  }

  @ViewBuilder
  var body: some View {
    if let content = content {
      content
        .buttonStyle(CellButtonStyle())
        .environment(\.cellState, cellState)
        .environment(\.deselectCell, deselectCell)
    }
  }

  private struct CellButtonStyle: PrimitiveButtonStyle {
    @Environment(\.cellState) var cellState
    @Environment(\.deselectCell) var deselectCell

    func makeBody(configuration: Configuration) -> some View {
      configuration.label
        .onValueChanged(cellState) { state in
          if state == .selected {
            configuration.trigger()
            deselectCell()
          }
        }
    }
  }
}
