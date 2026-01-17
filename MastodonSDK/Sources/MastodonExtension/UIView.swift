//
//  UIView.swift
//  
//
//  Created by MainasuK on 2022-1-17.
//

import UIKit

extension UIView {
    public static var isZoomedMode: Bool {
        return UIScreen.main.scale != UIScreen.main.nativeScale
    }
}

extension UIView {
    @discardableResult
    public func applyCornerRadius(radius: CGFloat) -> Self {
        layer.masksToBounds = true
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        return self
    }
}

public extension UIView {
    @discardableResult
    func pinToParent(padding: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        pinTo(to: self.superview, padding: padding)
    }

    @discardableResult
    func pinTo(to view: UIView?, padding: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        guard let pinToView = view else { return [] }
        let constraints = [
            topAnchor.constraint(equalTo: pinToView.topAnchor, constant: padding.top),
            leadingAnchor.constraint(equalTo: pinToView.leadingAnchor, constant: padding.left),
            trailingAnchor.constraint(equalTo: pinToView.trailingAnchor, constant: -padding.right),
            bottomAnchor.constraint(equalTo: pinToView.bottomAnchor, constant: -padding.bottom),
        ]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }
}
