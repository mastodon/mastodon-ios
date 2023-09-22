//
//  ThreadReplyLoaderTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-13.
//

import UIKit
import Combine
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

protocol ThreadReplyLoaderTableViewCellDelegate: AnyObject {
    func threadReplyLoaderTableViewCell(_ cell: ThreadReplyLoaderTableViewCell, loadMoreButtonDidPressed button: UIButton)
}

final class ThreadReplyLoaderTableViewCell: UITableViewCell {
    
    static let cellHeight: CGFloat = 44
    
    weak var delegate: ThreadReplyLoaderTableViewCellDelegate?
    var _disposeBag = Set<AnyCancellable>()
    
    let loadMoreButton: UIButton = {
        let button = HighlightDimmableButton()
        button.titleLabel?.font = TimelineLoaderTableViewCell.labelFont
        button.setTitleColor(SystemTheme.tintColor, for: .normal)
        button.setTitle(L10n.Common.Controls.Timeline.Loader.showMoreReplies, for: .normal)
        return button
    }()
    
    let separatorLine = UIView.separatorLine
    
    var separatorLineToEdgeLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToEdgeTrailingLayoutConstraint: NSLayoutConstraint!
    
    var separatorLineToMarginLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToMarginTrailingLayoutConstraint: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        resetSeparatorLineLayout()
    }

}

extension ThreadReplyLoaderTableViewCell {

    func _init() {
        selectionStyle = .none

        loadMoreButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(loadMoreButton)
        NSLayoutConstraint.activate([
            loadMoreButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            loadMoreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: loadMoreButton.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: loadMoreButton.bottomAnchor),
            loadMoreButton.heightAnchor.constraint(equalToConstant: ThreadReplyLoaderTableViewCell.cellHeight).priority(.required - 1),
        ])
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        separatorLineToEdgeLeadingLayoutConstraint = separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        separatorLineToEdgeTrailingLayoutConstraint = separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        separatorLineToMarginLeadingLayoutConstraint = separatorLine.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor)
        separatorLineToMarginTrailingLayoutConstraint = separatorLine.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor)
        NSLayoutConstraint.activate([
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
        ])
        resetSeparatorLineLayout()
        
        loadMoreButton.addTarget(self, action: #selector(ThreadReplyLoaderTableViewCell.loadMoreButtonDidPressed(_:)), for: .touchUpInside)

        backgroundColor = .systemGroupedBackground
    }
    
    private func resetSeparatorLineLayout() {
        separatorLineToEdgeLeadingLayoutConstraint.isActive = false
        separatorLineToEdgeTrailingLayoutConstraint.isActive = false
        separatorLineToMarginLeadingLayoutConstraint.isActive = false
        separatorLineToMarginTrailingLayoutConstraint.isActive = false
        
        if traitCollection.userInterfaceIdiom == .phone {
            // to edge
            NSLayoutConstraint.activate([
                separatorLineToEdgeLeadingLayoutConstraint,
                separatorLineToEdgeTrailingLayoutConstraint,
            ])
        } else {
            if traitCollection.horizontalSizeClass == .compact {
                // to edge
                NSLayoutConstraint.activate([
                    separatorLineToEdgeLeadingLayoutConstraint,
                    separatorLineToEdgeTrailingLayoutConstraint,
                ])
            } else {
                // to margin
                NSLayoutConstraint.activate([
                    separatorLineToMarginLeadingLayoutConstraint,
                    separatorLineToMarginTrailingLayoutConstraint,
                ])
            }
        }
    }
}

extension ThreadReplyLoaderTableViewCell {
    @objc private func loadMoreButtonDidPressed(_ sender: UIButton) {
        delegate?.threadReplyLoaderTableViewCell(self, loadMoreButtonDidPressed: sender)
    }
}
