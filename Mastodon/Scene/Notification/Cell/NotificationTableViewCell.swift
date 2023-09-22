//
//  NotificationTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import UIKit
import Combine
import MastodonCore
import MastodonUI

final class NotificationTableViewCell: UITableViewCell {
    weak var delegate: NotificationTableViewCellDelegate?
    var disposeBag = Set<AnyCancellable>()
    private var _disposeBag = Set<AnyCancellable>()
    
    let notificationView = NotificationView()
    
    let separatorLine = UIView.separatorLine
    
    var containerViewLeadingLayoutConstraint: NSLayoutConstraint!
    var containerViewTrailingLayoutConstraint: NSLayoutConstraint!

    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
        notificationView.prepareForReuse()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension NotificationTableViewCell {
    
    private func _init() {
        notificationView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(notificationView)
        setupContainerViewMarginConstraints()
        NSLayoutConstraint.activate([
            notificationView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            containerViewLeadingLayoutConstraint,
            containerViewTrailingLayoutConstraint,
            contentView.bottomAnchor.constraint(equalTo: notificationView.bottomAnchor),
        ])
        updateContainerViewMarginConstraints()
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)).priority(.required - 1),
        ])
        
        notificationView.quoteBackgroundView.backgroundColor = ThemeService.shared.currentTheme.secondarySystemBackgroundColor
        
        notificationView.delegate = self
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateContainerViewMarginConstraints()
    }
    
}

// MARK: - AdaptiveContainerMarginTableViewCell
extension NotificationTableViewCell: AdaptiveContainerMarginTableViewCell {
    var containerView: NotificationView {
        notificationView
    }
}

// MARK: - NotificationViewContainerTableViewCell
extension NotificationTableViewCell: NotificationViewContainerTableViewCell { }

// MARK: - NotificationTableViewCellDelegate
extension NotificationTableViewCell: NotificationViewDelegate { }
