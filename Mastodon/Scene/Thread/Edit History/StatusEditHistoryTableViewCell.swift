// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonUI
import MastodonSDK
import CoreDataStack
import MastodonAsset

class StatusEditHistoryTableViewCell: UITableViewCell {
    var containerViewLeadingLayoutConstraint: NSLayoutConstraint!
    var containerViewTrailingLayoutConstraint: NSLayoutConstraint!
    
    static let identifier = "StatusEditHistoryTableViewCell"
    static let horizontalMargin: CGFloat = 12

    let dateLabel: UILabel
    let statusView: StatusView
    private let grayBackground: UIView
    var statusViewBottomConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.textColor = Asset.Colors.Label.secondary.color
        dateLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))

        statusView = StatusView()
        statusView.setup(style: .inline)
        statusView.translatesAutoresizingMaskIntoConstraints = false

        grayBackground = UIView()
        grayBackground.translatesAutoresizingMaskIntoConstraints = false
        grayBackground.backgroundColor = Asset.Scene.EditHistory.statusBackground.color
        grayBackground.layer.borderWidth = 1
        grayBackground.layer.borderColor = Asset.Scene.EditHistory.statusBackgroundBorder.color.cgColor
        grayBackground.applyCornerRadius(radius: 8)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        grayBackground.addSubview(statusView)
        contentView.addSubview(dateLabel)
        contentView.addSubview(grayBackground)
        
        setupContainerViewMarginConstraints()
        setupConstraints()
        updateContainerViewMarginConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        statusViewBottomConstraint = statusView.bottomAnchor.constraint(equalTo: grayBackground.bottomAnchor, constant: -Self.horizontalMargin)
        let constraints = [
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            grayBackground.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: Self.horizontalMargin),
            grayBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            grayBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            grayBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.horizontalMargin),

            statusView.topAnchor.constraint(equalTo: grayBackground.topAnchor, constant: Self.horizontalMargin),
            statusView.leadingAnchor.constraint(equalTo: grayBackground.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: grayBackground.trailingAnchor),
            statusViewBottomConstraint,
        ].compactMap { $0 }

        NSLayoutConstraint.activate(constraints)
    }

    func configure(status: Status, statusEdit: StatusEdit, dateText: String) {
        dateLabel.text = dateText
        statusView.configure(status: status, statusEdit: statusEdit)
    }
    
    override func prepareForReuse() {
        statusView.prepareForReuse()
        super.prepareForReuse()
    }
}

// MARK: - AdaptiveContainerMarginTableViewCell
extension StatusEditHistoryTableViewCell: AdaptiveContainerMarginTableViewCell {
    var containerView: StatusView {
        statusView
    }
}
