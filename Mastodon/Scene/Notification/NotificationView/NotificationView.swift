//
//  NotificationView.swift
//  
//
//  Created by MainasuK on 2022-1-21.
//

import UIKit
import Combine
import MetaTextKit
import Meta
import MastodonCore
import MastodonAsset
import MastodonLocalization
import MastodonUI
import MastodonSDK

public protocol NotificationViewDelegate: AnyObject {
    func notificationView(_ notificationView: NotificationView, authorAvatarButtonDidPressed button: AvatarButton)
    func notificationView(_ notificationView: NotificationView, menuButton button: UIButton, didSelectAction action: MastodonMenu.Action)
    
    func notificationView(_ notificationView: NotificationView, acceptFollowRequestButtonDidPressed button: UIButton)
    func notificationView(_ notificationView: NotificationView, rejectFollowRequestButtonDidPressed button: UIButton)
    
    func notificationView(_ notificationView: NotificationView, statusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta)
    func notificationView(_ notificationView: NotificationView, statusView: StatusView, spoilerOverlayViewDidPressed overlayView: SpoilerOverlayView)
    func notificationView(_ notificationView: NotificationView, statusView: StatusView, mediaGridContainerView: MediaGridContainerView, mediaView: MediaView, didSelectMediaViewAt index: Int)
    func notificationView(_ notificationView: NotificationView, statusView: StatusView, pollTableView tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    func notificationView(_ notificationView: NotificationView, statusView: StatusView, pollVoteButtonPressed button: UIButton)
    func notificationView(_ notificationView: NotificationView, statusView: StatusView, actionToolbarContainer: ActionToolbarContainer, buttonDidPressed button: UIButton, action: ActionToolbarContainer.Action)

    func notificationView(_ notificationView: NotificationView, quoteStatusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton)
    func notificationView(_ notificationView: NotificationView, quoteStatusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta)
    func notificationView(_ notificationView: NotificationView, quoteStatusView: StatusView, spoilerOverlayViewDidPressed overlayView: SpoilerOverlayView)
    func notificationView(_ notificationView: NotificationView, quoteStatusView: StatusView, mediaGridContainerView: MediaGridContainerView, mediaView: MediaView, didSelectMediaViewAt index: Int)
    
    // a11y
    func notificationView(_ notificationView: NotificationView, accessibilityActivate: Void)
}

public final class NotificationView: UIView {
    
    static let containerLayoutMargin = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    
    public weak var delegate: NotificationViewDelegate?
    
    var _disposeBag = Set<AnyCancellable>()
    public var disposeBag = Set<AnyCancellable>()

    var notificationActions = [UIAccessibilityCustomAction]()
    var authorActions = [UIAccessibilityCustomAction]()

    let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }()
    
    // author
    let authorAdaptiveMarginContainerView = AdaptiveMarginContainerView()
    let authorContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        return stackView
    }()
    let authorContainerViewBottomPaddingView = UIView()
    
    // avatar
    public let avatarButton = AvatarButton()
    
    // author name
    public let authorNameLabel = MetaLabel(style: .statusName)
    
    // author username
    public let authorUsernameLabel = MetaLabel(style: .statusUsername)
    
    public let usernameTrialingDotLabel: MetaLabel = {
        let label = MetaLabel(style: .statusUsername)
        label.configure(content: PlaintextMetaContent(string: "·"))
        return label
    }()

    // timestamp
    public let dateLabel = MetaLabel(style: .statusUsername)
    
    public let menuButton: UIButton = {
        let button = HitTestExpandedButton(type: .system)
        button.tintColor = Asset.Colors.Label.secondary.color
        let image = UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 15)))
        button.setImage(image, for: .normal)
        button.accessibilityLabel = L10n.Common.Controls.Status.Actions.menu
        return button
    }()
    
    // notification type indicator imageView
    public let notificationTypeIndicatorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = Asset.Colors.Label.secondary.color
        return imageView
    }()
    
    // notification type indicator imageView
    public let notificationTypeIndicatorLabel = MetaLabel(style: .notificationTitle)
    
    // follow request
    let followRequestAdaptiveMarginContainerView = AdaptiveMarginContainerView()
    let followRequestContainerView = UIStackView()
    
    let acceptFollowRequestButtonShadowBackgroundContainer = ShadowBackgroundContainer()
    private(set) lazy var acceptFollowRequestButton: UIButton = {
        let button = HighlightDimmableButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.setTitle(L10n.Common.Controls.Actions.confirm, for: .normal)
        button.setImage(Asset.Editing.checkmark20.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.setBackgroundImage(.placeholder(color: Asset.Scene.Notification.confirmFollowRequestButtonBackground.color), for: .normal)
        button.setInsets(forContentPadding: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8), imageTitlePadding: 8)
        button.tintColor = .white
        button.layer.masksToBounds = true
        button.layer.cornerCurve = .continuous
        button.layer.cornerRadius = 10
        button.accessibilityLabel = L10n.Scene.Notification.FollowRequest.accept
        acceptFollowRequestButtonShadowBackgroundContainer.cornerRadius = 10
        acceptFollowRequestButtonShadowBackgroundContainer.shadowAlpha = 0.1
        button.addTarget(self, action: #selector(NotificationView.acceptFollowRequestButtonDidPressed(_:)), for: .touchUpInside)
        return button
    }()
    let acceptFollowRequestActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    
    let rejectFollowRequestButtonShadowBackgroundContainer = ShadowBackgroundContainer()
    private(set) lazy var rejectFollowRequestButton: UIButton = {
        let button = HighlightDimmableButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.black, for: .normal)
        button.setTitle(L10n.Common.Controls.Actions.delete, for: .normal)
        button.setImage(Asset.Circles.forbidden20.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.setInsets(forContentPadding: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8), imageTitlePadding: 8)
        button.setBackgroundImage(.placeholder(color: Asset.Scene.Notification.deleteFollowRequestButtonBackground.color), for: .normal)
        button.tintColor = .black
        button.layer.masksToBounds = true
        button.layer.cornerCurve = .continuous
        button.layer.cornerRadius = 10
        button.accessibilityLabel = L10n.Scene.Notification.FollowRequest.reject
        rejectFollowRequestButtonShadowBackgroundContainer.cornerRadius = 10
        rejectFollowRequestButtonShadowBackgroundContainer.shadowAlpha = 0.1
        button.addTarget(self, action: #selector(NotificationView.rejectFollowRequestButtonDidPressed(_:)), for: .touchUpInside)
        return button
    }()
    let rejectFollowRequestActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    
    // status
    public let statusView = StatusView()
    
    public let quoteStatusViewContainerView = UIView()
    public let quoteBackgroundView = UIView()
    public let quoteStatusView = StatusView()

    let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
        .share()
        .eraseToAnyPublisher()

    public func prepareForReuse() {
        disposeBag.removeAll()

        avatarButton.avatarImageView.image = nil
        avatarButton.avatarImageView.cancelTask()
        
        authorContainerViewBottomPaddingView.isHidden = true
        
        followRequestAdaptiveMarginContainerView.isHidden = true
        acceptFollowRequestButtonShadowBackgroundContainer.isHidden = false
        rejectFollowRequestButtonShadowBackgroundContainer.isHidden = false
        acceptFollowRequestActivityIndicatorView.stopAnimating()
        rejectFollowRequestActivityIndicatorView.stopAnimating()
        acceptFollowRequestButton.isUserInteractionEnabled = true
        rejectFollowRequestButton.isUserInteractionEnabled = true
        
        statusView.isHidden = true
        statusView.prepareForReuse()

        quoteStatusViewContainerView.isHidden = true
        quoteStatusView.prepareForReuse()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension NotificationView {
    private func _init() {
        // container: V - [ author container | (authorContainerViewBottomPaddingView) | statusView | quoteStatusView ]
        // containerStackView.layoutMargins = StatusView.containerLayoutMargin

        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        
        // author container: H - [ avatarButton | author meta container ]
        authorAdaptiveMarginContainerView.contentView = authorContainerView
        authorAdaptiveMarginContainerView.margin = StatusView.containerLayoutMargin
        containerStackView.addArrangedSubview(authorAdaptiveMarginContainerView)
        
        UIContentSizeCategory.publisher
            .sink { [weak self] category in
                guard let self = self else { return }
                self.authorContainerView.axis = category > .accessibilityLarge ? .vertical : .horizontal
                self.authorContainerView.alignment = category > .accessibilityLarge ? .leading : .center
            }
            .store(in: &_disposeBag)
        
        // avatarButton
        avatarButton.size = CGSize.authorAvatarButtonSize
        avatarButton.avatarImageView.imageViewSize = CGSize.authorAvatarButtonSize
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        authorContainerView.addArrangedSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.widthAnchor.constraint(equalToConstant: CGSize.authorAvatarButtonSize.width).priority(.required - 1),
            avatarButton.heightAnchor.constraint(equalToConstant: CGSize.authorAvatarButtonSize.height).priority(.required - 1),
        ])
        avatarButton.setContentHuggingPriority(.required - 1, for: .vertical)
        avatarButton.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        
        // authrMetaContainer: V - [ authorPrimaryContainer | authorSecondaryMetaContainer ]
        let authrMetaContainer = UIStackView()
        authrMetaContainer.axis = .vertical
        authrMetaContainer.spacing = 4
        authorContainerView.addArrangedSubview(authrMetaContainer)
        
        // authorPrimaryContainer: H - [ authorNameLabel | notificationTypeIndicatorLabel | (padding) | menuButton ]
        let authorPrimaryContainer = UIStackView()
        authorPrimaryContainer.axis = .horizontal
        authrMetaContainer.addArrangedSubview(authorPrimaryContainer)
        
        authorPrimaryContainer.addArrangedSubview(authorNameLabel)
        authorPrimaryContainer.addArrangedSubview(notificationTypeIndicatorLabel)
        authorPrimaryContainer.addArrangedSubview(UIView())
        authorPrimaryContainer.addArrangedSubview(menuButton)
        authorNameLabel.setContentHuggingPriority(.required - 10, for: .horizontal)
        authorNameLabel.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        notificationTypeIndicatorLabel.setContentHuggingPriority(.required - 4, for: .horizontal)
        notificationTypeIndicatorLabel.setContentCompressionResistancePriority(.required - 4, for: .horizontal)
        menuButton.setContentHuggingPriority(.required - 5, for: .horizontal)
        menuButton.setContentCompressionResistancePriority(.required - 5, for: .horizontal)
    
        // authorSecondaryMetaContainer: H - [ authorUsername | (padding) ]
        let authorSecondaryMetaContainer = UIStackView()
        authorSecondaryMetaContainer.axis = .horizontal
        authorSecondaryMetaContainer.spacing = 4
        authrMetaContainer.addArrangedSubview(authorSecondaryMetaContainer)
        authrMetaContainer.setCustomSpacing(4, after: authorSecondaryMetaContainer)

        authorSecondaryMetaContainer.addArrangedSubview(dateLabel)
        dateLabel.setContentHuggingPriority(.required - 1, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)

        authorSecondaryMetaContainer.addArrangedSubview(usernameTrialingDotLabel)
        usernameTrialingDotLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        authorSecondaryMetaContainer.addArrangedSubview(authorUsernameLabel)
        authorUsernameLabel.setContentHuggingPriority(.required - 1, for: .vertical)
        authorUsernameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        authorSecondaryMetaContainer.addArrangedSubview(UIView())

        // authorContainerViewBottomPaddingView
        authorContainerViewBottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(authorContainerViewBottomPaddingView)
        NSLayoutConstraint.activate([
            authorContainerViewBottomPaddingView.heightAnchor.constraint(equalToConstant: 16).priority(.required - 1),
        ])
        authorContainerViewBottomPaddingView.isHidden = true
        
        // follow reqeust
        followRequestAdaptiveMarginContainerView.contentView = followRequestContainerView
        followRequestAdaptiveMarginContainerView.margin = StatusView.containerLayoutMargin
        containerStackView.addArrangedSubview(followRequestAdaptiveMarginContainerView)
        
        acceptFollowRequestButton.translatesAutoresizingMaskIntoConstraints = false
        acceptFollowRequestButtonShadowBackgroundContainer.addSubview(acceptFollowRequestButton)
        acceptFollowRequestButton.pinToParent()
        
        rejectFollowRequestButton.translatesAutoresizingMaskIntoConstraints = false
        rejectFollowRequestButtonShadowBackgroundContainer.addSubview(rejectFollowRequestButton)
        rejectFollowRequestButton.pinToParent()
        
        followRequestContainerView.axis = .horizontal
        followRequestContainerView.distribution = .fillEqually
        followRequestContainerView.spacing = 16
        followRequestContainerView.isLayoutMarginsRelativeArrangement = true
        followRequestContainerView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)  // set bottom padding
        followRequestContainerView.addArrangedSubview(acceptFollowRequestButtonShadowBackgroundContainer)
        followRequestContainerView.addArrangedSubview(rejectFollowRequestButtonShadowBackgroundContainer)
        followRequestAdaptiveMarginContainerView.isHidden = true
        
        acceptFollowRequestActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        acceptFollowRequestButton.addSubview(acceptFollowRequestActivityIndicatorView)
        NSLayoutConstraint.activate([
            acceptFollowRequestActivityIndicatorView.centerXAnchor.constraint(equalTo: acceptFollowRequestButton.centerXAnchor),
            acceptFollowRequestActivityIndicatorView.centerYAnchor.constraint(equalTo: acceptFollowRequestButton.centerYAnchor),
        ])
        acceptFollowRequestActivityIndicatorView.color = .white
        acceptFollowRequestActivityIndicatorView.hidesWhenStopped = true
        acceptFollowRequestActivityIndicatorView.stopAnimating()
        
        rejectFollowRequestActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        rejectFollowRequestButton.addSubview(rejectFollowRequestActivityIndicatorView)
        NSLayoutConstraint.activate([
            rejectFollowRequestActivityIndicatorView.centerXAnchor.constraint(equalTo: rejectFollowRequestButton.centerXAnchor),
            rejectFollowRequestActivityIndicatorView.centerYAnchor.constraint(equalTo: rejectFollowRequestButton.centerYAnchor),
        ])
        rejectFollowRequestActivityIndicatorView.color = .black
        acceptFollowRequestActivityIndicatorView.hidesWhenStopped = true
        rejectFollowRequestActivityIndicatorView.stopAnimating()
        
        // statusView
        containerStackView.addArrangedSubview(statusView)
        statusView.setup(style: .notification)
        
        // quoteStatusView
        containerStackView.addArrangedSubview(quoteStatusViewContainerView)
        quoteStatusViewContainerView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)

        quoteBackgroundView.layoutMargins = UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0)
        quoteBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        quoteStatusViewContainerView.addSubview(quoteBackgroundView)
        NSLayoutConstraint.activate([
            quoteBackgroundView.topAnchor.constraint(equalTo: quoteStatusViewContainerView.layoutMarginsGuide.topAnchor),
            quoteBackgroundView.leadingAnchor.constraint(equalTo: quoteStatusViewContainerView.layoutMarginsGuide.leadingAnchor),
            quoteBackgroundView.trailingAnchor.constraint(equalTo: quoteStatusViewContainerView.layoutMarginsGuide.trailingAnchor),
            quoteBackgroundView.bottomAnchor.constraint(equalTo: quoteStatusViewContainerView.layoutMarginsGuide.bottomAnchor),
        ])
        quoteBackgroundView.backgroundColor = .secondarySystemBackground
        quoteBackgroundView.layer.masksToBounds = true
        quoteBackgroundView.layer.cornerCurve = .continuous
        quoteBackgroundView.layer.cornerRadius = 8
        quoteBackgroundView.layer.borderWidth = 1
        quoteBackgroundView.layer.borderColor = UIColor.separator.cgColor
        
        quoteStatusView.translatesAutoresizingMaskIntoConstraints = false
        quoteBackgroundView.addSubview(quoteStatusView)
        NSLayoutConstraint.activate([
            quoteStatusView.topAnchor.constraint(equalTo: quoteBackgroundView.layoutMarginsGuide.topAnchor),
            quoteStatusView.leadingAnchor.constraint(equalTo: quoteBackgroundView.layoutMarginsGuide.leadingAnchor),
            quoteStatusView.trailingAnchor.constraint(equalTo: quoteBackgroundView.layoutMarginsGuide.trailingAnchor),
            quoteStatusView.bottomAnchor.constraint(equalTo: quoteBackgroundView.layoutMarginsGuide.bottomAnchor),
        ])
        quoteStatusView.setup(style: .notificationQuote)
        
        statusView.isHidden = true
        quoteStatusViewContainerView.isHidden = true
        
        authorNameLabel.isUserInteractionEnabled = false
        authorUsernameLabel.isUserInteractionEnabled = false
        notificationTypeIndicatorLabel.isUserInteractionEnabled = false
        
        avatarButton.addTarget(self, action: #selector(NotificationView.avatarButtonDidPressed(_:)), for: .touchUpInside)
        
        statusView.delegate = self
        quoteStatusView.delegate = self

        isAccessibilityElement = true
    }
}

extension NotificationView {
    public override var accessibilityElements: [Any]? {
        get { [] }
        set {}
    }

    public override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            var actions = notificationActions
            actions += authorActions
            if !statusView.isHidden {
                actions += statusView.accessibilityCustomActions ?? []
            }
            if !quoteStatusViewContainerView.isHidden {
                actions += quoteStatusView.accessibilityCustomActions ?? []
            }
            return actions
        }
        set {}
    }
}

extension NotificationView {
    
    @objc private func avatarButtonDidPressed(_ sender: UIButton) {
        delegate?.notificationView(self, authorAvatarButtonDidPressed: avatarButton)
    }
    
    @objc private func acceptFollowRequestButtonDidPressed(_ sender: UIButton) {
        delegate?.notificationView(self, acceptFollowRequestButtonDidPressed: sender)
    }
    
    @objc private func rejectFollowRequestButtonDidPressed(_ sender: UIButton) {
        delegate?.notificationView(self, rejectFollowRequestButtonDidPressed: sender)
    }
    
}

extension NotificationView {
    
    public func setAuthorContainerBottomPaddingViewDisplay() {
        authorContainerViewBottomPaddingView.isHidden = false
    }
    
    public func setFollowRequestAdaptiveMarginContainerViewDisplay() {
        followRequestAdaptiveMarginContainerView.isHidden = false
    }

    public func setStatusViewDisplay() {
        statusView.isHidden = false
    }

    public func setQuoteStatusViewDisplay() {
        quoteStatusViewContainerView.isHidden = false
    }
    
}

// MARK: - AdaptiveContainerView
extension NotificationView: AdaptiveContainerView {
    public func updateContainerViewComponentsLayoutMarginsRelativeArrangementBehavior(isEnabled: Bool) {
        let margin = isEnabled ? StatusView.containerLayoutMargin : .zero
        authorAdaptiveMarginContainerView.margin = margin
        quoteStatusViewContainerView.layoutMargins.left = margin
        quoteStatusViewContainerView.layoutMargins.right = margin
        
        statusView.updateContainerViewComponentsLayoutMarginsRelativeArrangementBehavior(isEnabled: isEnabled)
        quoteStatusView.updateContainerViewComponentsLayoutMarginsRelativeArrangementBehavior(isEnabled: true)  // always set margins
    }
}

extension NotificationView {
    
    public struct AuthorMenuContext {
        public let name: String
        public let isMuting: Bool
        public let isBlocking: Bool
        public let isMyself: Bool
    }

    public func setupAuthorMenu(menuContext: AuthorMenuContext) -> (UIMenu, [UIAccessibilityCustomAction]) {
        var items = [
            MastodonMenu.Submenu(actions: [
                .muteUser(.init(name: menuContext.name,isMuting: menuContext.isMuting)),
                .blockUser(.init(name: menuContext.name,isBlocking: menuContext.isBlocking)),
                .reportUser(.init(name: menuContext.name))]
            )
        ]

        if menuContext.isMyself {
            items.append(MastodonMenu.Submenu(actions: [.deleteStatus]))
        }
        
        
        let menu = MastodonMenu.setupMenu(
            submenus: items,
            delegate: self
        )

        let accessibilityActions = MastodonMenu.setupAccessibilityActions(
            actions: items.compactMap { $0.actions } ,
            delegate: self
        )

        return (menu, accessibilityActions)
    }

}

// MARK: - StatusViewDelegate
extension NotificationView: StatusViewDelegate {
    public func statusView(_ statusView: StatusView, didTapCardWithURL url: URL) { assertionFailure() }
    public func statusView(_ statusView: StatusView, cardControl: StatusCardControl, didTapProfile account: Mastodon.Entity.Account) {
        // no op
    }

    public func statusView(_ statusView: StatusView, headerDidPressed header: UIView) {
        // do nothing
    }
    
    public func statusView(_ statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton) {
        switch statusView {
        case self.statusView:
            assertionFailure()
        case quoteStatusView:
            delegate?.notificationView(self, quoteStatusView: statusView, authorAvatarButtonDidPressed: button)
        default:
            assertionFailure()
        }
    }
    
    public func statusView(_ statusView: StatusView, contentSensitiveeToggleButtonDidPressed button: UIButton) {
        assertionFailure()
    }
    
    public func statusView(_ statusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta) {
        switch statusView {
        case self.statusView:
            delegate?.notificationView(self, statusView: statusView, metaText: metaText, didSelectMeta: meta)
        case quoteStatusView:
            delegate?.notificationView(self, quoteStatusView: statusView, metaText: metaText, didSelectMeta: meta)
        default:
            assertionFailure()
        }
    }
    
    public func statusView(_ statusView: StatusView, mediaGridContainerView: MediaGridContainerView, mediaView: MediaView, didSelectMediaViewAt index: Int) {
        switch statusView {
        case self.statusView:
            delegate?.notificationView(self, statusView: statusView, mediaGridContainerView: mediaGridContainerView, mediaView: mediaView, didSelectMediaViewAt: index)
        case quoteStatusView:
            delegate?.notificationView(self, quoteStatusView: statusView, mediaGridContainerView: mediaGridContainerView, mediaView: mediaView, didSelectMediaViewAt: index)
        default:
            assertionFailure()
        }
    }
    
    public func statusView(_ statusView: StatusView, pollTableView tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.notificationView(self, statusView: statusView, pollTableView: tableView, didSelectRowAt: indexPath)
    }
    
    public func statusView(_ statusView: StatusView, pollVoteButtonPressed button: UIButton) {
        delegate?.notificationView(self, statusView: statusView, pollVoteButtonPressed: button)
    }
    
    public func statusView(_ statusView: StatusView, actionToolbarContainer: ActionToolbarContainer, buttonDidPressed button: UIButton, action: ActionToolbarContainer.Action) {
        switch statusView {
        case self.statusView:
            delegate?.notificationView(self, statusView: statusView, actionToolbarContainer: actionToolbarContainer, buttonDidPressed: button, action: action)
        case quoteStatusView:
            assertionFailure()
        default:
            assertionFailure()
        }
    }
    
    public func statusView(_ statusView: StatusView, menuButton button: UIButton, didSelectAction action: MastodonMenu.Action) {
        assertionFailure()
    }
    
    public func statusView(_ statusView: StatusView, spoilerOverlayViewDidPressed overlayView: SpoilerOverlayView) {
        switch statusView {
        case self.statusView:
            delegate?.notificationView(self, statusView: statusView, spoilerOverlayViewDidPressed: overlayView)
        case quoteStatusView:
            delegate?.notificationView(self, quoteStatusView: statusView, spoilerOverlayViewDidPressed: overlayView)
        default:
            assertionFailure()
        }
    }
    
//    public func statusView(_ statusView: StatusView, spoilerBannerViewDidPressed bannerView: SpoilerBannerView) {
//        switch statusView {
//        case self.statusView:
//            delegate?.notificationView(self, statusView: statusView, spoilerBannerViewDidPressed: bannerView)
//        case quoteStatusView:
//            delegate?.notificationView(self, quoteStatusView: statusView, spoilerBannerViewDidPressed: bannerView)
//        default:
//            assertionFailure()
//        }
//    }
    
    public func statusView(_ statusView: StatusView, mediaGridContainerView: MediaGridContainerView, mediaSensitiveButtonDidPressed button: UIButton) {
        assertionFailure()
    }
    
    public func statusView(_ statusView: StatusView, statusMetricView: StatusMetricView, reblogButtonDidPressed button: UIButton) {
        assertionFailure()
    }
    
    public func statusView(_ statusView: StatusView, statusMetricView: StatusMetricView, favoriteButtonDidPressed button: UIButton) {
        assertionFailure()
    }

    public func statusView(_ statusView: StatusView, statusMetricView: StatusMetricView, showEditHistory button: UIButton) {
        assertionFailure()
    }
    
    public func statusView(_ statusView: StatusView, accessibilityActivate: Void) {
        assertionFailure()
    }
    
    public func statusView(_ statusView: StatusView, cardControl: StatusCardControl, didTapURL url: URL) {
        assertionFailure()
    }

    public func statusView(_ statusView: StatusView, cardControlMenu: StatusCardControl) -> [LabeledAction]? {
        assertionFailure()
        return nil
    }

}

// MARK: - MastodonMenuDelegate
extension NotificationView: MastodonMenuDelegate {
    public func menuAction(_ action: MastodonMenu.Action) {
        delegate?.notificationView(self, menuButton: menuButton, didSelectAction: action)
    }
}
