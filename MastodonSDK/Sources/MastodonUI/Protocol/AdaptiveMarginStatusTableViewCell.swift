//
//  AdaptiveMarginStatusTableViewCell.swift
//  
//
//  Created by MainasuK on 2022-2-18.
//

import UIKit

public protocol AdaptiveContainerView: UIView {
    func updateContainerViewComponentsLayoutMarginsRelativeArrangementBehavior(isEnabled: Bool)
}

public protocol AdaptiveContainerMarginTableViewCell: UITableViewCell {
    associatedtype ContainerView: AdaptiveContainerView
    static var containerViewMarginForRegularHorizontalSizeClass: CGFloat { get }
    var containerView: ContainerView { get }
    var containerViewLeadingLayoutConstraint: NSLayoutConstraint! { get set }
    var containerViewTrailingLayoutConstraint: NSLayoutConstraint! { get set }
}

extension AdaptiveContainerMarginTableViewCell {
    
    public static var containerViewMarginForRegularHorizontalSizeClass: CGFloat { 64 }
    
    public func setupContainerViewMarginConstraints() {
        containerViewLeadingLayoutConstraint = containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        containerViewTrailingLayoutConstraint = contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
    }
    
    public func updateContainerViewMarginConstraints() {
        func setupContainerForPhone() {
            containerView.updateContainerViewComponentsLayoutMarginsRelativeArrangementBehavior(isEnabled: true)        // add inner margin for phone
            containerViewLeadingLayoutConstraint.constant = 0                                                           // remove outer margin for phone
            containerViewTrailingLayoutConstraint.constant = 0
        }
        
        switch traitCollection.userInterfaceIdiom {
        case .phone:
            setupContainerForPhone()
        default:
            guard traitCollection.horizontalSizeClass == .regular else {
                setupContainerForPhone()
                return
            }
            containerView.updateContainerViewComponentsLayoutMarginsRelativeArrangementBehavior(isEnabled: false)       // remove margin for iPad
            containerViewLeadingLayoutConstraint.constant = Self.containerViewMarginForRegularHorizontalSizeClass       // add outer margin for iPad
            containerViewTrailingLayoutConstraint.constant = Self.containerViewMarginForRegularHorizontalSizeClass
        }
    }
    
    public var containerViewHorizontalMargin: CGFloat {
        containerViewLeadingLayoutConstraint.constant + containerViewTrailingLayoutConstraint.constant
    }
    
}
