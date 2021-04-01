//
//  StatusView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/28.
//

import os.log
import UIKit
import AVKit
import ActiveLabel
import AlamofireImage

protocol StatusViewDelegate: class {
    func statusView(_ statusView: StatusView, contentWarningActionButtonPressed button: UIButton)
    func statusView(_ statusView: StatusView, playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
    func statusView(_ statusView: StatusView, pollVoteButtonPressed button: UIButton)
    func statusView(_ statusView: StatusView, didSelectActiveEntity activeLabel: ActiveLabel, entity: ActiveEntity)
}

final class StatusView: UIView {
    
    var statusPollTableViewHeightObservation: NSKeyValueObservation?
    
    static let avatarImageSize = CGSize(width: 42, height: 42)
    static let avatarImageCornerRadius: CGFloat = 4
    static let avatarToLabelSpacing: CGFloat = 5
    static let contentWarningBlurRadius: CGFloat = 12
    
    static let boostIconImage: UIImage = {
        let font = UIFont.systemFont(ofSize: 13, weight: .medium)
        let configuration = UIImage.SymbolConfiguration(font: font)
        let image = UIImage(systemName: "arrow.2.squarepath", withConfiguration: configuration)!.withTintColor(Asset.Colors.Label.secondary.color)
        return image
    }()
    
    static let replyIconImage: UIImage = {
        let font = UIFont.systemFont(ofSize: 13, weight: .medium)
        let configuration = UIImage.SymbolConfiguration(font: font)
        let image = UIImage(systemName: "arrowshape.turn.up.left.fill", withConfiguration: configuration)!.withTintColor(Asset.Colors.Label.secondary.color)
        return image
    }()
    
    static func iconAttributedString(image: UIImage) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        let imageTextAttachment = NSTextAttachment()
        let imageAttribute = NSAttributedString(attachment: imageTextAttachment)
        imageTextAttachment.image = image
        attributedString.append(imageAttribute)
        return attributedString
    }
    
    weak var delegate: StatusViewDelegate?
    var isStatusTextSensitive = false
    var pollTableViewDataSource: UITableViewDiffableDataSource<PollSection, PollItem>?
    var pollTableViewHeightLaoutConstraint: NSLayoutConstraint!
    
    let headerContainerStackView = UIStackView()
    
    let headerIconLabel: UILabel = {
        let label = UILabel()
        label.attributedText = StatusView.iconAttributedString(image: StatusView.boostIconImage)
        return label
    }()
    
    let headerInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .medium))
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = "Bob reblogged"
        return label
    }()
    
    let avatarView = UIView()
    let avatarButton: UIButton = {
        let button = HighlightDimmableButton(type: .custom)
        let placeholderImage = UIImage.placeholder(size: avatarImageSize, color: .systemFill)
            .af.imageRounded(withCornerRadius: StatusView.avatarImageCornerRadius, divideRadiusByImageScale: true)
        button.setImage(placeholderImage, for: .normal)
        return button
    }()
    let avatarStackedContainerButton: AvatarStackContainerButton = AvatarStackContainerButton()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = Asset.Colors.Label.primary.color
        label.text = "Alice"
        return label
    }()
    
    let nameTrialingDotLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.secondary.color
        label.font = .systemFont(ofSize: 17)
        label.text = "·"
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = "@alice"
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = "1d"
        return label
    }()
    
    let statusContainerStackView = UIStackView()
    let statusTextContainerView = UIView()
    let statusContentWarningContainerStackView = UIStackView()
    var statusContentWarningContainerStackViewBottomLayoutConstraint: NSLayoutConstraint!
    
    let contentWarningTitle: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Common.Controls.Status.statusContentWarning
        return label
    }()
    let contentWarningActionButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .medium))
        button.setTitleColor(Asset.Colors.Label.highlight.color, for: .normal)
        button.setTitle(L10n.Common.Controls.Status.showPost, for: .normal)
        return button
    }()
    let statusMosaicImageViewContainer = MosaicImageViewContainer()
    
    let pollTableView: PollTableView = {
        let tableView = PollTableView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        tableView.register(PollOptionTableViewCell.self, forCellReuseIdentifier: String(describing: PollOptionTableViewCell.self))
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    let pollStatusStackView = UIStackView()
    let pollVoteCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 12, weight: .regular))
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = L10n.Common.Controls.Status.Poll.VoteCount.single(0)
        return label
    }()
    let pollStatusDotLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 12, weight: .regular))
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = " · "
        return label
    }()
    let pollCountdownLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 12, weight: .regular))
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = L10n.Common.Controls.Status.Poll.timeLeft("6 hours")
        return label
    }()
    let pollVoteButton: UIButton = {
        let button = HitTestExpandedButton()
        button.titleLabel?.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 14, weight: .semibold))
        button.setTitle(L10n.Common.Controls.Status.Poll.vote, for: .normal)
        button.setTitleColor(Asset.Colors.Button.normal.color, for: .normal)
        button.setTitleColor(Asset.Colors.Button.normal.color.withAlphaComponent(0.8), for: .highlighted)
        button.setTitleColor(Asset.Colors.Button.disabled.color, for: .disabled)
        button.isEnabled = false
        return button
    }()
    
    // do not use visual effect view due to we blur text only without background
    let contentWarningBlurContentImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = Asset.Colors.Background.secondaryGroupedSystemBackground.color
        imageView.layer.masksToBounds = false
        return imageView
    }()

    let playerContainerView = PlayerContainerView()
    
    let audioView: AudioContainerView = {
        let audioView = AudioContainerView()
        return audioView
    }()
    let actionToolbarContainer: ActionToolbarContainer = {
        let actionToolbarContainer = ActionToolbarContainer()
        actionToolbarContainer.configure(for: .inline)
        return actionToolbarContainer
    }()
    
    
    let activeTextLabel = ActiveLabel(style: .default)
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // update blur image when interface style changed
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            drawContentWarningImageView()
        }
    }
    
    deinit {
        statusPollTableViewHeightObservation = nil
    }

}

extension StatusView {
    
    func _init() {
        // container: [retoot | author | status | action toolbar]
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = 10
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        
        // header container: [icon | info]
        containerStackView.addArrangedSubview(headerContainerStackView)
        headerContainerStackView.spacing = 4
        headerContainerStackView.addArrangedSubview(headerIconLabel)
        headerContainerStackView.addArrangedSubview(headerInfoLabel)
        headerIconLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        // author container: [avatar | author meta container]
        let authorContainerStackView = UIStackView()
        containerStackView.addArrangedSubview(authorContainerStackView)
        authorContainerStackView.axis = .horizontal
        authorContainerStackView.spacing = StatusView.avatarToLabelSpacing

        // avatar
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        authorContainerStackView.addArrangedSubview(avatarView)
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: StatusView.avatarImageSize.width).priority(.required - 1),
            avatarView.heightAnchor.constraint(equalToConstant: StatusView.avatarImageSize.height).priority(.required - 1),
        ])
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarButton.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarButton.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarButton.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),
        ])
        avatarStackedContainerButton.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarStackedContainerButton)
        NSLayoutConstraint.activate([
            avatarStackedContainerButton.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarStackedContainerButton.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarStackedContainerButton.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarStackedContainerButton.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),
        ])
        
        // author meta container: [title container | subtitle container]
        let authorMetaContainerStackView = UIStackView()
        authorContainerStackView.addArrangedSubview(authorMetaContainerStackView)
        authorMetaContainerStackView.axis = .vertical
        authorMetaContainerStackView.spacing = 4
        
        // title container: [display name | "·" | date]
        let titleContainerStackView = UIStackView()
        authorMetaContainerStackView.addArrangedSubview(titleContainerStackView)
        titleContainerStackView.axis = .horizontal
        titleContainerStackView.spacing = 4
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        titleContainerStackView.addArrangedSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.heightAnchor.constraint(equalToConstant: 22).priority(.defaultHigh),
        ])
        titleContainerStackView.alignment = .firstBaseline
        titleContainerStackView.addArrangedSubview(nameTrialingDotLabel)
        titleContainerStackView.addArrangedSubview(dateLabel)
        nameLabel.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
        nameTrialingDotLabel.setContentHuggingPriority(.defaultHigh + 2, for: .horizontal)
        nameTrialingDotLabel.setContentCompressionResistancePriority(.required - 2, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        // subtitle container: [username]
        let subtitleContainerStackView = UIStackView()
        authorMetaContainerStackView.addArrangedSubview(subtitleContainerStackView)
        subtitleContainerStackView.axis = .horizontal
        subtitleContainerStackView.addArrangedSubview(usernameLabel)
        
        // status container: [status | image / video | audio | poll | poll status]
        containerStackView.addArrangedSubview(statusContainerStackView)
        statusContainerStackView.axis = .vertical
        statusContainerStackView.spacing = 10
        statusContainerStackView.addArrangedSubview(statusTextContainerView)
        statusTextContainerView.setContentCompressionResistancePriority(.required - 2, for: .vertical)
        activeTextLabel.translatesAutoresizingMaskIntoConstraints = false
        statusTextContainerView.addSubview(activeTextLabel)
        NSLayoutConstraint.activate([
            activeTextLabel.topAnchor.constraint(equalTo: statusTextContainerView.topAnchor),
            activeTextLabel.leadingAnchor.constraint(equalTo: statusTextContainerView.leadingAnchor),
            activeTextLabel.trailingAnchor.constraint(equalTo: statusTextContainerView.trailingAnchor),
            statusTextContainerView.bottomAnchor.constraint(greaterThanOrEqualTo: activeTextLabel.bottomAnchor),
        ])
        activeTextLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        contentWarningBlurContentImageView.translatesAutoresizingMaskIntoConstraints = false
        statusTextContainerView.addSubview(contentWarningBlurContentImageView)
        NSLayoutConstraint.activate([
            activeTextLabel.topAnchor.constraint(equalTo: contentWarningBlurContentImageView.topAnchor, constant: StatusView.contentWarningBlurRadius),
            activeTextLabel.leadingAnchor.constraint(equalTo: contentWarningBlurContentImageView.leadingAnchor, constant: StatusView.contentWarningBlurRadius),
            
        ])
        statusContentWarningContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        statusContentWarningContainerStackView.axis = .vertical
        statusContentWarningContainerStackView.distribution = .fill
        statusContentWarningContainerStackView.alignment = .center
        statusTextContainerView.addSubview(statusContentWarningContainerStackView)
        statusContentWarningContainerStackViewBottomLayoutConstraint = statusTextContainerView.bottomAnchor.constraint(greaterThanOrEqualTo: statusContentWarningContainerStackView.bottomAnchor)
        NSLayoutConstraint.activate([
            statusContentWarningContainerStackView.topAnchor.constraint(equalTo: statusTextContainerView.topAnchor),
            statusContentWarningContainerStackView.leadingAnchor.constraint(equalTo: statusTextContainerView.leadingAnchor),
            statusContentWarningContainerStackView.trailingAnchor.constraint(equalTo: statusTextContainerView.trailingAnchor),
            statusContentWarningContainerStackViewBottomLayoutConstraint,
        ])
        statusContentWarningContainerStackView.addArrangedSubview(contentWarningTitle)
        statusContentWarningContainerStackView.addArrangedSubview(contentWarningActionButton)
        
        statusContainerStackView.addArrangedSubview(statusMosaicImageViewContainer)
        pollTableView.translatesAutoresizingMaskIntoConstraints = false
        statusContainerStackView.addArrangedSubview(pollTableView)
        pollTableViewHeightLaoutConstraint = pollTableView.heightAnchor.constraint(equalToConstant: 44.0).priority(.required - 1)
        NSLayoutConstraint.activate([
            pollTableViewHeightLaoutConstraint,
        ])
        
        statusPollTableViewHeightObservation = pollTableView.observe(\.contentSize, options: .new, changeHandler: { [weak self] tableView, _ in
            guard let self = self else { return }
            guard self.pollTableView.contentSize.height != .zero else {
                self.pollTableViewHeightLaoutConstraint.constant = 44
                return
            }
            self.pollTableViewHeightLaoutConstraint.constant = self.pollTableView.contentSize.height
        })
        
        statusContainerStackView.addArrangedSubview(pollStatusStackView)
        pollStatusStackView.axis = .horizontal
        pollStatusStackView.addArrangedSubview(pollVoteCountLabel)
        pollStatusStackView.addArrangedSubview(pollStatusDotLabel)
        pollStatusStackView.addArrangedSubview(pollCountdownLabel)
        pollStatusStackView.addArrangedSubview(pollVoteButton)
        pollVoteCountLabel.setContentHuggingPriority(.defaultHigh + 2, for: .horizontal)
        pollStatusDotLabel.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
        pollCountdownLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        pollVoteButton.setContentHuggingPriority(.defaultHigh + 3, for: .horizontal)
        
        // audio
        audioView.translatesAutoresizingMaskIntoConstraints = false
        statusContainerStackView.addArrangedSubview(audioView)
        NSLayoutConstraint.activate([
            audioView.leadingAnchor.constraint(equalTo: statusTextContainerView.leadingAnchor),
            audioView.trailingAnchor.constraint(equalTo: statusTextContainerView.trailingAnchor),
            audioView.heightAnchor.constraint(equalToConstant: 44).priority(.defaultHigh)
        ])
        // video gif
        statusContainerStackView.addArrangedSubview(playerContainerView)
        
        // action toolbar container
        containerStackView.addArrangedSubview(actionToolbarContainer)
        actionToolbarContainer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        headerContainerStackView.isHidden = true
        statusMosaicImageViewContainer.isHidden = true
        pollTableView.isHidden = true
        pollStatusStackView.isHidden = true
        audioView.isHidden = true
        playerContainerView.isHidden = true
        
        avatarStackedContainerButton.isHidden = true
        contentWarningBlurContentImageView.isHidden = true
        statusContentWarningContainerStackView.isHidden = true
        statusContentWarningContainerStackViewBottomLayoutConstraint.isActive = false
        
        playerContainerView.delegate = self
        activeTextLabel.delegate = self
        
        contentWarningActionButton.addTarget(self, action: #selector(StatusView.contentWarningActionButtonPressed(_:)), for: .touchUpInside)
        pollVoteButton.addTarget(self, action: #selector(StatusView.pollVoteButtonPressed(_:)), for: .touchUpInside)
    }
    
}

extension StatusView {
    
    func cleanUpContentWarning() {
        contentWarningBlurContentImageView.image = nil
    }
    
    func drawContentWarningImageView() {
        guard activeTextLabel.frame != .zero,
              isStatusTextSensitive,
              let text = activeTextLabel.text, !text.isEmpty else {
            cleanUpContentWarning()
            return
        }
        
        let image = UIGraphicsImageRenderer(size: activeTextLabel.frame.size).image { context in
            activeTextLabel.draw(activeTextLabel.bounds)
        }
        .blur(radius: StatusView.contentWarningBlurRadius)
        contentWarningBlurContentImageView.contentScaleFactor = traitCollection.displayScale
        contentWarningBlurContentImageView.image = image
    }
    
    func updateContentWarningDisplay(isHidden: Bool) {
        contentWarningBlurContentImageView.isHidden = isHidden
        statusContentWarningContainerStackView.isHidden = isHidden
        statusContentWarningContainerStackViewBottomLayoutConstraint.isActive = !isHidden
    }
    
}

extension StatusView {
    
    @objc private func contentWarningActionButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.statusView(self, contentWarningActionButtonPressed: sender)
    }
    
    @objc private func pollVoteButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.statusView(self, pollVoteButtonPressed: sender)
    }
    
}

// MARK: - PlayerContainerViewDelegate
extension StatusView: PlayerContainerViewDelegate {
    func playerContainerView(_ playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
        delegate?.statusView(self, playerContainerView: playerContainerView, contentWarningOverlayViewDidPressed: contentWarningOverlayView)
    }
}

// MARK: - AvatarConfigurableView
extension StatusView: AvatarConfigurableView {
    static var configurableAvatarImageSize: CGSize { return Self.avatarImageSize }
    static var configurableAvatarImageCornerRadius: CGFloat { return 4 }
    var configurableAvatarImageView: UIImageView? { return nil }
    var configurableAvatarButton: UIButton? { return avatarButton }
    var configurableVerifiedBadgeImageView: UIImageView? { nil }
}

// MARK: - ActiveLabelDelegate
extension StatusView: ActiveLabelDelegate {
    func activeLabel(_ activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        delegate?.statusView(self, didSelectActiveEntity: activeLabel, entity: entity)
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct StatusView_Previews: PreviewProvider {
    
    static let avatarFlora = UIImage(named: "tiraya-adam")
    static let avatarMarkus = UIImage(named: "markus-spiske")
    
    static var previews: some View {
        Group {
            UIViewPreview(width: 375) {
                let statusView = StatusView()
                statusView.configure(
                    with: AvatarConfigurableViewConfiguration(
                        avatarImageURL: nil,
                        placeholderImage: avatarFlora
                    )
                )
                return statusView
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("Normal")
            UIViewPreview(width: 375) {
                let statusView = StatusView()
                statusView.headerContainerStackView.isHidden = false
                statusView.avatarButton.isHidden = true
                statusView.avatarStackedContainerButton.isHidden = false
                statusView.avatarStackedContainerButton.topLeadingAvatarStackedImageView.configure(
                    with: AvatarConfigurableViewConfiguration(
                        avatarImageURL: nil,
                        placeholderImage: avatarFlora
                    )
                )
                statusView.avatarStackedContainerButton.bottomTrailingAvatarStackedImageView.configure(
                    with: AvatarConfigurableViewConfiguration(
                        avatarImageURL: nil,
                        placeholderImage: avatarMarkus
                    )
                )
                return statusView
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("Reblog")
            UIViewPreview(width: 375) {
                let statusView = StatusView(frame: CGRect(x: 0, y: 0, width: 375, height: 500))
                statusView.configure(
                    with: AvatarConfigurableViewConfiguration(
                        avatarImageURL: nil,
                        placeholderImage: avatarFlora
                    )
                )
                statusView.headerContainerStackView.isHidden = false
                let images = MosaicImageView_Previews.images
                let imageViews = statusView.statusMosaicImageViewContainer.setupImageViews(count: 4, maxHeight: 162)
                for (i, imageView) in imageViews.enumerated() {
                    imageView.image = images[i]
                }
                statusView.statusMosaicImageViewContainer.isHidden = false
                statusView.statusMosaicImageViewContainer.contentWarningOverlayView.isHidden = true
                statusView.isStatusTextSensitive = false
                return statusView
            }
            .previewLayout(.fixed(width: 375, height: 380))
            .previewDisplayName("Image Meida")
            UIViewPreview(width: 375) {
                let statusView = StatusView(frame: CGRect(x: 0, y: 0, width: 375, height: 500))
                statusView.configure(
                    with: AvatarConfigurableViewConfiguration(
                        avatarImageURL: nil,
                        placeholderImage: avatarFlora
                    )
                )
                statusView.headerContainerStackView.isHidden = false
                statusView.isStatusTextSensitive = true
                statusView.setNeedsLayout()
                statusView.layoutIfNeeded()
                statusView.drawContentWarningImageView()
                statusView.updateContentWarningDisplay(isHidden: false)
                let images = MosaicImageView_Previews.images
                let imageViews = statusView.statusMosaicImageViewContainer.setupImageViews(count: 4, maxHeight: 162)
                for (i, imageView) in imageViews.enumerated() {
                    imageView.image = images[i]
                }
                statusView.statusMosaicImageViewContainer.isHidden = false
                return statusView
            }
            .previewLayout(.fixed(width: 375, height: 380))
            .previewDisplayName("Content Sensitive")
        }
    }
    
}

#endif

