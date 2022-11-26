//
//  ReorderableForEach.swift
//  
//
//  Created by MainasuK on 2022-5-23.
//

import SwiftUI
import UniformTypeIdentifiers

// Ref
// https://stackoverflow.com/a/68963988/3797903

struct ReorderableForEach<Content: View, Item: Identifiable & Equatable & NSItemProviderWriting & TypeIdentifiedItemProvider>: View {

    @State var currentReorderItem: Item? = nil
    @State var isCurrentReorderItemOutside: Bool = false

    @Binding var items: [Item]
    @ViewBuilder let content: (Binding<Item>) -> Content
    
    var body: some View {
        ForEach($items) { $item in
            content($item)
                .zIndex(currentReorderItem == item ? 1 : 0)
                .onDrop(
                    of: [Item.typeIdentifier],
                    delegate: DropRelocateDelegate(
                        item: item,
                        items: $items,
                        current: $currentReorderItem,
                        isOutside: $isCurrentReorderItemOutside
                    )
                )
                .onDrag {
                    currentReorderItem = item
                    isCurrentReorderItemOutside = false
                    return NSItemProvider(object: item)
                }
        }
        .onDrop(
            of: [Item.typeIdentifier],
            delegate: DropOutsideDelegate(
                current: $currentReorderItem,
                isOutside: $isCurrentReorderItemOutside
            )
        )
    }
}

struct DropRelocateDelegate<Item: Equatable>: DropDelegate {
    let item: Item
    @Binding var items: [Item]
    
    @Binding var current: Item?
    @Binding var isOutside: Bool

    func dropEntered(info: DropInfo) {
        guard item != current, let current = current else { return }
        guard let from = items.firstIndex(of: current), let to = items.firstIndex(of: item) else { return }
        
        if items[to] != current {
            withAnimation {
                items.move(
                    fromOffsets: IndexSet(integer: from),
                    toOffset: to > from ? to + 1 : to
                )
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        current = nil
        isOutside = false
        return true
    }
}

struct DropOutsideDelegate<Item: Equatable>: DropDelegate {
    @Binding var current: Item?
    @Binding var isOutside: Bool
    
    func dropEntered(info: DropInfo) {
        isOutside = false
    }
    
    func dropExited(info: DropInfo) {
        isOutside = true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .cancel)
    }
        
    func performDrop(info: DropInfo) -> Bool {
        current = nil
        isOutside = false
        return false
    }
}

public protocol TypeIdentifiedItemProvider {
    static var typeIdentifier: String { get }
}
