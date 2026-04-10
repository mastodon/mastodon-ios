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
            
            let fittingSize = subview.sizeThatFits(ProposedViewSize(width: maxItemWidth, height: nil))
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

struct JustifiedBalancedFlowLayout: Layout {
    var minItemCountPerRow: Int
    var maxItemCountPerRow: Int
    var interItemSpacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? CGFloat.greatestFiniteMagnitude
        let rows = createRows(subviews.filter{ _ in true }, maxRowWidth: maxWidth)
        
        var totalRowHeight: CGFloat = 0
        
        for row in rows {
            let itemCountFloat = CGFloat(row.count)
            let widthPerItem = (maxWidth - itemCountFloat) / itemCountFloat
            var rowHeight: CGFloat = 0
            for subview in row {
                rowHeight = max(rowHeight, subview.sizeThatFits(ProposedViewSize(width: widthPerItem, height: nil)).height)
            }
            if rowHeight > 0 {
                totalRowHeight += rowHeight
            }
        }
        
        return CGSize(width: maxWidth, height: totalRowHeight + (CGFloat(rows.count) - 1) * rowSpacing)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var currentRowHeight: CGFloat = 0
        
        func beginNextRow() {
            x = bounds.minX
            if currentRowHeight > 0 {
                y += currentRowHeight + rowSpacing
            }
            currentRowHeight = 0
        }
        
        let maxRowWidth = proposal.width ?? .greatestFiniteMagnitude
        for row in createRows(subviews.filter { _ in true}, maxRowWidth: maxRowWidth) {
            let itemCountFloat = CGFloat(row.count)
            let widthPerItem = (maxRowWidth - (itemCountFloat - 1) * interItemSpacing) / itemCountFloat
            
            // find the height
            for subview in row {
                let layoutSize = subview.sizeThatFits(ProposedViewSize(width: widthPerItem, height: nil))
                currentRowHeight = max(currentRowHeight, layoutSize.height)
            }
              
            for subview in row {
                subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: widthPerItem, height: currentRowHeight)
                )
                x += interItemSpacing + widthPerItem
            }
            
            beginNextRow()
        }
    }
    
    func maxWidthAvailableForNextItem(availableWidthRemaining: CGFloat, numberOfItemsAlreadyInRow: Int, totalItemsRemainingToPlace: Int) -> CGFloat {
        let remainingMinItemCountForRow = minItemCountPerRow - numberOfItemsAlreadyInRow
        let remainingActualItemCountForRow = max(min(remainingMinItemCountForRow, totalItemsRemainingToPlace), 1)
        
        let interItemSpaceRemaining = CGFloat(remainingActualItemCountForRow - 1) * interItemSpacing
        let widthAvailableForThisItem = (availableWidthRemaining - interItemSpaceRemaining) / CGFloat(remainingActualItemCountForRow)
        return widthAvailableForThisItem
    }
    
    func createRows(_ subviews: [LayoutSubview], maxRowWidth: CGFloat) -> [[LayoutSubview]] {
        var currentRowWidth: CGFloat = 0
       
        var rows = [[LayoutSubview]]()
        var currentRow = [LayoutSubview]()
        
        func beginNextRow() {
            currentRowWidth = 0
            rows.append(currentRow)
            currentRow = [LayoutSubview]()
        }
        
        let widthIncrement = (maxRowWidth - (CGFloat(maxItemCountPerRow - 1) * interItemSpacing)) / CGFloat(maxItemCountPerRow)
        
        var index = subviews.startIndex
        while index < subviews.endIndex {
            let subview = subviews[index]
            let maxItemWidth = maxWidthAvailableForNextItem(availableWidthRemaining: maxRowWidth, numberOfItemsAlreadyInRow: currentRow.count, totalItemsRemainingToPlace: subviews.count - index)
            
            let fitOnLine = subview.sizeThatFits(ProposedViewSize(width: maxItemWidth, height: nil))
            let intrinsicSize = subview.sizeThatFits(ProposedViewSize(width: nil, height: nil))
            
            let wouldBeUnnecessarilySquished = (intrinsicSize.width > fitOnLine.width) && currentRow.count >= minItemCountPerRow
            let wouldOverrunAvailableSpace = currentRowWidth + intrinsicSize.width > maxRowWidth
            
            if wouldBeUnnecessarilySquished
                || (wouldOverrunAvailableSpace && currentRow.count > 0)
                || currentRow.count == maxItemCountPerRow {
                beginNextRow()
            } else {
                currentRow.append(subview)
                
                let incrementedLargestSize = {
                    if intrinsicSize.width <= widthIncrement {
                        return CGSize(width: widthIncrement, height: intrinsicSize.height)
                    } else {
                        let additionalWidth = intrinsicSize.width - widthIncrement
                        let additionalWidthIncrements = ceil(additionalWidth / (interItemSpacing + widthIncrement))
                        let desiredWidth = widthIncrement + additionalWidthIncrements * (interItemSpacing + widthIncrement)
                        return CGSize(width: min(maxRowWidth, desiredWidth), height: intrinsicSize.height)
                    }
                }()
                currentRowWidth += incrementedLargestSize.width + interItemSpacing
                index += 1
                
                if currentRow.count > maxItemCountPerRow {
                    beginNextRow()
                }
            }
        }
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
}
