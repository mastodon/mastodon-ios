//
//  UITextView.swift
//  
//
//  Created by Jed Fox on 2022-12-15.
//

import UIKit
import Meta
import MastodonCore

extension UITextView {
    public func meta(at location: CGPoint) -> (meta: Meta, range: NSRange)? {
        let glyphIndex = layoutManager.glyphIndex(for: location, in: textContainer)
        let bounds = layoutManager.boundingRect(forGlyphRange: NSMakeRange(glyphIndex, 1), in: textContainer)
        let index = layoutManager.characterIndexForGlyph(at: glyphIndex)

        guard bounds.contains(location), index < textStorage.length else { return nil }

        var effectiveRange = NSRange()
        let key = NSAttributedString.Key("MetaAttributeKey.meta")
        if let meta = textStorage.attribute(key, at: index, longestEffectiveRange: &effectiveRange, in: NSRange(..<textStorage.length)) as? Meta {
            return (meta, effectiveRange)
        }

        return nil
    }

    public func snapshot(of range: NSRange, backgroundColor: UIColor) -> (snapshot: UIView, textLineRects: [NSValue], center: CGPoint)? {
        var rects = [CGRect]()
        var combinedRect = CGRect.null
        let combinedPath = UIBezierPath()
        layoutManager.enumerateEnclosingRects(forGlyphRange: range, withinSelectedGlyphRange: NSMakeRange(NSNotFound, 0), in: textContainer) { rect, _ in
            rects.append(rect)
            combinedRect = combinedRect.union(rect)
            combinedPath.append(UIBezierPath(rect: rect))
        }
        if let snapshot = snapshotView(afterScreenUpdates: false) {
            let mask = CAShapeLayer()
            mask.path = combinedPath.cgPath
            snapshot.layer.mask = mask
            snapshot.backgroundColor = backgroundColor
            return (
                snapshot,
                rects.map(NSValue.init),
                CGPoint(x: combinedRect.midX, y: combinedRect.midY)
            )
        }
        return nil
    }
}
