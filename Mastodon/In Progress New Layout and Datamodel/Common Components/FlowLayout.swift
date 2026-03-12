// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct FlowLayout: Layout {
    var minItemCountPerRow: Int
    var interItemSpacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? CGFloat.greatestFiniteMagnitude
        
        var currentRowWidth: CGFloat = 0
        var currentRowItemCount: Int = 0
        var rowHeight: CGFloat = 0
        
        var actualWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        func beginNextRow() {
            actualWidth = max(actualWidth, currentRowWidth)
            totalHeight += rowHeight + rowSpacing
            currentRowWidth = 0
            currentRowItemCount = 0
            rowHeight = 0
        }
        
        var index = subviews.startIndex
        while index < subviews.endIndex {
            let subview = subviews[index]
            let maxItemWidth = maxWidthAvailableForNextItem(availableWidthRemaining: maxWidth, numberOfItemsAlreadyInRow: currentRowItemCount, totalItemsRemainingToPlace: subviews.count - index)
            
            var fittingSize = subview.sizeThatFits(ProposedViewSize(width: maxItemWidth, height: nil))
            let largestSize = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            
            let wouldBeUnnecessarilySquished = (largestSize.width > fittingSize.width) && currentRowItemCount >= minItemCountPerRow
            let wouldOverrunAvailableSpace = currentRowWidth + fittingSize.width > maxWidth
            if wouldBeUnnecessarilySquished || wouldOverrunAvailableSpace && currentRowItemCount > 0 {
                beginNextRow()
            } else {
                currentRowWidth += fittingSize.width + interItemSpacing
                currentRowItemCount += 1
                rowHeight = max(rowHeight, fittingSize.height)
                index += 1
            }
        }
        totalHeight += rowHeight
        
        return CGSize(width: maxWidth, height: totalHeight)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        var itemsInCurrentRow: Int = 0
        
        func beginNextRow() {
            x = bounds.minX
            y += rowHeight + rowSpacing
            rowHeight = 0
            itemsInCurrentRow = 0
        }
        
        var index = subviews.startIndex
        while index < subviews.endIndex {
            let subview = subviews[index]
            let maxItemWidth = maxWidthAvailableForNextItem(availableWidthRemaining: bounds.maxX - x, numberOfItemsAlreadyInRow: itemsInCurrentRow, totalItemsRemainingToPlace: subviews.count - index)
            let fittingSize = subview.sizeThatFits(ProposedViewSize(width: maxItemWidth, height: nil))
            let largestSize = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            
            let wouldBeUnnecessarilySquished = (largestSize.width > fittingSize.width) && (itemsInCurrentRow >= minItemCountPerRow)
            let wouldOverrunAvailableSpace = x + fittingSize.width > bounds.maxX
            if wouldBeUnnecessarilySquished || wouldOverrunAvailableSpace && itemsInCurrentRow > 0 {
                beginNextRow()
            } else {
                subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(fittingSize)
                )
                
                x += fittingSize.width + interItemSpacing
                rowHeight = max(rowHeight, fittingSize.height)
                itemsInCurrentRow += 1
                index += 1
            }
        }
    }
    
    func maxWidthAvailableForNextItem(availableWidthRemaining: CGFloat, numberOfItemsAlreadyInRow: Int, totalItemsRemainingToPlace: Int) -> CGFloat {
        let remainingMinItemCountForRow = minItemCountPerRow - numberOfItemsAlreadyInRow
        let remainingActualItemCountForRow = max(min(remainingMinItemCountForRow, totalItemsRemainingToPlace), 1) // we can place more items than the expected number if there is space
        
        let interItemSpaceRemaining = CGFloat(remainingActualItemCountForRow - 1) * interItemSpacing
        let widthAvailableForThisItem = (availableWidthRemaining - interItemSpaceRemaining) / CGFloat(remainingActualItemCountForRow)
        return widthAvailableForThisItem
    }
}
