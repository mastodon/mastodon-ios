//
//  StatusView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/28.
//

import os.log
import UIKit
import Combine
import AVKit
import ActiveLabel
import AlamofireImage
import FLAnimatedImage
import MetaTextView
import Meta
import MastodonSDK

// TODO:
// import LinkPresentation

protocol StatusViewDelegate: AnyObject {
    func statusView(_ statusView: StatusView, headerInfoLabelDidPressed label: UILabel)
    func statusView(_ statusView: StatusView, avatarImageViewDidPressed imageView: UIImageView)
    func statusView(_ statusView: StatusView, revealContentWarningButtonDidPressed button: UIButton)
    func statusView(_ statusView: StatusView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
    func statusView(_ statusView: StatusView, playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
    func statusView(_ statusView: StatusView, pollVoteButtonPressed button: UIButton)
    func statusView(_ statusView: StatusView, activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity)
    func statusView(_ statusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta)
}

final class StatusView: UIView {

    let logger = Logger(subsystem: "StatusView", category: "logic")
    
    var statusPollTableViewHeightObservation: NSKeyValueObservation?
    var pollCountdownSubscription: AnyCancellable?
    
    static let avatarImageSize = CGSize(width: 42, height: 42)
    static let avatarImageCornerRadius: CGFloat = 4
    static let avatarToLabelSpacing: CGFloat = 5
    static let contentWarningBlurRadius: CGFloat = 12
    static let containerStackViewSpacing: CGFloat = 10
    
    weak var delegate: StatusViewDelegate?

    var pollTableViewDataSource: UITableViewDiffableDataSource<PollSection, PollItem>?
    var pollTableViewHeightLayoutConstraint: NSLayoutConstraint!
    
    let containerStackView = UIStackView()
    let headerContainerView = UIView()
    let authorContainerView = UIView()
    
    static let reblogIconImage: UIImage = {
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
    
    let headerIconLabel: UILabel = {
        let label = UILabel()
        label.attributedText = StatusView.iconAttributedString(image: StatusView.reblogIconImage)
        return label
    }()
    
    let headerInfoLabel: ActiveLabel = {
        let label = ActiveLabel(style: .statusHeader)
        label.text = "Bob reblogged"
        label.layer.masksToBounds = false
        return label
    }()
    
    let avatarView: UIView = {
        let view = UIView()
        view.isAccessibilityElement = true
        view.accessibilityTraits = .button
        view.accessibilityLabel = L10n.Common.Controls.Status.showUserProfile
        return view
    }()
    let avatarImageView: FLAnimatedImageView = {
        let imageView = FLAnimatedImageView()
        return imageView
    }()
    let avatarStackedContainerButton: AvatarStackContainerButton = AvatarStackContainerButton()
    
    let nameLabel: ActiveLabel = {
        let label = ActiveLabel(style: .statusName)
        return label
    }()
    
    let nameTrialingDotLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.secondary.color
        label.font = .systemFont(ofSize: 17)
        label.text = "·"
        label.isAccessibilityElement = false
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = "@alice"
        label.isAccessibilityElement = false
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = "1d"
        return label
    }()
    
    let revealContentWarningButton: UIButton = {
        let button = HighlightDimmableButton()
        button.setImage(UIImage(systemName: "eye", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)), for: .normal)
        button.tintColor = Asset.Colors.brandBlue.color
        return button
    }()
    
    let visibilityImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = Asset.Colors.Label.secondary.color
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let statusContainerStackView = UIStackView()    
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
        label.text = L10n.Plural.Count.vote(0)
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
        button.setTitleColor(Asset.Colors.brandBlue.color, for: .normal)
        button.setTitleColor(Asset.Colors.brandBlue.color.withAlphaComponent(0.8), for: .highlighted)
        button.setTitleColor(Asset.Colors.Button.disabled.color, for: .disabled)
        button.isEnabled = false
        return button
    }()
    
    // do not use visual effect view due to we blur text only without background
    let contentWarningOverlayView: ContentWarningOverlayView = {
        let contentWarningOverlayView = ContentWarningOverlayView()
        contentWarningOverlayView.configure(style: .contentWarning)
        contentWarningOverlayView.layer.masksToBounds = true
        return contentWarningOverlayView
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
    
    let contentMetaText: MetaText = {
        let metaText = MetaText()
        metaText.textView.backgroundColor = .clear
        metaText.textView.isEditable = false
        metaText.textView.isSelectable = false
        metaText.textView.isScrollEnabled = false
        metaText.textView.textContainer.lineFragmentPadding = 0
        metaText.textView.textContainerInset = .zero
        metaText.textView.layer.masksToBounds = false
        metaText.textView.textDragInteraction?.isEnabled = false    // disable drag for link and attachment

        let paragraphStyle: NSMutableParagraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 5
            return style
        }()
        metaText.textAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular)),
            .foregroundColor: Asset.Colors.Label.primary.color,
            .paragraphStyle: paragraphStyle,
        ]
        metaText.linkAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold)),
            .foregroundColor: Asset.Colors.brandBlue.color,
            .paragraphStyle: paragraphStyle,
        ]
        return metaText
    }()

    private let headerInfoLabelTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    
    var isRevealing = true

    // TODO:
    // let linkPreview = LPLinkView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    deinit {
        statusPollTableViewHeightObservation = nil
    }

}

extension StatusView {
    
    func _init() {
        // container: [reblog | author | status | action toolbar]
        // note: do not set spacing for nested stackView to avoid SDK layout conflict issue
        containerStackView.axis = .vertical
        // containerStackView.spacing = 10
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        containerStackView.setContentHuggingPriority(.required - 1, for: .vertical)
        containerStackView.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        
        // header container: [icon | info]
        let headerContainerStackView = UIStackView()
        headerContainerStackView.axis = .horizontal
        headerContainerStackView.spacing = 4
        headerContainerStackView.addArrangedSubview(headerIconLabel)
        headerContainerStackView.addArrangedSubview(headerInfoLabel)
        headerIconLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        headerContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        headerContainerView.addSubview(headerContainerStackView)
        NSLayoutConstraint.activate([
            headerContainerStackView.topAnchor.constraint(equalTo: headerContainerView.topAnchor),
            headerContainerStackView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            headerContainerStackView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            headerContainerView.bottomAnchor.constraint(equalTo: headerContainerStackView.bottomAnchor, constant: StatusView.containerStackViewSpacing).priority(.defaultHigh),
        ])
        containerStackView.addArrangedSubview(headerContainerView)
        defer {
            containerStackView.bringSubviewToFront(headerContainerView)
        }
        
        // author container: [avatar | author meta container | reveal button]
        let authorContainerStackView = UIStackView()
        authorContainerStackView.axis = .horizontal
        authorContainerStackView.spacing = StatusView.avatarToLabelSpacing
        authorContainerStackView.distribution = .fill

        // avatar
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        authorContainerStackView.addArrangedSubview(avatarView)
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: StatusView.avatarImageSize.width).priority(.required - 1),
            avatarView.heightAnchor.constraint(equalToConstant: StatusView.avatarImageSize.height).priority(.required - 1),
        ])
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),
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
        
        // title container: [display name | "·" | date | padding | visibility]
        let titleContainerStackView = UIStackView()
        authorMetaContainerStackView.addArrangedSubview(titleContainerStackView)
        titleContainerStackView.axis = .horizontal
        titleContainerStackView.alignment = .center
        titleContainerStackView.spacing = 4
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        titleContainerStackView.addArrangedSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.heightAnchor.constraint(equalToConstant: 22).priority(.defaultHigh),
        ])
        titleContainerStackView.alignment = .firstBaseline
        titleContainerStackView.addArrangedSubview(nameTrialingDotLabel)
        titleContainerStackView.addArrangedSubview(dateLabel)
        titleContainerStackView.addArrangedSubview(UIView()) // padding
        titleContainerStackView.addArrangedSubview(visibilityImageView)
        nameLabel.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
        nameTrialingDotLabel.setContentHuggingPriority(.defaultHigh + 2, for: .horizontal)
        nameTrialingDotLabel.setContentCompressionResistancePriority(.required - 2, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        visibilityImageView.setContentHuggingPriority(.required - 1, for: .horizontal)
        visibilityImageView.setContentHuggingPriority(.required - 1, for: .vertical)
        visibilityImageView.setContentCompressionResistancePriority(.required - 1, for: .horizontal)

        // subtitle container: [username]
        let subtitleContainerStackView = UIStackView()
        authorMetaContainerStackView.addArrangedSubview(subtitleContainerStackView)
        subtitleContainerStackView.axis = .horizontal
        subtitleContainerStackView.addArrangedSubview(usernameLabel)

        // reveal button
        authorContainerStackView.addArrangedSubview(revealContentWarningButton)
        revealContentWarningButton.setContentHuggingPriority(.required - 2, for: .horizontal)
        
        authorContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        authorContainerView.addSubview(authorContainerStackView)
        NSLayoutConstraint.activate([
            authorContainerStackView.topAnchor.constraint(equalTo: authorContainerView.topAnchor),
            authorContainerStackView.leadingAnchor.constraint(equalTo: authorContainerView.leadingAnchor),
            authorContainerStackView.trailingAnchor.constraint(equalTo: authorContainerView.trailingAnchor),
            authorContainerView.bottomAnchor.constraint(equalTo: authorContainerStackView.bottomAnchor, constant: StatusView.containerStackViewSpacing).priority(.required - 1),
        ])
        containerStackView.addArrangedSubview(authorContainerView)
        
        // status container: [status | image / video | audio | poll | poll status] (overlay with content warning)
        containerStackView.addArrangedSubview(statusContainerStackView)
        statusContainerStackView.axis = .vertical
        statusContainerStackView.spacing = 10
        
        // content warning overlay
        contentWarningOverlayView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addSubview(contentWarningOverlayView)
        NSLayoutConstraint.activate([
            statusContainerStackView.topAnchor.constraint(equalTo: contentWarningOverlayView.topAnchor).priority(.defaultHigh + 10),
            statusContainerStackView.leftAnchor.constraint(equalTo: contentWarningOverlayView.leftAnchor).priority(.defaultHigh),
            contentWarningOverlayView.rightAnchor.constraint(equalTo: statusContainerStackView.rightAnchor).priority(.defaultHigh),
            contentWarningOverlayView.bottomAnchor.constraint(equalTo: statusContainerStackView.bottomAnchor).priority(.defaultHigh),
        ])
        // avoid overlay behind other views
        defer {
            containerStackView.bringSubviewToFront(authorContainerView)
        }
        
        // status
        statusContainerStackView.addArrangedSubview(contentMetaText.textView)
        contentMetaText.textView.setContentCompressionResistancePriority(.required - 1, for: .vertical)

        // image
        statusContainerStackView.addArrangedSubview(statusMosaicImageViewContainer)
        
        // audio
        audioView.translatesAutoresizingMaskIntoConstraints = false
        statusContainerStackView.addArrangedSubview(audioView)
        NSLayoutConstraint.activate([
            audioView.heightAnchor.constraint(equalToConstant: 44).priority(.defaultHigh)
        ])
        
        // video & gifv
        statusContainerStackView.addArrangedSubview(playerContainerView)
        
        pollTableView.translatesAutoresizingMaskIntoConstraints = false
        statusContainerStackView.addArrangedSubview(pollTableView)
        pollTableViewHeightLayoutConstraint = pollTableView.heightAnchor.constraint(equalToConstant: 44.0).priority(.required - 1)
        NSLayoutConstraint.activate([
            pollTableViewHeightLayoutConstraint,
        ])
        
        statusPollTableViewHeightObservation = pollTableView.observe(\.contentSize, options: .new, changeHandler: { [weak self] tableView, _ in
            guard let self = self else { return }
            guard self.pollTableView.contentSize.height != .zero else {
                self.pollTableViewHeightLayoutConstraint.constant = 44
                return
            }
            self.pollTableViewHeightLayoutConstraint.constant = self.pollTableView.contentSize.height
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
        
        // action toolbar container
        containerStackView.addArrangedSubview(actionToolbarContainer)
        containerStackView.sendSubviewToBack(actionToolbarContainer)
        actionToolbarContainer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        actionToolbarContainer.setContentHuggingPriority(.required - 1, for: .vertical)

        headerContainerView.isHidden = true
        statusMosaicImageViewContainer.isHidden = true
        pollTableView.isHidden = true
        pollStatusStackView.isHidden = true
        audioView.isHidden = true
        playerContainerView.isHidden = true
        
        avatarStackedContainerButton.isHidden = true
        contentWarningOverlayView.isHidden = true

        contentMetaText.textView.delegate = self
        contentMetaText.textView.linkDelegate = self
        playerContainerView.delegate = self
        contentWarningOverlayView.delegate = self
        
        headerInfoLabelTapGestureRecognizer.addTarget(self, action: #selector(StatusView.headerInfoLabelTapGestureRecognizerHandler(_:)))
        headerInfoLabel.isUserInteractionEnabled = true
        headerInfoLabel.addGestureRecognizer(headerInfoLabelTapGestureRecognizer)

        let avatarImageViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        avatarImageViewTapGestureRecognizer.addTarget(self, action: #selector(StatusView.avatarImageViewDidPressed(_:)))
        avatarImageView.addGestureRecognizer(avatarImageViewTapGestureRecognizer)
        avatarImageView.isUserInteractionEnabled = true

        avatarStackedContainerButton.addTarget(self, action: #selector(StatusView.avatarStackedContainerButtonDidPressed(_:)), for: .touchUpInside)
        revealContentWarningButton.addTarget(self, action: #selector(StatusView.revealContentWarningButtonDidPressed(_:)), for: .touchUpInside)
        pollVoteButton.addTarget(self, action: #selector(StatusView.pollVoteButtonPressed(_:)), for: .touchUpInside)
    }
    
}

extension StatusView {

    func updateContentWarningDisplay(isHidden: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        func updateOverlayView() {
            contentWarningOverlayView.contentOverlayView.alpha = isHidden ? 0 : 1
            contentWarningOverlayView.isUserInteractionEnabled = !isHidden
        }

        contentWarningOverlayView.blurContentWarningTitleLabel.isHidden = isHidden

        if animated {
            UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut) {
                updateOverlayView()
            } completion: { _ in
                completion!()
            }
        } else {
            updateOverlayView()
            completion?()
        }
    }
    
    func updateRevealContentWarningButton(isRevealing: Bool) {
        self.isRevealing = isRevealing
        
        if !isRevealing {
            let image = traitCollection.userInterfaceStyle == .light ? UIImage(systemName: "eye")! : UIImage(systemName: "eye.fill")
            revealContentWarningButton.setImage(image, for: .normal)
        } else {
            let image = traitCollection.userInterfaceStyle == .light ? UIImage(systemName: "eye.slash")! : UIImage(systemName: "eye.slash.fill")
            revealContentWarningButton.setImage(image, for: .normal)
        }
        // TODO: a11y
    }

    func updateVisibility(visibility: Mastodon.Entity.Status.Visibility) {
        switch visibility {
        case .public:
            visibilityImageView.image = UIImage(systemName: "globe", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .regular))
        case .private:
            visibilityImageView.image = UIImage(systemName: "person.3", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .regular))
        case .unlisted:
            visibilityImageView.image = UIImage(systemName: "eye.slash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .regular))
        case .direct:
            visibilityImageView.image = UIImage(systemName: "at", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .regular))
        case ._other:
            visibilityImageView.image = nil
        }
    }
    
}

extension StatusView {
    
    @objc private func headerInfoLabelTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.statusView(self, headerInfoLabelDidPressed: headerInfoLabel)
    }
    
    @objc private func avatarImageViewDidPressed(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.statusView(self, avatarImageViewDidPressed: avatarImageView)
    }
    
    @objc private func avatarStackedContainerButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.statusView(self, avatarImageViewDidPressed: avatarStackedContainerButton.topLeadingAvatarStackedImageView)
    }
    
    @objc private func revealContentWarningButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.statusView(self, revealContentWarningButtonDidPressed: sender)
    }
    
    @objc private func pollVoteButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.statusView(self, pollVoteButtonPressed: sender)
    }
    
}

// MARK: - MetaTextViewDelegate
extension StatusView: MetaTextViewDelegate {
    func metaTextView(_ metaTextView: MetaTextView, didSelectLink link: URL) {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        switch metaTextView {
        case contentMetaText.textView:
            guard let meta = Meta(url: link) else { return }
            delegate?.statusView(self, metaText: contentMetaText, didSelectMeta: meta)
        default:
            assertionFailure()
            break
        }
    }
}

// MARK: - UITextViewDelegate
extension StatusView: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch textView {
        case contentMetaText.textView:
            return false
        default:
            assertionFailure()
            return true
        }
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch textView {
        case contentMetaText.textView:
            return false
        default:
            assertionFailure()
            return true
        }
    }
}

// MARK: - ActiveLabelDelegate
extension StatusView: ActiveLabelDelegate {
    func activeLabel(_ activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: select entity: %s", ((#file as NSString).lastPathComponent), #line, #function, entity.primaryText)
        delegate?.statusView(self, activeLabel: activeLabel, didSelectActiveEntity: entity)
    }
}

// MARK: - ContentWarningOverlayViewDelegate
extension StatusView: ContentWarningOverlayViewDelegate {
    func contentWarningOverlayViewDidPressed(_ contentWarningOverlayView: ContentWarningOverlayView) {
        assert(contentWarningOverlayView === self.contentWarningOverlayView)
        delegate?.statusView(self, contentWarningOverlayViewDidPressed: contentWarningOverlayView)
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
    var configurableAvatarImageView: UIImageView? { avatarImageView }
    var configurableAvatarButton: UIButton? { nil }
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
                statusView.headerContainerView.isHidden = false
                statusView.avatarImageView.isHidden = true
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
                statusView.headerContainerView.isHidden = false
                let images = MosaicImageView_Previews.images
                let mosaics = statusView.statusMosaicImageViewContainer.setupImageViews(count: 4, maxSize: CGSize(width: 375, height: 162))
                for (i, mosaic) in mosaics.enumerated() {
                    mosaic.imageView.image = images[i]
                }
                statusView.statusMosaicImageViewContainer.isHidden = false
                statusView.statusMosaicImageViewContainer.contentWarningOverlayView.isHidden = true
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
                statusView.headerContainerView.isHidden = false
                statusView.setNeedsLayout()
                statusView.layoutIfNeeded()
                statusView.updateContentWarningDisplay(isHidden: false, animated: false)
                let images = MosaicImageView_Previews.images
                let mosaics = statusView.statusMosaicImageViewContainer.setupImageViews(count: 4, maxSize: CGSize(width: 375, height: 162))
                for (i, mosaic) in mosaics.enumerated() {
                    mosaic.imageView.image = images[i]
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

