import UIKit
import SwiftUI

internal final class HostingCell<ItemContent: View>: UICollectionViewCell {
  let hostingController = UIHostingController(rootView: HostingCellRootView<ItemContent>(content: nil))

  override var safeAreaInsets: UIEdgeInsets { .zero }

  override var isSelected: Bool {
    didSet {
      hostingController.rootView.isSelected = isSelected
    }
  }

  override var isHighlighted: Bool {
    didSet {
      hostingController.rootView.isHighlighted = isHighlighted
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    hostingController.disableSafeArea()
    contentView.addSubview(hostingController.view)
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false

    contentView.backgroundColor = .clear
    hostingController.view.backgroundColor = .clear
  }

  required init?(coder: NSCoder) { fatalError() }

  override func prepareForReuse() {
    super.prepareForReuse()
    hostingController.rootView.content = nil
  }

  func set(_ item: ItemContent) {
    hostingController.rootView.content = item
  }

  func didDequeue(for viewController: SwiftUICollectionViewControllerProtocol) {
    if hostingController.parent !== viewController {
      assert(hostingController.parent == nil)

      viewController.addChild(hostingController)
      hostingController.didMove(toParent: viewController)

      hostingController.rootView.deselectCell = { [unowned viewController, unowned self] in
        viewController.deselect(self)
      }
    }
  }

  override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)
    hostingController.view.frame = layoutAttributes.bounds
  }

  override func preferredLayoutAttributesFitting(
    _ layoutAttributes: UICollectionViewLayoutAttributes
  ) -> UICollectionViewLayoutAttributes {
    let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
    attributes.frame.size = hostingController.sizeThatFits(in: attributes.frame.size)
    return attributes
  }

  override func systemLayoutSizeFitting(
    _ targetSize: CGSize,
    withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
    verticalFittingPriority: UILayoutPriority
  ) -> CGSize {
    // Skip Auto Layout.
    return targetSize
  }

  deinit {
    hostingController.removeFromParent()
  }
}

extension UIHostingController {
  fileprivate func disableSafeArea() {
    // https://defagos.github.io/swiftui_collection_part3/
    guard let viewClass = object_getClass(view) else { return }

    let viewSubclassName = String(cString: class_getName(viewClass)).appending("_IgnoreSafeArea")
    if let viewSubclass = NSClassFromString(viewSubclassName) {
      object_setClass(view, viewSubclass)
    }
    else {
      guard let viewClassNameUtf8 = (viewSubclassName as NSString).utf8String else { return }
      guard let viewSubclass = objc_allocateClassPair(viewClass, viewClassNameUtf8, 0) else { return }

      if let method = class_getInstanceMethod(UIView.self, #selector(getter: UIView.safeAreaInsets)) {
        let safeAreaInsets: @convention(block) (AnyObject) -> UIEdgeInsets = { _ in
          return .zero
        }
        class_addMethod(viewSubclass, #selector(getter: UIView.safeAreaInsets), imp_implementationWithBlock(safeAreaInsets), method_getTypeEncoding(method))
      }

      objc_registerClassPair(viewSubclass)
      object_setClass(view, viewSubclass)
    }
  }
}
