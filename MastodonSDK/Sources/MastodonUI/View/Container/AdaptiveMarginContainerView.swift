//
//  AdaptiveMarginContainerView.swift
//  
//
//  Created by MainasuK on 2022-2-18.
//

import UIKit

public final class AdaptiveMarginContainerView: UIView {
    
    public var margin: CGFloat = 0 {
        didSet { updateConstraints() }
    }
    
    public var contentView: UIView? {
        didSet {
            guard let contentView = contentView else { return }
            guard contentView.superview == nil else { return }
            
            contentView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(contentView)
            
            topLayoutConstraint = contentView.topAnchor.constraint(equalTo: topAnchor)
            topLayoutConstraint?.isActive = true
            leadingLayoutConstraint = contentView.leadingAnchor.constraint(equalTo: leadingAnchor)
            leadingLayoutConstraint?.isActive = true
            trailingLayoutConstraint = trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            trailingLayoutConstraint?.isActive = true
            bottomLayoutConstraint = bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            bottomLayoutConstraint?.isActive = true
            
            updateConstraints()
        }
    }

    private(set) var topLayoutConstraint: NSLayoutConstraint?
    private(set) var leadingLayoutConstraint: NSLayoutConstraint?
    private(set) var trailingLayoutConstraint: NSLayoutConstraint?
    private(set) var bottomLayoutConstraint: NSLayoutConstraint?
    
}

extension AdaptiveMarginContainerView {
    
    public override func updateConstraints() {
        leadingLayoutConstraint?.constant = margin
        trailingLayoutConstraint?.constant = margin

        super.updateConstraints()
    }
    
}
