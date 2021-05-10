//
//  NotificationStatusTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/14.
//

import Combine
import Foundation
import UIKit
import ActiveLabel

final class NotificationStatusTableViewCell: UITableViewCell, StatusCell {
    static let actionImageBorderWidth: CGFloat = 2
    static let statusPadding = UIEdgeInsets(top: 50, left: 73, bottom: 24, right: 24)
    var disposeBag = Set<AnyCancellable>()
    var pollCountdownSubscription: AnyCancellable?
    var delegate: NotificationTableViewCellDelegate?
    
    let avatatImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 4
        imageView.layer.cornerCurve = .continuous
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let actionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = Asset.Colors.Background.systemBackground.color
        return imageView
    }()
    
    let actionImageBackground: UIView = {
        let view = UIView()
        view.layer.cornerRadius = (24 + NotificationStatusTableViewCell.actionImageBorderWidth) / 2
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        view.layer.borderWidth = NotificationStatusTableViewCell.actionImageBorderWidth
        view.layer.borderColor = Asset.Colors.Background.systemBackground.color.cgColor
        view.tintColor = Asset.Colors.Background.systemBackground.color
        return view
    }()
    
    let avatarContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    let actionLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.secondary.color
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular), maximumPointSize: 20)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.brandBlue.color
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold), maximumPointSize: 20)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    let statusBorder: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 6
        view.layer.borderWidth = 2
        view.layer.cornerCurve = .continuous
        view.layer.borderColor = Asset.Colors.Border.notification.color.cgColor
        view.clipsToBounds = true
        return view
    }()
    
    let statusView = StatusView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatatImageView.af.cancelImageRequest()
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // precondition: app is active
        guard UIApplication.shared.applicationState == .active else { return }
        DispatchQueue.main.async {
            self.statusView.drawContentWarningImageView()
        }
    }
}

extension NotificationStatusTableViewCell {
    func configure() {
        backgroundColor = Asset.Colors.Background.systemBackground.color
        
        let containerStackView = UIStackView()
        containerStackView.axis = .horizontal
        containerStackView.alignment = .top
        containerStackView.spacing = 4
        containerStackView.layoutMargins = UIEdgeInsets(top: 14, left: 0, bottom: 12, right: 0)
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])

        containerStackView.addArrangedSubview(avatarContainer)
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarContainer.heightAnchor.constraint(equalToConstant: 47).priority(.required - 1),
            avatarContainer.widthAnchor.constraint(equalToConstant: 47).priority(.required - 1)
        ])

        avatarContainer.addSubview(avatatImageView)
        avatatImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatatImageView.heightAnchor.constraint(equalToConstant: 35).priority(.required - 1),
            avatatImageView.widthAnchor.constraint(equalToConstant: 35).priority(.required - 1),
            avatatImageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            avatatImageView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor)
        ])

        avatarContainer.addSubview(actionImageBackground)
        actionImageBackground.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actionImageBackground.heightAnchor.constraint(equalToConstant: 24 + NotificationTableViewCell.actionImageBorderWidth).priority(.required - 1),
            actionImageBackground.widthAnchor.constraint(equalToConstant: 24 + NotificationTableViewCell.actionImageBorderWidth).priority(.required - 1),
            actionImageBackground.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
            actionImageBackground.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor)
        ])

        avatarContainer.addSubview(actionImageView)
        actionImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actionImageView.centerXAnchor.constraint(equalTo: actionImageBackground.centerXAnchor),
            actionImageView.centerYAnchor.constraint(equalTo: actionImageBackground.centerYAnchor)
        ])

        let actionStackView = UIStackView()
        actionStackView.axis = .horizontal
        actionStackView.distribution = .fill
        actionStackView.spacing = 4
        actionStackView.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        actionStackView.addArrangedSubview(nameLabel)
        actionLabel.translatesAutoresizingMaskIntoConstraints = false
        actionStackView.addArrangedSubview(actionLabel)
        nameLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        actionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let statusStackView = UIStackView()
        statusStackView.axis = .vertical
    
        statusStackView.distribution = .fill
        statusStackView.spacing = 4
        statusStackView.translatesAutoresizingMaskIntoConstraints = false
        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusStackView.addArrangedSubview(actionStackView)
        
        statusBorder.translatesAutoresizingMaskIntoConstraints = false
        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusBorder.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: statusBorder.topAnchor, constant: 12),
            statusView.leadingAnchor.constraint(equalTo: statusBorder.leadingAnchor, constant: 12),
            statusBorder.bottomAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 12),
            statusBorder.trailingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: 12),
        ])
        
        statusView.delegate = self
        
        statusStackView.addArrangedSubview(statusBorder)

        containerStackView.addArrangedSubview(statusStackView)
        
        // remove item don't display
        statusView.actionToolbarContainer.removeFromStackView()
        // it affect stackView's height,need remove
        statusView.avatarView.removeFromStackView()
        statusView.usernameLabel.removeFromStackView()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        statusBorder.layer.borderColor = Asset.Colors.Border.notification.color.cgColor
        actionImageBackground.layer.borderColor = Asset.Colors.Background.systemBackground.color.cgColor
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        resetContentOverlayBlurImageBackgroundColor(selected: highlighted)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        resetContentOverlayBlurImageBackgroundColor(selected: selected)
    }
    
    private func resetContentOverlayBlurImageBackgroundColor(selected: Bool) {
        let imageViewBackgroundColor: UIColor? = selected ? selectedBackgroundView?.backgroundColor : backgroundColor
        statusView.contentWarningOverlayView.blurContentImageView.backgroundColor = imageViewBackgroundColor
    }
}

// MARK: - StatusViewDelegate
extension NotificationStatusTableViewCell: StatusViewDelegate {
    func statusView(_ statusView: StatusView, headerInfoLabelDidPressed label: UILabel) {
        // do nothing
    }
    
    func statusView(_ statusView: StatusView, avatarButtonDidPressed button: UIButton) {
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
    
    
}
