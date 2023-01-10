//
//  TouchTransparentStackView.swift
//  
//
//  Created by Jed Fox on 2022-12-21.
//

import UIKit

/// A subclass of `UIStackView` that allows touches that aren’t captured by any
/// of its subviews to pass through to views beneath this view in the Z-order.
public class TouchTransparentStackView: UIStackView {
    // allow subview hit boxes to grow outside of this view’s bounds
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        subviews.contains { $0.point(inside: $0.convert(point, from: self), with: event) }
    }
    
    // allow taps on blank areas to pass through
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == self {
            return nil
        }
        return view
    }
}
