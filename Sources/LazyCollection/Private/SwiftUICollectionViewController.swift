import SwiftUI
import UIKit
import DifferenceKit

private let reuseIdentifier = "HostingCell"

internal protocol SwiftUICollectionViewControllerProtocol: UIViewController {
  func deselect(_ cell: UICollectionViewCell)
}

internal final class SwiftUICollectionViewController<
  Data: RandomAccessCollection,
  ItemContent: View
>: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, SwiftUICollectionViewControllerProtocol
where Data.Element: Identifiable, Data.Element: Equatable {
  let collectionView: UICollectionView
  var transform: (Data.Element) -> ItemContent
  var current: [SectionWrapper] = []
  var selectionBinding: Binding<Data.Element.ID?>? = nil {
    didSet { updateSelectionIfNecessary() }
  }

  override var shouldAutomaticallyForwardAppearanceMethods: Bool { false }

  init(
    layout: UICollectionViewLayout,
    initial: Data,
    transform: @escaping (Data.Element) -> ItemContent
  ) {
    self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    self.transform = transform

    super.init(nibName: nil, bundle: nil)

    collectionView.register(
      HostingCell<ItemContent>.self,
      forCellWithReuseIdentifier: reuseIdentifier
    )
    collectionView.dataSource = self
    collectionView.delegate = self

    apply(initial, transaction: nil)
  }

  required init?(coder: NSCoder) { fatalError() }

  override func loadView() {
    view = collectionView
    collectionView.backgroundColor = .clear
  }

  func apply(_ new: Data, transaction: Transaction?) {
    let shouldAnimate = (transaction?.disablesAnimations ?? true) == false
    let new = [SectionWrapper(new.map(ElementWrapper.init))]

    if shouldAnimate {
      let changeset = StagedChangeset(source: current, target: new)

      collectionView.reloadWithSilentCellUpdate(
        changeset,
        updateCell: { [transform] cell, item in
          (cell as! HostingCell).set(transform(item.element))
        },
        setData: { self.current = $0 }
      )
    } else {
      current = new
      collectionView.reloadData()
    }
  }

  func deselect(_ cell: UICollectionViewCell) {
    // If we have a selection binding, automatic deselection should be disabled.
    guard selectionBinding == nil else { return }

    guard let indexPath = collectionView.indexPath(for: cell) else { return }
    collectionView.deselectItem(at: indexPath, animated: false)
  }

  private func updateSelectionIfNecessary() {
    guard let binding = selectionBinding else { return }

    let selectedId = binding.wrappedValue
    let collectionViewSelection = (collectionView.indexPathsForSelectedItems?.first)
      .map { current[0].elements[$0.item].differenceIdentifier }

    // Update the collection view state, and in turn all affected visible cells, immediately without any animation.
    // SwiftUI can animate on its own terms in response to this update.
    //
    // Also note that setting `animated: true` might cause the animations on the SwiftUI root view to be stuck somehow.

    if selectedId != collectionViewSelection {
      (collectionView.indexPathsForSelectedItems ?? [])
        .forEach { collectionView.deselectItem(at: $0, animated: false) }

      if let newSelectionIndex = current[0].elements.firstIndex(where: { $0.differenceIdentifier == selectedId }) {
        collectionView.selectItem(
          at: IndexPath(item: newSelectionIndex, section: 0),
          animated: false,
          scrollPosition: .bottom
        )
      }
    }
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    assert(section == 0)
    return current[0].elements.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: reuseIdentifier,
      for: indexPath
    ) as! HostingCell<ItemContent>

    cell.didDequeue(for: self)
    cell.set(transform(current[0].elements[indexPath.item].element))

    return cell
  }

  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    let cell = (cell as! HostingCell<ItemContent>)
    cell.hostingController.beginAppearanceTransition(true, animated: false)
    cell.hostingController.endAppearanceTransition()
  }

  func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    let cell = (cell as! HostingCell<ItemContent>)
    cell.hostingController.beginAppearanceTransition(false, animated: false)
    cell.hostingController.endAppearanceTransition()
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    selectionBinding?.wrappedValue = current[0].elements[indexPath.item].differenceIdentifier
  }

  func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    selectionBinding?.wrappedValue = nil
  }

  struct SectionWrapper: DifferentiableSection {
    var elements: [ElementWrapper]
    var differenceIdentifier: Int8 { 0 }

    init(_ elements: [ElementWrapper]) {
      self.elements = elements
    }

    init<C>(source: SectionWrapper, elements: C) where C : Collection, C.Element == ElementWrapper {
      self.init(Array(elements))
    }

    func isContentEqual(to source: SectionWrapper) -> Bool {
      true
    }
  }

  struct ElementWrapper: Differentiable {
    let element: Data.Element

    var differenceIdentifier: Data.Element.ID {
      element.id
    }

    func isContentEqual(to source: ElementWrapper) -> Bool {
      source.element == element
    }
  }
}
