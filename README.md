# LazyCollection

A minimal SwiftUI lazy container type, that:

* uses `UICollectionView` underneath and supports any self-sizing `UICollectionViewLayout` you throwing at it;
* can be used on iOS 13.0+ and substituted the sometimes wonky `LazyVStack`; and
* does not support sections as is, does not support drag-n-drop, and does not support multiple selections.

There is no commitment to a feature roadmap. Feel free to copy & paste into your own codebase, and evolve/fork it on your own terms.

Sources/Private/Previews.swift contains a SwiftUI Preview showcasing `LazyCollection` in a grid format, powered by `UICollectionViewCompositionalLayout`. One thing worth noting that is also showcased is that `LazyCollection` supports two ways of item selection:

1. a `Data.Element.ID?` binding which you point to a `@State` variable; or

2. using a `SwiftUI.Button` at the root of your `ItemContent` view, akin to the vanilla usage of `SwiftUI.List`.

   This is made possible by `LazyCollection` always providing an ambient `PrimitiveButtonStyle`, that will trigger the SwiftUI action closure in response to UICollectionView selection, and then subsequently auto-deselect the item. Note that auto-deselection is disabled if you use a binding (1).

### Acknowledgements

* [Samuel Défago's blog post series](https://defagos.github.io/swiftui_collection_part3/)
* [ASCollectionView](https://github.com/apptekstudios/ASCollectionView) — a more fully featured package.
