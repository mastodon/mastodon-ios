//
//  AdaptiveMarginStatusTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-10.
//

import UIKit
import MastodonUI

protocol AdaptiveContainerMarginTableViewCell: UITableViewCell {
    associatedtype ContainerView: UIView
    static var containerViewMarginForRegularHorizontalSizeClass: CGFloat { get }
    var containerView: ContainerView { get }
    var containerViewLeadingLayoutConstraint: NSLayoutConstraint! { get set }
    var containerViewTrailingLayoutConstraint: NSLayoutConstraint! { get set }
}

extension AdaptiveContainerMarginTableViewCell {
    
    static var containerViewMarginForRegularHorizontalSizeClass: CGFloat { 64 }
    
    func setupContainerViewMarginConstraints() {
        containerViewLeadingLayoutConstraint = containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        containerViewTrailingLayoutConstraint = contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
    }
    
    func updateContainerViewMarginConstraints() {
        guard traitCollection.userInterfaceIdiom != .phone,
              traitCollection.horizontalSizeClass == .regular
        else {
            containerViewLeadingLayoutConstraint.constant = 0
            containerViewTrailingLayoutConstraint.constant = 0
            return
        }
                
        containerViewLeadingLayoutConstraint.constant = Self.containerViewMarginForRegularHorizontalSizeClass
        containerViewTrailingLayoutConstraint.constant = Self.containerViewMarginForRegularHorizontalSizeClass
    }
    
    var containerViewHorizontalMargin: CGFloat {
        containerViewLeadingLayoutConstraint.constant + containerViewTrailingLayoutConstraint.constant
    }
    
}
