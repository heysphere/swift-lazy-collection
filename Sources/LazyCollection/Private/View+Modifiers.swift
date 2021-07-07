import SwiftUI
import Combine

extension View {
  @ViewBuilder
  internal func ignoreSafeArea() -> some View {
    if #available(iOS 14.0, *) {
      ignoresSafeArea(.all, edges: .all)
    } else {
      edgesIgnoringSafeArea(.all)
    }
  }

  /// iOS 13 usable version of `onChange(of:perform:)`.
  @ViewBuilder
  internal func onValueChanged<Value: Equatable>(_ value: Value, perform action: @escaping (Value) -> Void) -> some View {
    if #available(iOS 14.0, *) {
      onChange(of: value, perform: action)
    } else {
      modifier(OnChangeModifier(value: value, action: action))
    }
  }
}

private struct OnChangeModifier<Value: Equatable>: ViewModifier {
  let value: Value
  let action: (Value) -> Void

  @State var lastRecord: Value? = nil

  func body(content: Content) -> some View {
    return content
      .onAppear()
      .onReceive(Just(value)) { value in
        if value != lastRecord {
          action(value)
          self.lastRecord = value
        }
      }
  }
}
