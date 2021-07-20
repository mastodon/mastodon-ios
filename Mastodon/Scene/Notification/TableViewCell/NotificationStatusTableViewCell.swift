//
//  NotificationStatusTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/14.
//

import os.log
import Combine
import Foundation
import CoreDataStack
import UIKit
import ActiveLabel
import MetaTextView
import Meta
import FLAnimatedImage
import Nuke

protocol NotificationTableViewCellDelegate: AnyObject {
    var context: AppContext! { get }
    func parent() -> UIViewController

    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, avatarImageViewDidPressed imageView: UIImageView)
    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, authorNameLabelDidPressed label: ActiveLabel)

    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, revealContentWarningButtonDidPressed button: UIButton)
    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta)

    func notificationTableViewCell(_ cell: NotificationStatusTableViewCell, notification: MastodonNotification, acceptButtonDidPressed button: UIButton)
    func notificationTableViewCell(_ cell: NotificationStatusTableViewCell, notification: MastodonNotification, rejectButtonDidPressed button: UIButton)

}

final class NotificationStatusTableViewCell: UITableViewCell, StatusCell {

    static let actionImageBorderWidth: CGFloat = 2
    static let statusPadding = UIEdgeInsets(top: 50, left: 73, bottom: 24, right: 24)
    static let actionImageViewSize = CGSize(width: 24, height: 24)

    var disposeBag = Set<AnyCancellable>()
    var pollCountdownSubscription: AnyCancellable?
    var delegate: NotificationTableViewCellDelegate?

    var containerStackViewBottomLayoutConstraint: NSLayoutConstraint!
    let containerStackView = UIStackView()

    let avatarImageView: UIImageView = {
        let imageView = FLAnimatedImageView()
        return imageView
    }()


    let traitCollectionDidChange = PassthroughSubject<Void, Never>()
    
    let actionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.isOpaque = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = NotificationStatusTableViewCell.actionImageViewSize.width * 0.5
        imageView.layer.cornerCurve = .circular
        imageView.layer.borderWidth = NotificationStatusTableViewCell.actionImageBorderWidth
        imageView.layer.shouldRasterize = true
        imageView.layer.rasterizationScale = UIScreen.main.scale
        return imageView
    }()
    
    let avatarContainer: UIView = {
        let view = UIView()
        return view
    }()

    let contentStackView = UIStackView()

    let actionLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.secondary.color
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular), maximumPointSize: 20)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    let nameLabel: ActiveLabel = {
        let label = ActiveLabel(style: .statusName)
        label.textColor = Asset.Colors.brandBlue.color
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold), maximumPointSize: 20)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    let buttonStackView = UIStackView()

    let acceptButton: UIButton = {
        let button = UIButton(type: .custom)
        let actionImage = UIImage(systemName: "checkmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold))?.withRenderingMode(.alwaysTemplate)
        button.setImage(actionImage, for: .normal)
        button.tintColor = Asset.Colors.Label.secondary.color
        return button
    }()

    let rejectButton: UIButton = {
        let button = UIButton(type: .custom)
        let actionImage = UIImage(systemName: "xmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold))?.withRenderingMode(.alwaysTemplate)
        button.setImage(actionImage, for: .normal)
        button.tintColor = Asset.Colors.Label.secondary.color
        return button
    }()

    let statusContainerView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 6
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 2
        view.layer.borderColor = Asset.Colors.Border.notificationStatus.color.cgColor
        return view
    }()
    let statusView = StatusView()
    
    let separatorLine = UIView.separatorLine
        
    var separatorLineToEdgeLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToEdgeTrailingLayoutConstraint: NSLayoutConstraint!
    
    var separatorLineToMarginLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToMarginTrailingLayoutConstraint: NSLayoutConstraint!

    var isFiltered: Bool = false {
        didSet {
            configure(isFiltered: isFiltered)
        }
    }

    let filteredLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = L10n.Common.Controls.Timeline.filtered
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isFiltered = false
        statusView.updateContentWarningDisplay(isHidden: true, animated: false)
        statusView.pollTableView.dataSource = nil
        statusView.playerContainerView.reset()
        statusView.playerContainerView.isHidden = true
        disposeBag.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

}

extension NotificationStatusTableViewCell {
    func configure() {
        containerStackView.axis = .horizontal
        containerStackView.alignment = .top
        containerStackView.distribution = .fill
        containerStackView.spacing = 14 + 2 // 2pt for status container outline border
        containerStackView.layoutMargins = UIEdgeInsets(top: 14, left: 0, bottom: 12, right: 0)
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        containerStackViewBottomLayoutConstraint = contentView.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            containerStackViewBottomLayoutConstraint.priority(.required - 1),
        ])

        containerStackView.addArrangedSubview(avatarContainer)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
            avatarImageView.heightAnchor.constraint(equalToConstant: 35).priority(.required - 1),
            avatarImageView.widthAnchor.constraint(equalToConstant: 35).priority(.required - 1),
        ])

        actionImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(actionImageView)
        NSLayoutConstraint.activate([
            actionImageView.centerYAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
            actionImageView.centerXAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            actionImageView.widthAnchor.constraint(equalToConstant: NotificationStatusTableViewCell.actionImageViewSize.width).priority(.required - 1),
            actionImageView.heightAnchor.constraint(equalTo: actionImageView.widthAnchor, multiplier: 1.0),
        ])

        containerStackView.addArrangedSubview(contentStackView)
        contentStackView.axis = .vertical
        contentStackView.spacing = 6

        // header
        let actionStackView = UIStackView()
        contentStackView.addArrangedSubview(actionStackView)
        actionStackView.axis = .horizontal
        actionStackView.distribution = .fill
        actionStackView.spacing = 4

        actionStackView.addArrangedSubview(nameLabel)
        actionStackView.addArrangedSubview(actionLabel)
        nameLabel.setContentHuggingPriority(.required - 1, for: .horizontal)
        nameLabel.setContentHuggingPriority(.required - 1, for: .vertical)
        nameLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        actionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        // follow request
        contentStackView.addArrangedSubview(buttonStackView)
        buttonStackView.addArrangedSubview(acceptButton)
        buttonStackView.addArrangedSubview(rejectButton)
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually

        // status
        contentStackView.addArrangedSubview(statusContainerView)
        statusContainerView.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusContainerView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: statusContainerView.layoutMarginsGuide.topAnchor),
            statusView.leadingAnchor.constraint(equalTo: statusContainerView.layoutMarginsGuide.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: statusContainerView.layoutMarginsGuide.trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: statusContainerView.layoutMarginsGuide.bottomAnchor),
        ])

        setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackgroundColor(theme: theme)
            }
            .store(in: &disposeBag)
        // remove item don't display
        statusView.actionToolbarContainer.removeFromStackView()
        // it affect stackView's height, need remove
        statusView.headerContainerView.removeFromStackView()

        // adaptive separator
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

        filteredLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(filteredLabel)
        NSLayoutConstraint.activate([
            filteredLabel.centerXAnchor.constraint(equalTo: statusContainerView.centerXAnchor),
            filteredLabel.centerYAnchor.constraint(equalTo: statusContainerView.centerYAnchor),
        ])
        filteredLabel.isHidden = true

        statusView.delegate = self

        let avatarImageViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        avatarImageViewTapGestureRecognizer.addTarget(self, action: #selector(NotificationStatusTableViewCell.avatarImageViewTapGestureRecognizerHandler(_:)))
        avatarImageView.addGestureRecognizer(avatarImageViewTapGestureRecognizer)
        let authorNameLabelTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        authorNameLabelTapGestureRecognizer.addTarget(self, action: #selector(NotificationStatusTableViewCell.authorNameLabelTapGestureRecognizerHandler(_:)))
        nameLabel.addGestureRecognizer(authorNameLabelTapGestureRecognizer)

        resetSeparatorLineLayout()

        setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackgroundColor(theme: theme)
            }
            .store(in: &disposeBag)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        resetSeparatorLineLayout()
        setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
        traitCollectionDidChange.send()
    }

    private func configure(isFiltered: Bool) {
        statusView.alpha = isFiltered ? 0 : 1
        filteredLabel.isHidden = !isFiltered
        isUserInteractionEnabled = !isFiltered
    }
}

extension NotificationStatusTableViewCell {

    private func setupBackgroundColor(theme: Theme) {
        actionImageView.layer.borderColor = theme.systemBackgroundColor.cgColor
        avatarImageView.layer.borderColor = Asset.Theme.Mastodon.systemBackground.color.cgColor
        statusContainerView.layer.borderColor = Asset.Colors.Border.notificationStatus.color.cgColor
        statusContainerView.backgroundColor = UIColor(dynamicProvider: { traitCollection in
            return traitCollection.userInterfaceStyle == .light ? theme.systemBackgroundColor : theme.tertiarySystemGroupedBackgroundColor
        })
    }

}

extension NotificationStatusTableViewCell {
    @objc private func avatarImageViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.notificationStatusTableViewCell(self, avatarImageViewDidPressed: avatarImageView)
    }

    @objc private func authorNameLabelTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.notificationStatusTableViewCell(self, authorNameLabelDidPressed: nameLabel)
    }
}

// MARK: - StatusViewDelegate
extension NotificationStatusTableViewCell: StatusViewDelegate {

    func statusView(_ statusView: StatusView, headerInfoLabelDidPressed label: UILabel) {
        // do nothing
    }

    func statusView(_ statusView: StatusView, avatarImageViewDidPressed imageView: UIImageView) {
        // do nothing
    }
    
    func statusView(_ statusView: StatusView, revealContentWarningButtonDidPressed button: UIButton) {
        delegate?.notificationStatusTableViewCell(self, statusView: statusView, revealContentWarningButtonDidPressed: button)
    }
    
    func statusView(_ statusView: StatusView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
        delegate?.notificationStatusTableViewCell(self, statusView: statusView, contentWarningOverlayViewDidPressed: contentWarningOverlayView)
    }
    
    func statusView(_ statusView: StatusView, playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
        delegate?.notificationStatusTableViewCell(self, statusView: statusView, playerContainerView: playerContainerView, contentWarningOverlayViewDidPressed: contentWarningOverlayView)
    }
    
    func statusView(_ statusView: StatusView, pollVoteButtonPressed button: UIButton) {
        // do nothing
    }
    
    func statusView(_ statusView: StatusView, activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        // do nothing
    }

    func statusView(_ statusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta) {
        delegate?.notificationStatusTableViewCell(self, statusView: statusView, metaText: metaText, didSelectMeta: meta)
    }
    
}

extension NotificationStatusTableViewCell {
    
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

// MARK: - AvatarConfigurableView
extension NotificationStatusTableViewCell: AvatarConfigurableView {
    static var configurableAvatarImageSize: CGSize { CGSize(width: 35, height: 35) }
    static var configurableAvatarImageCornerRadius: CGFloat { 4 }
    var configurableAvatarImageView: UIImageView? { avatarImageView }
    var configurableAvatarButton: UIButton? { nil }
}
