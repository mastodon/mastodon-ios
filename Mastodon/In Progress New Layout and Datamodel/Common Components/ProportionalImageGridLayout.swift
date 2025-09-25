// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Foundation
import SwiftUI

struct ProportionalImageGridLayout: Layout {
    var canUseTwoRows: Bool
    let aspects: [CGFloat]
    let spacing: CGFloat
    
    func doUseTwoRows(forSubviewCount subviewCount: Int) -> Bool {
        canUseTwoRows && subviewCount > 2
    }
    
    init(spacing: CGFloat, aspectRatios: [CGFloat], canUseTwoRows: Bool) {
        self.spacing = spacing
        self.canUseTwoRows = canUseTwoRows
        self.aspects = aspectRatios.map { max($0, 0.01) } // Avoid zero or divide-by-zero
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let width = proposal.width else { return .zero }
        
        if subviews.count == 1 {
            // Height = width / aspect
            guard let aspect = aspects.first else { return .zero }
            return CGSize(width: width, height: width / aspect)
        }
        
        if doUseTwoRows(forSubviewCount: subviews.count) {
            // Split into two rows
            let row1Count = subviews.count / 2 + subviews.count % 2
            let row2Count = subviews.count - row1Count
            
            let row1Aspects = aspects.prefix(row1Count)
            let row2Aspects = aspects.suffix(row2Count)
            
            let h1 = rowHeight(for: Array(row1Aspects), containerWidth: width)
            let h2 = rowHeight(for: Array(row2Aspects), containerWidth: width)
            
            let fullHeight = h1 + h2
            return CGSize(width: width, height: fullHeight)
        } else {
            // One row
            let height = rowHeight(for: aspects, containerWidth: width)
            return CGSize(width: width, height: height)
        }
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == aspects.count else { return }
        
        if doUseTwoRows(forSubviewCount: subviews.count) {
            let row1Count = subviews.count / 2 + subviews.count % 2
            let row2Count = subviews.count - row1Count
            
            let row1Subviews = subviews.prefix(row1Count)
            let row2Subviews = subviews.suffix(row2Count)
            let row1Aspects = aspects.prefix(row1Count)
            let row2Aspects = aspects.suffix(row2Count)
            
            let h1 = rowHeight(for: Array(row1Aspects), containerWidth: bounds.width)
            let h2 = rowHeight(for: Array(row2Aspects), containerWidth: bounds.width)
            
            let halfSpacing = spacing / 2.0
            
            let row1Frame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: h1 - halfSpacing)
            let row2Frame = CGRect(x: bounds.minX, y: bounds.minY + h1 + halfSpacing, width: bounds.width, height: h2 - halfSpacing)
            
            layoutRow(in: row1Frame, subviews: Array(row1Subviews), aspects: Array(row1Aspects))
            layoutRow(in: row2Frame, subviews: Array(row2Subviews), aspects: Array(row2Aspects))
        } else {
            layoutRow(in: bounds, subviews: Array(subviews), aspects: aspects)
        }
    }
    
    private func layoutRow(in rect: CGRect, subviews: [LayoutSubview], aspects: [CGFloat]) {
        let totalAspect = aspects.reduce(0, +)
    
        var x = rect.minX
        for (index, subview) in subviews.enumerated() {
            guard index < aspects.endIndex else { break }
            let isFirstOrLast = index == subviews.startIndex || index == subviews.endIndex
            let widthReductionForSpacing = spacing / (isFirstOrLast ? 2 : 1)
            let width = rect.width * (aspects[index] / totalAspect)
            let frame = CGRect(x: x, y: rect.minY, width: width - widthReductionForSpacing, height: rect.height)
            subview.place(at: frame.origin, proposal: ProposedViewSize(width: frame.width, height: frame.height))
            x += width + spacing
        }
    }
    
    private func rowHeight(for aspects: [CGFloat], containerWidth: CGFloat) -> CGFloat {
        let totalAspect = aspects.reduce(0, +)
        return containerWidth / totalAspect
    }
}
