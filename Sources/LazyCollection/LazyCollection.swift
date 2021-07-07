import SwiftUI
import UIKit
import DifferenceKit

public struct LazyCollection<Data: RandomAccessCollection, ItemContent: View>: View where Data.Element: Identifiable, Data.Element: Equatable {
  public let data: Data
  public let transform: (Data.Element) -> ItemContent

  let layout: () -> UICollectionViewLayout
  var contentInsets: EdgeInsets
  var selection: Binding<Data.Element.ID?>? = nil

  public var body: some View {
    Core(data: data, transform: transform, layout: layout, contentInsets: contentInsets, selection: selection)
      .ignoreSafeArea()
  }

  public init(
    _ data: Data,
    selection: Binding<Data.Element.ID?>? = nil,
    @ViewBuilder transform: @escaping (Data.Element) -> ItemContent,
    layout: @escaping () -> UICollectionViewLayout,
    contentInsets: EdgeInsets = EdgeInsets()
  ) {
    self.data = data
    self.selection = selection
    self.transform = transform
    self.layout = layout
    self.contentInsets = contentInsets
  }

  public func contentInsets(_ insets: EdgeInsets) -> Self {
    var copy = self
    copy.contentInsets = insets
    return copy
  }

  private struct Core: UIViewControllerRepresentable {
    typealias Context = UIViewControllerRepresentableContext<Self>
    typealias UIViewControllerType = SwiftUICollectionViewController<Data, ItemContent>

    let data: Data
    let transform: (Data.Element) -> ItemContent
    let layout: () -> UICollectionViewLayout
    var contentInsets: EdgeInsets
    var selection: Binding<Data.Element.ID?>? = nil

    private var uiKitInsets: UIEdgeInsets {
      UIEdgeInsets(top: contentInsets.top, left: contentInsets.leading, bottom: contentInsets.bottom, right: contentInsets.trailing)
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
      let viewController = UIViewControllerType(layout: layout(), initial: data, transform: transform)
      applyExtraAttributes(viewController)
      return viewController
    }

    func updateUIViewController(_ viewController: UIViewControllerType, context: Context) {
      viewController.apply(data, transaction: context.transaction)
      applyExtraAttributes(viewController)
    }

    private func applyExtraAttributes(_ viewController: UIViewControllerType) {
      applyIfChanged(viewController, \.collectionView.contentInset, uiKitInsets)
      viewController.selectionBinding = selection
    }
  }
}

private func applyIfChanged<Root: AnyObject, Value: Equatable>(_ root: Root, _ keyPath: ReferenceWritableKeyPath<Root, Value>, _ value: Value) {
  if root[keyPath: keyPath] != value {
    root[keyPath: keyPath] = value
  }
}
