import SwiftUI
import UIKit
import DifferenceKit

#if DEBUG
struct Grid_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      TestGrid_SelectionBinding()
    }
    .previewLayout(.device)
    .previewDisplayName("Selection via ID binding")

    NavigationView {
      TestGrid_Button()
    }
    .previewLayout(.device)
    .previewDisplayName("Selection via Button")
  }

  static let ranges: [Unicode.Scalar] = (0x1F601...0x1F64F).compactMap(Unicode.Scalar.init)

  struct TestGrid_SelectionBinding: View {
    @State var items = ranges.map { TestItem(id: $0) }
    @State var selection: Unicode.Scalar? = nil

    var body: some View {
      VStack(spacing: 0) {
        HStack {
          Text("Selection")
          Spacer()
          Text(selection.map(String.init) ?? "nil")
          Button { self.selection = nil } label: {
            Image(systemName: "xmark.circle.fill")
          }
        }
        .padding()

        Divider()

        Grid(items, selection: $selection) { item in
          TestButton(id: item.id)

          if item.showLabel {
            Text("Label")
          }
        }
        .navigationBarTitle(Text("Grid"))
        .navigationBarItems(
          trailing: Button {
            self.items = self.items.map { item in
              var copy = item
              copy.showLabel.toggle()
              return copy
            }
          } label: { Text("Toggle") }
        )
      }
    }

    public init() {}
  }

  struct TestGrid_Button: View {
    @State var items = ranges.map { TestItem(id: $0) }
    @State var selection: Unicode.Scalar? = nil

    var body: some View {
      VStack(spacing: 0) {
        HStack {
          Text("Selection")
          Spacer()
          Text(selection.map(String.init) ?? "nil")
        }
        .padding()

        Divider()

        Grid(items) { item in
          Button {
            self.selection = item.id
          } label: {
            TestButton(id: item.id)

            if item.showLabel {
              Text("Label")
            }
          }
        }
        .navigationBarTitle(Text("Grid"))
        .navigationBarItems(
          trailing: Button {
            self.items = self.items.map { item in
              var copy = item
              copy.showLabel.toggle()
              return copy
            }
          } label: { Text("Toggle") }
        )
      }
    }

    public init() {}
  }

  struct TestItem: Equatable, Identifiable {
    var id: Unicode.Scalar
    var showLabel: Bool = false
  }

  struct TestButton: View {
    let id: Unicode.Scalar
    @Environment(\.cellState) var cellState

    var body: some View {
      Text("\(String(id))")
        .font(Font.system(size: 48))
        .padding(8)
        .background(
          Group {
            switch cellState {
            case .selected:
              Text("\(String(id))")
                .font(Font.system(size: 64))
                .blur(radius: 48.0, opaque: true)
                .opacity(0.3)
            case .highlighted:
              Color.gray
            case .normal:
              Color.clear
            }
          }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
    }
  }


  struct Grid<Item: Equatable & Identifiable, ItemContent: View>: View {
    let items: [Item]
    var selection: Binding<Item.ID?>? = nil
    private let content: (Item) -> ItemContent
    var contentInsets: EdgeInsets = EdgeInsets()

    init(
      _ items: [Item],
      selection: Binding<Item.ID?>? = nil,
      @ViewBuilder content: @escaping (Item) -> ItemContent,
      contentInsets: EdgeInsets = EdgeInsets()
    ) {
      self.items = items
      self.selection = selection
      self.content = content
      self.contentInsets = contentInsets
    }

    var body: some View {
      LazyCollection(
        items,
        selection: selection,
        transform: { item in
          content(item)
        },
        layout: { [contentInsets] in
          let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)),
            subitem: NSCollectionLayoutItem(
              layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
            ),
            count: 3
          )
          group.interItemSpacing = .fixed(4)

          let section = NSCollectionLayoutSection(group: group)
          section.interGroupSpacing = 16
          section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: contentInsets.leading,
            bottom: 0,
            trailing: contentInsets.trailing
          )

          let layout = UICollectionViewCompositionalLayout(section: section)
          return layout
        },
        contentInsets: EdgeInsets(top: contentInsets.top, leading: 0, bottom: contentInsets.bottom, trailing: 0)
      )
    }
  }
}

#endif
