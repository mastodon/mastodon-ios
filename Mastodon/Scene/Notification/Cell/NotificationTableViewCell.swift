//
//  NotificationTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import os.log
import UIKit
import Combine
import MastodonUI

final class NotificationTableViewCell: UITableViewCell {
    
    let logger = Logger(subsystem: "NotificationTableViewCell", category: "View")
    
    weak var delegate: NotificationTableViewCellDelegate?
    var disposeBag = Set<AnyCancellable>()
    
    let notificationView = NotificationView()
    
    let separatorLine = UIView.separatorLine

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
        NSLayoutConstraint.activate([
            notificationView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            notificationView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            notificationView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: notificationView.bottomAnchor),
        ])
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)).priority(.required - 1),
        ])
        
        notificationView.delegate = self
    }
    
}

// MARK: - NotificationViewContainerTableViewCell
extension NotificationTableViewCell: NotificationViewContainerTableViewCell { }

// MARK: - NotificationTableViewCellDelegate
extension NotificationTableViewCell: NotificationViewDelegate { }
