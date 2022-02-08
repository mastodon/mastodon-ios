//
//  NotificationView.swift
//  
//
//  Created by MainasuK on 2022-1-21.
//

import os.log
import UIKit
import Combine
import MetaTextKit
import Meta
import MastodonAsset
import MastodonLocalization

public protocol NotificationViewDelegate: AnyObject {
    func notificationView(_ notificationView: NotificationView, authorAvatarButtonDidPressed button: AvatarButton)
    func notificationView(_ notificationView: NotificationView, menuButton button: UIButton, didSelectAction action: MastodonMenu.Action)
    
    func notificationView(_ notificationView: NotificationView, statusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta)
    func notificationView(_ notificationView: NotificationView, statusView: StatusView, actionToolbarContainer: ActionToolbarContainer, buttonDidPressed button: UIButton, action: ActionToolbarContainer.Action)

    func notificationView(_ notificationView: NotificationView, quoteStatusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton)
    func notificationView(_ notificationView: NotificationView, quoteStatusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta)
}

public final class NotificationView: UIView {
    
    static let containerLayoutMargin = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    
    let logger = Logger(subsystem: "NotificationView", category: "View")
    
    public weak var delegate: NotificationViewDelegate?
    
    var _disposeBag = Set<AnyCancellable>()
    public var disposeBag = Set<AnyCancellable>()
    
    public private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(notificationView: self)
        return viewModel
    }()
    
    let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }()
    
    // author
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
        let image = UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 15)))
        button.setImage(image, for: .normal)
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
    
    public let statusView = StatusView()
    
    public let quoteStatusViewContainerView = UIView()
    public let quoteStatusView = StatusView()
    
    public func prepareForReuse() {
        disposeBag.removeAll()
        
        viewModel.authorAvatarImageURL = nil
        avatarButton.avatarImageView.cancelTask()
        
        authorContainerViewBottomPaddingView.isHidden = true
        
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
        containerStackView.layoutMargins = StatusView.containerLayoutMargin

        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        
        // author container: H - [ avatarButton | author meta container ]
        authorContainerView.preservesSuperviewLayoutMargins = true
        authorContainerView.isLayoutMarginsRelativeArrangement = true
        containerStackView.addArrangedSubview(authorContainerView)
        UIContentSizeCategory.publisher
            .sink { [weak self] category in
                guard let self = self else { return }
                self.authorContainerView.axis = category > .accessibilityLarge ? .vertical : .horizontal
                self.authorContainerView.alignment = category > .accessibilityLarge ? .leading : .center
            }
            .store(in: &_disposeBag)
        
        // avatarButton
        let authorAvatarButtonSize = CGSize(width: 46, height: 46)
        avatarButton.size = authorAvatarButtonSize
        avatarButton.avatarImageView.imageViewSize = authorAvatarButtonSize
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        authorContainerView.addArrangedSubview(avatarButton)
        NSLayoutConstraint.activate([
            avatarButton.widthAnchor.constraint(equalToConstant: authorAvatarButtonSize.width).priority(.required - 1),
            avatarButton.heightAnchor.constraint(equalToConstant: authorAvatarButtonSize.height).priority(.required - 1),
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

        authorSecondaryMetaContainer.addArrangedSubview(authorUsernameLabel)
        authorUsernameLabel.setContentHuggingPriority(.required - 8, for: .horizontal)
        authorUsernameLabel.setContentCompressionResistancePriority(.required - 8, for: .horizontal)
        authorSecondaryMetaContainer.addArrangedSubview(usernameTrialingDotLabel)
        usernameTrialingDotLabel.setContentHuggingPriority(.required - 2, for: .horizontal)
        usernameTrialingDotLabel.setContentCompressionResistancePriority(.required - 2, for: .horizontal)
        authorSecondaryMetaContainer.addArrangedSubview(dateLabel)
        dateLabel.setContentHuggingPriority(.required - 1, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        authorSecondaryMetaContainer.addArrangedSubview(UIView())
        
        // authorContainerViewBottomPaddingView
        authorContainerViewBottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(authorContainerViewBottomPaddingView)
        NSLayoutConstraint.activate([
            authorContainerViewBottomPaddingView.heightAnchor.constraint(equalToConstant: 16).priority(.required - 1),
        ])
        authorContainerViewBottomPaddingView.isHidden = true
        
        // statusView
        containerStackView.addArrangedSubview(statusView)
        statusView.setup(style: .notification)
        
        // quoteStatusView
        containerStackView.addArrangedSubview(quoteStatusViewContainerView)
        quoteStatusViewContainerView.layoutMargins = UIEdgeInsets(
            top: 0,
            left: StatusView.containerLayoutMargin.left,
            bottom: 16,
            right: StatusView.containerLayoutMargin.right
        )

        let quoteBackgroundView = UIView()
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
    }
}

extension NotificationView {
    @objc private func avatarButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.notificationView(self, authorAvatarButtonDidPressed: avatarButton)
    }
}

extension NotificationView {
    
    public func setAuthorContainerBottomPaddingViewDisplay() {
        authorContainerViewBottomPaddingView.isHidden = false
    }

    public func setStatusViewDisplay() {
        statusView.isHidden = false
    }

    public func setQuoteStatusViewDisplay() {
        quoteStatusViewContainerView.isHidden = false
    }
    
}

extension NotificationView {
    public typealias AuthorMenuContext = StatusView.AuthorMenuContext
    
    public func setupAuthorMenu(menuContext: AuthorMenuContext) -> UIMenu {
        var actions: [MastodonMenu.Action] = []
        
        actions = [
            .muteUser(.init(
                name: menuContext.name,
                isMuting: menuContext.isMuting
            )),
            .blockUser(.init(
                name: menuContext.name,
                isBlocking: menuContext.isBlocking
            )),
            .reportUser(
                .init(name: menuContext.name)
            ),
        ]
        
        if menuContext.isMyself {
            actions.append(.deleteStatus)
        }
        
        
        let menu = MastodonMenu.setupMenu(
            actions: actions,
            delegate: self
        )
        
        return menu
    }

}

// MARK: - StatusViewDelegate
extension NotificationView: StatusViewDelegate {
    
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
        assertionFailure()
    }
    
    public func statusView(_ statusView: StatusView, pollTableView tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assertionFailure()
    }
    
    public func statusView(_ statusView: StatusView, pollVoteButtonPressed button: UIButton) {
        assertionFailure()
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
        assertionFailure()
    }
    
    public func statusView(_ statusView: StatusView, spoilerBannerViewDidPressed bannerView: SpoilerBannerView) {
        assertionFailure()
    }
    
}

// MARK: - MastodonMenuDelegate
extension NotificationView: MastodonMenuDelegate {
    public func menuAction(_ action: MastodonMenu.Action) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        delegate?.notificationView(self, menuButton: menuButton, didSelectAction: action)
    }
}
