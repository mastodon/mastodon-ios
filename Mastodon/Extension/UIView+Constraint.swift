//
//  UIView+Constraint.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import UIKit

enum Dimension {
    case width
    case height

    var layoutAttribute: NSLayoutConstraint.Attribute {
        switch self {
        case .width:
            return .width
        case .height:
            return .height
        }
    }

}

extension UIView {

    func constrain(toSuperviewEdges: UIEdgeInsets?) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return}
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
                NSLayoutConstraint(item: self,
                                   attribute: .leading,
                                   relatedBy: .equal,
                                   toItem: view,
                                   attribute: .leading,
                                   multiplier: 1.0,
                                   constant: toSuperviewEdges?.left ?? 0.0),
                NSLayoutConstraint(item: self,
                                   attribute: .top,
                                   relatedBy: .equal,
                                   toItem: view,
                                   attribute: .top,
                                   multiplier: 1.0,
                                   constant: toSuperviewEdges?.top ?? 0.0),
                NSLayoutConstraint(item: self,
                                   attribute: .trailing,
                                   relatedBy: .equal,
                                   toItem: view,
                                   attribute: .trailing,
                                   multiplier: 1.0,
                                   constant: toSuperviewEdges?.right ?? 0.0),
                NSLayoutConstraint(item: self,
                                   attribute: .bottom,
                                   relatedBy: .equal,
                                   toItem: view,
                                   attribute: .bottom,
                                   multiplier: 1.0,
                                   constant: toSuperviewEdges?.bottom ?? 0.0)
            ])
    }

    func constrain(_ constraints: [NSLayoutConstraint?]) {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints.compactMap { $0 })
    }

    func constraint(_ attribute: NSLayoutConstraint.Attribute, toView: UIView, constant: CGFloat?) -> NSLayoutConstraint? {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return nil}
        translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .equal, toItem: toView, attribute: attribute, multiplier: 1.0, constant: constant ?? 0.0)
    }

    func constraint(_ attribute: NSLayoutConstraint.Attribute, toView: UIView) -> NSLayoutConstraint? {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return nil}
        translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .equal, toItem: toView, attribute: attribute, multiplier: 1.0, constant: 0.0)
    }

    func constraint(_ dimension: Dimension, constant: CGFloat) -> NSLayoutConstraint? {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return nil }
        translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self,
                                  attribute: dimension.layoutAttribute,
                                  relatedBy: .equal,
                                  toItem: nil,
                                  attribute: .notAnAttribute,
                                  multiplier: 1.0,
                                  constant: constant)
    }

    func constraint(toBottom: UIView, constant: CGFloat) -> NSLayoutConstraint? {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return nil }
        translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: toBottom, attribute: .bottom, multiplier: 1.0, constant: constant)
    }

    func pinToBottom(to: UIView, height: CGFloat) {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.width, toView: to),
                constraint(toBottom: to, constant: 0.0),
                constraint(.height, constant: height)
            ])
    }

    func constraint(toTop: UIView, constant: CGFloat) -> NSLayoutConstraint? {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return nil }
        translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: toTop, attribute: .top, multiplier: 1.0, constant: constant)
    }

    func constraint(toTrailing: UIView, constant: CGFloat) -> NSLayoutConstraint? {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return nil }
        translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: toTrailing, attribute: .trailing, multiplier: 1.0, constant: constant)
    }

    func constraint(toLeading: UIView, constant: CGFloat) -> NSLayoutConstraint? {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return nil }
        translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: toLeading, attribute: .leading, multiplier: 1.0, constant: constant)
    }

    func constrainTopCorners(sidePadding: CGFloat, topPadding: CGFloat, topLayoutGuide: UILayoutSupport) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.leading, toView: view, constant: sidePadding),
                NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: topPadding),
                constraint(.trailing, toView: view, constant: -sidePadding)
            ])
    }

    func constrainTopCorners(sidePadding: CGFloat, topPadding: CGFloat) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.leading, toView: view, constant: sidePadding),
                constraint(.top, toView: view, constant: topPadding),
                constraint(.trailing, toView: view, constant: -sidePadding)
            ])
    }

    func constrainTopCorners(height: CGFloat) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.leading, toView: view),
                constraint(.top, toView: view),
                constraint(.trailing, toView: view),
                constraint(.height, constant: height)
            ])
    }

    func constrainBottomCorners(sidePadding: CGFloat, bottomPadding: CGFloat) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.leading, toView: view, constant: sidePadding),
                constraint(.bottom, toView: view, constant: -bottomPadding),
                constraint(.trailing, toView: view, constant: -sidePadding)
            ])
    }

    func constrainBottomCorners(height: CGFloat) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.leading, toView: view),
                constraint(.bottom, toView: view),
                constraint(.trailing, toView: view),
                constraint(.height, constant: height)
            ])
    }

    func constrainLeadingCorners() {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.top, toView: view),
                constraint(.leading, toView: view),
                constraint(.bottom, toView: view)
            ])
    }

    func constrainTrailingCorners() {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.top, toView: view),
                constraint(.trailing, toView: view),
                constraint(.bottom, toView: view)
            ])
    }

    func constrainToCenter() {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
            constraint(.centerX, toView: view),
            constraint(.centerY, toView: view)
        ])
    }

    func pinTo(viewAbove: UIView, padding: CGFloat = 0.0, height: CGFloat? = nil) {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.width, toView: viewAbove),
                constraint(toBottom: viewAbove, constant: padding),
                self.centerXAnchor.constraint(equalTo: viewAbove.centerXAnchor),
                height != nil ? constraint(.height, constant: height!) : nil
            ])
    }

    func pin(toSize: CGSize) {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
            widthAnchor.constraint(equalToConstant: toSize.width),
            heightAnchor.constraint(equalToConstant: toSize.height)])
    }

    func pinTopLeft(padding: CGFloat) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            topAnchor.constraint(equalTo: view.topAnchor, constant: padding)])
    }
    
    func pinTopRight(padding: CGFloat) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
            view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: padding),
            topAnchor.constraint(equalTo: view.topAnchor, constant: padding)])
    }

    func pinTopLeft(toView: UIView, topPadding: CGFloat) {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
            leadingAnchor.constraint(equalTo: toView.leadingAnchor),
            topAnchor.constraint(equalTo: toView.bottomAnchor, constant: topPadding)])
    }
    
    /// Cross-fades between two views by animating their alpha then setting one or the other hidden.
    /// - parameters:
    ///     - lhs: left view
    ///     - rhs: right view
    ///     - toRight: fade to the right view if true, fade to the left view if false
    ///     - duration: animation duration
    ///
    static func crossfade(_ lhs: UIView, _ rhs: UIView, toRight: Bool, duration: TimeInterval) {
        lhs.alpha = toRight ? 1.0 : 0.0
        rhs.alpha = toRight ? 0.0 : 1.0
        lhs.isHidden = false
        rhs.isHidden = false
        
        UIView.animate(withDuration: duration, animations: {
            lhs.alpha = toRight ? 0.0 : 1.0
            rhs.alpha = toRight ? 1.0 : 0.0
        }, completion: { _ in
            lhs.isHidden = toRight
            rhs.isHidden = !toRight
        })
    }
}
