import SwiftUI

public enum CellState {
  case normal
  case highlighted
  case selected
}

extension EnvironmentValues {
  public var cellState: CellState {
    get { self[CellStateKey.self] }
    set { self[CellStateKey.self] = newValue }
  }

  public var deselectCell: () -> Void {
    get { self[DeselectCellKey.self] }
    set { self[DeselectCellKey.self] = newValue }
  }
}

private struct DeselectCellKey: EnvironmentKey {
  static var defaultValue: () -> Void = {}
}

private struct CellStateKey: EnvironmentKey {
  static var defaultValue: CellState = .normal
}
