// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI

struct FlowLayout: Layout {
    var maxItemWidth: CGFloat
    var interItemSpacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        
        var currentRowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        var actualWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: maxItemWidth, height: nil))
            
            if currentRowWidth + size.width > maxWidth {
                actualWidth = max(actualWidth, currentRowWidth)
                totalHeight += rowHeight + rowSpacing
                currentRowWidth = 0
                rowHeight = 0
            }
            
            currentRowWidth += size.width + interItemSpacing
            rowHeight = max(rowHeight, size.height)
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
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: maxItemWidth, height: nil))
            
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + rowSpacing
                rowHeight = 0
            }
            
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(size)
            )
            
            x += size.width + interItemSpacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
