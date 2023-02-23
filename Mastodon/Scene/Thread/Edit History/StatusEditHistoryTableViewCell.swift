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
    static let verticalMargin: CGFloat = 12
    static let horizontalMargin: CGFloat = 16

    let dateLabel: UILabel
    let statusHistoryView: StatusHistoryView
    private let grayBackground: UIView
    var statusViewBottomConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.textColor = Asset.Colors.Label.secondary.color
        dateLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))

        statusHistoryView = StatusHistoryView()
        statusHistoryView.translatesAutoresizingMaskIntoConstraints = false

        grayBackground = UIView()
        grayBackground.translatesAutoresizingMaskIntoConstraints = false
        grayBackground.backgroundColor = Asset.Scene.EditHistory.statusBackground.color
        grayBackground.layer.borderWidth = 1
        grayBackground.layer.borderColor = Asset.Scene.EditHistory.statusBackgroundBorder.color.cgColor
        grayBackground.applyCornerRadius(radius: 8)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        isAccessibilityElement = true

        selectionStyle = .none
        grayBackground.addSubview(statusHistoryView)
        contentView.addSubview(dateLabel)
        contentView.addSubview(grayBackground)
        
        setupContainerViewMarginConstraints()
        setupConstraints()
        updateContainerViewMarginConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        statusViewBottomConstraint = statusHistoryView.bottomAnchor.constraint(equalTo: grayBackground.bottomAnchor, constant: -Self.verticalMargin)
        let constraints = [
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            grayBackground.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: Self.verticalMargin),
            grayBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            grayBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            grayBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.verticalMargin),

            statusHistoryView.topAnchor.constraint(equalTo: grayBackground.topAnchor, constant: Self.verticalMargin),
            statusHistoryView.leadingAnchor.constraint(equalTo: grayBackground.leadingAnchor),
            statusHistoryView.trailingAnchor.constraint(equalTo: grayBackground.trailingAnchor),
            statusViewBottomConstraint,
        ].compactMap { $0 }

        NSLayoutConstraint.activate(constraints)
    }

    func configure(status: Status, statusEdit: StatusEdit, dateText: String) {
        dateLabel.text = dateText
        statusHistoryView.statusView.configure(status: status, statusEdit: statusEdit)
    }
    
    override func prepareForReuse() {
        statusHistoryView.prepareForReuse()
        super.prepareForReuse()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateContainerViewMarginConstraints()
    }

    override var accessibilityLabel: String? {
        get {
            (dateLabel.text ?? "") + ", " + (statusHistoryView.statusView.accessibilityLabel ?? "")
        }
        set {}
    }
}

// MARK: - AdaptiveContainerMarginTableViewCell
extension StatusEditHistoryTableViewCell: AdaptiveContainerMarginTableViewCell {
    var containerView: StatusHistoryView {
        statusHistoryView
    }
}

class StatusHistoryView: UIView {
    let statusView = StatusView()
    
    private var statusViewLeadingConstraint: NSLayoutConstraint!
    private var statusViewTrailingConstraint: NSLayoutConstraint!

    init() {
        super.init(frame: .zero)
        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusView.setup(style: .editHistory)
        addSubview(statusView)
        
        statusViewLeadingConstraint = statusView.leadingAnchor.constraint(equalTo: leadingAnchor)
        statusViewTrailingConstraint = statusView.trailingAnchor.constraint(equalTo: trailingAnchor)
        
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: topAnchor),
            statusView.bottomAnchor.constraint(equalTo: bottomAnchor),
            statusViewLeadingConstraint,
            statusViewTrailingConstraint
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        statusView.prepareForReuse()
    }
}

extension StatusHistoryView: AdaptiveContainerView {
    func updateContainerViewComponentsLayoutMarginsRelativeArrangementBehavior(isEnabled: Bool) {
        statusView.updateContainerViewComponentsLayoutMarginsRelativeArrangementBehavior(isEnabled: isEnabled)
        statusViewLeadingConstraint.constant = isEnabled ? 0 : StatusEditHistoryTableViewCell.horizontalMargin
        statusViewTrailingConstraint.constant = isEnabled ? 0 : -StatusEditHistoryTableViewCell.horizontalMargin
    }
}
