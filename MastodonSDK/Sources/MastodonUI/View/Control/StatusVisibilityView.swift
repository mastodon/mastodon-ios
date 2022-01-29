//
//  StatusVisibilityView.swift
//  
//
//  Created by MainasuK on 2022-1-28.
//

import UIKit

public final class StatusVisibilityView: UIView {
    
    static let cornerRadius: CGFloat = 8
    static let containerMargin: CGFloat = 14
    
    public let containerView = UIView()
    
    public let label: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension StatusVisibilityView {
    
    private func _init() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        containerView.backgroundColor = .secondarySystemBackground
        
        containerView.layoutMargins = UIEdgeInsets(
            top: StatusVisibilityView.containerMargin,
            left: StatusVisibilityView.containerMargin,
            bottom: StatusVisibilityView.containerMargin,
            right: StatusVisibilityView.containerMargin
        )
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor),
            label.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: containerView.layoutMarginsGuide.bottomAnchor),
        ])
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.layer.masksToBounds = false
        containerView.layer.cornerCurve = .continuous
        containerView.layer.cornerRadius = StatusVisibilityView.cornerRadius
    }
    
}
