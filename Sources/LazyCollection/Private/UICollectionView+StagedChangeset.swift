import DifferenceKit
import UIKit

extension UICollectionView {
  internal func reloadWithSilentCellUpdate<C: Collection>(
    _ changeset: StagedChangeset<C>,
    updateCell: (UICollectionViewCell, C.Element.Collection.Element) -> Void,
    setData: @escaping (C) -> Void
  ) where C.Element: DifferentiableSection {
    guard window != nil else {
      if let data = changeset.last?.data {
        setData(data)
      }

      reloadData()
      return
    }

    for changeset in changeset {
      performBatchUpdates({
        setData(changeset.data)

        if !changeset.sectionDeleted.isEmpty {
          deleteSections(IndexSet(changeset.sectionDeleted))
        }

        if !changeset.sectionInserted.isEmpty {
          insertSections(IndexSet(changeset.sectionInserted))
        }

        if !changeset.sectionUpdated.isEmpty {
          reloadSections(IndexSet(changeset.sectionUpdated))
        }

        for (source, target) in changeset.sectionMoved {
          moveSection(source, toSection: target)
        }

        if !changeset.elementDeleted.isEmpty {
          deleteItems(at: changeset.elementDeleted.map { IndexPath(item: $0.element, section: $0.section) })
        }

        if !changeset.elementInserted.isEmpty {
          insertItems(at: changeset.elementInserted.map { IndexPath(item: $0.element, section: $0.section) })
        }

        if !changeset.elementUpdated.isEmpty {
          // For all visible cells that have updated model, apply changes to the cells directly using the provided
          // `updateCell` closure.
          //
          // The rest of the invisible index paths can be safety ignored, because their sizes would either:
          // 1. be lazily computed as they go on screen (UICollectionViewLayout self-sizing via preferred layout
          //    attributes); or
          // 2. be computed by the handler in `collectionViewLayout(_:sizeForItemAt:)` (if implemented) using the model.
          //
          // TODO: Supplementary view is not dealt with, as that requires tighter integration of diff application &
          //       data source.

          let updatedIndexPaths = Set(
            changeset.elementUpdated.lazy
              .map { IndexPath(item: $0.element, section: $0.section) }
          )

          self.indexPathsForVisibleItems
            .filter(updatedIndexPaths.contains)
            .map { ($0, cellForItem(at: $0)!) }
            .forEach { indexPath, cell in
              let sectionIndex = changeset.data.index(changeset.data.startIndex, offsetBy: indexPath.section)
              let section = changeset.data[sectionIndex].elements
              let elementIndex = section.index(section.startIndex, offsetBy: indexPath.item)
              updateCell(cell, section[elementIndex])
            }

          let invalidationContextType = type(of: collectionViewLayout).invalidationContextClass as! UICollectionViewLayoutInvalidationContext.Type
          let invalidationContext = invalidationContextType.init()
          invalidationContext.invalidateItems(at: Array(updatedIndexPaths))
          collectionViewLayout.invalidateLayout(with: invalidationContext)
        }

        for (source, target) in changeset.elementMoved {
          // CollectionView in iOS 14.0 is once again not happy with moves being mixed with other changes.
          deleteItems(at: [IndexPath(item: source.element, section: source.section)])
          insertItems(at: [IndexPath(item: target.element, section: target.section)])
        }
      })
    }
  }
}
