//
//  StatusTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import os.log
import UIKit
import Combine
import MastodonAsset
import MastodonLocalization
import MastodonUI

final class StatusTableViewCell: UITableViewCell {
    
    static let marginForRegularHorizontalSizeClass: CGFloat = 64
    
    let logger = Logger(subsystem: "StatusTableViewCell", category: "View")
        
    weak var delegate: StatusTableViewCellDelegate?
    var disposeBag = Set<AnyCancellable>()

    let statusView = StatusView()
    let separatorLine = UIView.separatorLine
    
    var containerViewLeadingLayoutConstraint: NSLayoutConstraint!
    var containerViewTrailingLayoutConstraint: NSLayoutConstraint!

//    var isFiltered: Bool = false {
//        didSet {
//            configure(isFiltered: isFiltered)
//        }
//    }
//
//    let filteredLabel: UILabel = {
//        let label = UILabel()
//        label.textColor = Asset.Colors.Label.secondary.color
//        label.text = L10n.Common.Controls.Timeline.filtered
//        label.font = .preferredFont(forTextStyle: .body)
//        return label
//    }()
//
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
        statusView.prepareForReuse()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension StatusTableViewCell {
    
    private func _init() {
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        setupContainerViewMarginConstraints()
        updateContainerViewMarginConstraints()
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            containerViewLeadingLayoutConstraint,
            containerViewTrailingLayoutConstraint,
            statusView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        statusView.setup(style: .inline)
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)).priority(.required - 1),
        ])
        
        statusView.delegate = self
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateContainerViewMarginConstraints()
    }

}

// MARK: - AdaptiveContainerMarginTableViewCell
extension StatusTableViewCell: AdaptiveContainerMarginTableViewCell {
    var containerView: StatusView {
        statusView
    }
}

// MARK: - StatusViewContainerTableViewCell
extension StatusTableViewCell: StatusViewContainerTableViewCell { }

// MARK: - StatusViewDelegate
extension StatusTableViewCell: StatusViewDelegate { }
