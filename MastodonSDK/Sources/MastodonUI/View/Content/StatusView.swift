//
//  StatusView.swift
//  
//
//  Created by MainasuK on 2022-1-10.
//

import os.log
import UIKit
import Combine
import MetaTextKit
import Meta
import MastodonAsset
import MastodonLocalization

public protocol StatusViewDelegate: AnyObject {
    func statusView(_ statusView: StatusView, headerDidPressed header: UIView)
    func statusView(_ statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton)
    func statusView(_ statusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta)
    func statusView(_ statusView: StatusView, mediaGridContainerView: MediaGridContainerView, mediaView: MediaView, didSelectMediaViewAt index: Int)
    func statusView(_ statusView: StatusView, pollTableView tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    func statusView(_ statusView: StatusView, pollVoteButtonPressed button: UIButton)
    func statusView(_ statusView: StatusView, actionToolbarContainer: ActionToolbarContainer, buttonDidPressed button: UIButton, action: ActionToolbarContainer.Action)
    func statusView(_ statusView: StatusView, menuButton button: UIButton, didSelectAction action: MastodonMenu.Action)
    func statusView(_ statusView: StatusView, spoilerOverlayViewDidPressed overlayView: SpoilerOverlayView)
    func statusView(_ statusView: StatusView, spoilerBannerViewDidPressed bannerView: SpoilerBannerView)
//    func statusView(_ statusView: StatusView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
//    func statusView(_ statusView: StatusView, playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
}

public final class StatusView: UIView {
    
    public static let containerLayoutMargin = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    
    let logger = Logger(subsystem: "StatusView", category: "View")
    
    private var _disposeBag = Set<AnyCancellable>() // which lifetime same to view scope
    public var disposeBag = Set<AnyCancellable>()
    
    public weak var delegate: StatusViewDelegate?
    
    public private(set) var style: Style?
    
    public private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(statusView: self)
        return viewModel
    }()
    
    let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }()
    
    // header
    let headerContainerView = UIView()
    
    // header icon
    let headerIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = Asset.Colors.Label.secondary.color
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    // header info
    let headerInfoLabel = MetaLabel(style: .statusHeader)
    
    // author
    let authorContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        return stackView
    }()
    
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
    
    // content
    let contentContainer = UIStackView()
    public let contentMetaText: MetaText = {
        let metaText = MetaText()
        metaText.textView.backgroundColor = .clear
        metaText.textView.isEditable = false
        metaText.textView.isSelectable = false
        metaText.textView.isScrollEnabled = false
        metaText.textView.textContainer.lineFragmentPadding = 0
        metaText.textView.textContainerInset = .zero
        metaText.textView.layer.masksToBounds = false
        metaText.textView.textDragInteraction?.isEnabled = false    // disable drag for link and attachment

        metaText.paragraphStyle = {
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 5
            style.paragraphSpacing = 8
            style.alignment = .natural
            return style
        }()
        metaText.textAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular)),
            .foregroundColor: Asset.Colors.Label.primary.color,
        ]
        metaText.linkAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold)),
            .foregroundColor: Asset.Colors.brandBlue.color,
        ]
        return metaText
    }()
    
    // content warning
    let spoilerOverlayView = SpoilerOverlayView()

    // media
    public let mediaContainerView = UIView()
    public let mediaGridContainerView = MediaGridContainerView()

    // poll
    public let pollContainerView = UIStackView()
    public let pollTableView: UITableView = {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        tableView.register(PollOptionTableViewCell.self, forCellReuseIdentifier: String(describing: PollOptionTableViewCell.self))
        tableView.isScrollEnabled = false
        tableView.estimatedRowHeight = 36
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        return tableView
    }()
    public var pollTableViewHeightLayoutConstraint: NSLayoutConstraint!
    public var pollTableViewDiffableDataSource: UITableViewDiffableDataSource<PollSection, PollItem>?
    
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
        label.text = "1 day left"
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
    let pollVoteActivityIndicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        indicatorView.hidesWhenStopped = true
        indicatorView.stopAnimating()
        return indicatorView
    }()
    
    // visibility
    public let statusVisibilityView = StatusVisibilityView()
    
    // spoiler banner
    public let spoilerBannerView = SpoilerBannerView()
    
    // toolbar
    public let actionToolbarContainer = ActionToolbarContainer()

    // metric
    public let statusMetricView = StatusMetricView()
    
    public func prepareForReuse() {
        disposeBag.removeAll()
        
        viewModel.objects.removeAll()
        viewModel.prepareForReuse()
        
        avatarButton.avatarImageView.cancelTask()
        mediaGridContainerView.prepareForReuse()
        if var snapshot = pollTableViewDiffableDataSource?.snapshot() {
            snapshot.deleteAllItems()
            if #available(iOS 15.0, *) {
                pollTableViewDiffableDataSource?.applySnapshotUsingReloadData(snapshot)
            } else {
                // Fallback on earlier versions
                pollTableViewDiffableDataSource?.apply(snapshot, animatingDifferences: false)
            }
        }
        
        headerContainerView.isHidden = true
        setSpoilerOverlayViewHidden(isHidden: true)
        mediaContainerView.isHidden = true
        pollContainerView.isHidden = true
        statusVisibilityView.isHidden = true
        setSpoilerBannerViewHidden(isHidden: true)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension StatusView {
    private func _init() {
        // container
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        // header
        headerIconImageView.isUserInteractionEnabled = false
        headerInfoLabel.isUserInteractionEnabled = false
        let headerTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        headerTapGestureRecognizer.addTarget(self, action: #selector(StatusView.headerDidPressed(_:)))
        headerContainerView.addGestureRecognizer(headerTapGestureRecognizer)
        
        // avatar button
        avatarButton.addTarget(self, action: #selector(StatusView.authorAvatarButtonDidPressed(_:)), for: .touchUpInside)
        authorNameLabel.isUserInteractionEnabled = false
        authorUsernameLabel.isUserInteractionEnabled = false
        
        
        // dateLabel
        dateLabel.isUserInteractionEnabled = false
        
        // content warning
        let spoilerOverlayViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        spoilerOverlayView.addGestureRecognizer(spoilerOverlayViewTapGestureRecognizer)
        spoilerOverlayViewTapGestureRecognizer.addTarget(self, action: #selector(StatusView.spoilerOverlayViewTapGestureRecognizerHandler(_:)))
        
        // content
        contentMetaText.textView.delegate = self
        contentMetaText.textView.linkDelegate = self
        
        // media
        mediaGridContainerView.delegate = self
        
        // poll
        pollTableView.translatesAutoresizingMaskIntoConstraints = false
        pollTableViewHeightLayoutConstraint = pollTableView.heightAnchor.constraint(equalToConstant: 44.0).priority(.required - 1)
        NSLayoutConstraint.activate([
            pollTableViewHeightLayoutConstraint,
        ])
        pollTableView.delegate = self
        pollVoteButton.addTarget(self, action: #selector(StatusView.pollVoteButtonDidPressed(_:)), for: .touchUpInside)
        
        // statusSpoilerBannerView
        let spoilerBannerViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        spoilerBannerView.addGestureRecognizer(spoilerBannerViewTapGestureRecognizer)
        spoilerBannerViewTapGestureRecognizer.addTarget(self, action: #selector(StatusView.spoilerBannerViewTapGestureRecognizerHandler(_:)))
        
        // toolbar
        actionToolbarContainer.delegate = self
    }
}

extension StatusView {
    
    @objc private func headerDidPressed(_ sender: UITapGestureRecognizer) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        assert(sender.view === headerContainerView)
        delegate?.statusView(self, headerDidPressed: headerContainerView)
    }

    @objc private func authorAvatarButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.statusView(self, authorAvatarButtonDidPressed: avatarButton)
    }
    
    
    @objc private func pollVoteButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.statusView(self, pollVoteButtonPressed: pollVoteButton)
    }
    
    @objc private func spoilerOverlayViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.statusView(self, spoilerOverlayViewDidPressed: spoilerOverlayView)
    }
    
    @objc private func spoilerBannerViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.statusView(self, spoilerBannerViewDidPressed: spoilerBannerView)
    }
    
}

extension StatusView {
    
    public func setup(style: Style) {
        guard self.style == nil else {
            assertionFailure("Should only setup once")
            return
        }
        self.style = style
        style.layout(statusView: self)
        prepareForReuse()
    }
    
    public enum Style {
        case inline
        case plain
        case report
        case notification
        case notificationQuote
        case composeStatusReplica
        case composeStatusAuthor
    }
}

extension StatusView.Style {
    
    func layout(statusView: StatusView) {
        switch self {
        case .inline:               inline(statusView: statusView)
        case .plain:                plain(statusView: statusView)
        case .report:               report(statusView: statusView)
        case .notification:         notification(statusView: statusView)
        case .notificationQuote:    notificationQuote(statusView: statusView)
        case .composeStatusReplica: composeStatusReplica(statusView: statusView)
        case .composeStatusAuthor:  composeStatusAuthor(statusView: statusView)
        }
    }
    
    private func base(statusView: StatusView) {
        // container: V - [ header container | author container | content container | media container | pollTableView | actionToolbarContainer ]
        statusView.containerStackView.layoutMargins = StatusView.containerLayoutMargin
        
        // header container: H - [ icon | label ]
        statusView.headerContainerView.preservesSuperviewLayoutMargins = true
        statusView.containerStackView.addArrangedSubview(statusView.headerContainerView)
        statusView.headerIconImageView.translatesAutoresizingMaskIntoConstraints = false
        statusView.headerInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        statusView.headerContainerView.addSubview(statusView.headerIconImageView)
        statusView.headerContainerView.addSubview(statusView.headerInfoLabel)
        NSLayoutConstraint.activate([
            statusView.headerIconImageView.leadingAnchor.constraint(equalTo: statusView.headerContainerView.layoutMarginsGuide.leadingAnchor),
            statusView.headerIconImageView.heightAnchor.constraint(equalTo: statusView.headerInfoLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
            statusView.headerIconImageView.widthAnchor.constraint(equalTo: statusView.headerIconImageView.heightAnchor, multiplier: 1.0).priority(.required - 1),
            statusView.headerInfoLabel.topAnchor.constraint(equalTo: statusView.headerContainerView.topAnchor),
            statusView.headerInfoLabel.leadingAnchor.constraint(equalTo: statusView.headerIconImageView.trailingAnchor, constant: 6),
            statusView.headerInfoLabel.trailingAnchor.constraint(equalTo: statusView.headerContainerView.layoutMarginsGuide.trailingAnchor),
            statusView.headerInfoLabel.bottomAnchor.constraint(equalTo: statusView.headerContainerView.bottomAnchor),
            statusView.headerInfoLabel.centerYAnchor.constraint(equalTo: statusView.headerIconImageView.centerYAnchor),
        ])
        statusView.headerInfoLabel.setContentHuggingPriority(.required, for: .vertical)
        statusView.headerIconImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        statusView.headerIconImageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        statusView.headerIconImageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        statusView.headerIconImageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // author container: H - [ avatarButton | author meta container | contentWarningToggleButton ]
        statusView.authorContainerView.preservesSuperviewLayoutMargins = true
        statusView.authorContainerView.isLayoutMarginsRelativeArrangement = true
        statusView.containerStackView.addArrangedSubview(statusView.authorContainerView)
        UIContentSizeCategory.publisher
            .sink { category in
                statusView.authorContainerView.axis = category > .accessibilityLarge ? .vertical : .horizontal
                statusView.authorContainerView.alignment = category > .accessibilityLarge ? .leading : .center
            }
            .store(in: &statusView._disposeBag)
        
        // avatarButton
        let authorAvatarButtonSize = CGSize(width: 46, height: 46)
        statusView.avatarButton.size = authorAvatarButtonSize
        statusView.avatarButton.avatarImageView.imageViewSize = authorAvatarButtonSize
        statusView.avatarButton.translatesAutoresizingMaskIntoConstraints = false
        statusView.authorContainerView.addArrangedSubview(statusView.avatarButton)
        NSLayoutConstraint.activate([
            statusView.avatarButton.widthAnchor.constraint(equalToConstant: authorAvatarButtonSize.width).priority(.required - 1),
            statusView.avatarButton.heightAnchor.constraint(equalToConstant: authorAvatarButtonSize.height).priority(.required - 1),
        ])
        statusView.avatarButton.setContentHuggingPriority(.required - 1, for: .vertical)
        statusView.avatarButton.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        
        // authrMetaContainer: V - [ authorPrimaryMetaContainer | authorSecondaryMetaContainer ]
        let authorMetaContainer = UIStackView()
        authorMetaContainer.axis = .vertical
        authorMetaContainer.spacing = 4
        statusView.authorContainerView.addArrangedSubview(authorMetaContainer)
        
        // authorPrimaryMetaContainer: H - [ authorNameLabel | (padding) | menuButton ]
        let authorPrimaryMetaContainer = UIStackView()
        authorPrimaryMetaContainer.axis = .horizontal
        authorMetaContainer.addArrangedSubview(authorPrimaryMetaContainer)
        
        // authorNameLabel
        authorPrimaryMetaContainer.addArrangedSubview(statusView.authorNameLabel)
        authorPrimaryMetaContainer.addArrangedSubview(UIView())
        // menuButton
        authorPrimaryMetaContainer.addArrangedSubview(statusView.menuButton)
        statusView.menuButton.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        // authorSecondaryMetaContainer: H - [ authorUsername | usernameTrialingDotLabel | dateLabel | (padding) ]
        let authorSecondaryMetaContainer = UIStackView()
        authorSecondaryMetaContainer.axis = .horizontal
        authorSecondaryMetaContainer.spacing = 4
        authorMetaContainer.addArrangedSubview(authorSecondaryMetaContainer)

        authorSecondaryMetaContainer.addArrangedSubview(statusView.authorUsernameLabel)
        statusView.authorUsernameLabel.setContentHuggingPriority(.required - 8, for: .horizontal)
        statusView.authorUsernameLabel.setContentCompressionResistancePriority(.required - 8, for: .horizontal)
        authorSecondaryMetaContainer.addArrangedSubview(statusView.usernameTrialingDotLabel)
        statusView.usernameTrialingDotLabel.setContentHuggingPriority(.required - 2, for: .horizontal)
        statusView.usernameTrialingDotLabel.setContentCompressionResistancePriority(.required - 2, for: .horizontal)
        authorSecondaryMetaContainer.addArrangedSubview(statusView.dateLabel)
        statusView.dateLabel.setContentHuggingPriority(.required - 1, for: .horizontal)
        statusView.dateLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        authorSecondaryMetaContainer.addArrangedSubview(UIView())
        
        // content container: V - [ contentMetaText ]
        statusView.contentContainer.axis = .vertical
        statusView.contentContainer.spacing = 12
        statusView.contentContainer.distribution = .fill
        statusView.contentContainer.alignment = .top
        
        statusView.contentContainer.preservesSuperviewLayoutMargins = true
        statusView.contentContainer.isLayoutMarginsRelativeArrangement = true
        statusView.containerStackView.addArrangedSubview(statusView.contentContainer)
        statusView.contentContainer.setContentHuggingPriority(.required - 1, for: .vertical)
        statusView.contentContainer.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        
        // status content
        statusView.contentContainer.addArrangedSubview(statusView.contentMetaText.textView)
        
        statusView.spoilerOverlayView.translatesAutoresizingMaskIntoConstraints = false
        statusView.containerStackView.addSubview(statusView.spoilerOverlayView)
        NSLayoutConstraint.activate([
            statusView.contentContainer.topAnchor.constraint(equalTo: statusView.spoilerOverlayView.topAnchor),
            statusView.contentContainer.leadingAnchor.constraint(equalTo: statusView.spoilerOverlayView.leadingAnchor),
            statusView.contentContainer.trailingAnchor.constraint(equalTo: statusView.spoilerOverlayView.trailingAnchor),
            statusView.contentContainer.bottomAnchor.constraint(equalTo: statusView.spoilerOverlayView.bottomAnchor),
        ])
        
        // media container: V - [ mediaGridContainerView ]
        statusView.containerStackView.addArrangedSubview(statusView.mediaContainerView)
        
        statusView.mediaGridContainerView.translatesAutoresizingMaskIntoConstraints = false
        statusView.mediaContainerView.addSubview(statusView.mediaGridContainerView)
        NSLayoutConstraint.activate([
            statusView.mediaGridContainerView.topAnchor.constraint(equalTo: statusView.mediaContainerView.topAnchor),
            statusView.mediaGridContainerView.leadingAnchor.constraint(equalTo: statusView.mediaContainerView.leadingAnchor),
            statusView.mediaGridContainerView.trailingAnchor.constraint(equalTo: statusView.mediaContainerView.trailingAnchor),
            statusView.mediaGridContainerView.bottomAnchor.constraint(equalTo: statusView.mediaContainerView.bottomAnchor),
        ])
        
        // pollContainerView: V - [ pollTableView | pollStatusStackView ]
        statusView.pollContainerView.axis = .vertical
        statusView.pollContainerView.preservesSuperviewLayoutMargins = true
        statusView.pollContainerView.isLayoutMarginsRelativeArrangement = true
        statusView.containerStackView.addArrangedSubview(statusView.pollContainerView)
        
        // pollTableView
        statusView.pollContainerView.addArrangedSubview(statusView.pollTableView)
        
        // pollStatusStackView
        statusView.pollStatusStackView.axis = .horizontal
        statusView.pollContainerView.addArrangedSubview(statusView.pollStatusStackView)
        
        statusView.pollStatusStackView.addArrangedSubview(statusView.pollVoteCountLabel)
        statusView.pollStatusStackView.addArrangedSubview(statusView.pollStatusDotLabel)
        statusView.pollStatusStackView.addArrangedSubview(statusView.pollCountdownLabel)
        statusView.pollStatusStackView.addArrangedSubview(statusView.pollVoteButton)
        statusView.pollStatusStackView.addArrangedSubview(statusView.pollVoteActivityIndicatorView)
        statusView.pollVoteCountLabel.setContentHuggingPriority(.defaultHigh + 2, for: .horizontal)
        statusView.pollStatusDotLabel.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
        statusView.pollCountdownLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        statusView.pollVoteButton.setContentHuggingPriority(.defaultHigh + 3, for: .horizontal)
        
        // statusVisibilityView
        statusView.statusVisibilityView.preservesSuperviewLayoutMargins = true
        statusView.containerStackView.addArrangedSubview(statusView.statusVisibilityView)
        
        statusView.spoilerBannerView.preservesSuperviewLayoutMargins = true
        statusView.containerStackView.addArrangedSubview(statusView.spoilerBannerView)
        
        // action toolbar
        statusView.actionToolbarContainer.configure(for: .inline)
        statusView.actionToolbarContainer.preservesSuperviewLayoutMargins = true
        statusView.containerStackView.addArrangedSubview(statusView.actionToolbarContainer)
    }
    
    func inline(statusView: StatusView) {
        base(statusView: statusView)
        
        statusView.statusVisibilityView.removeFromSuperview()
    }
    
    func plain(statusView: StatusView) {
        // container: V - [ … | statusMetricView ]
        base(statusView: statusView)      // override the base style
        
        // statusMetricView
        statusView.statusMetricView.layoutMargins = StatusView.containerLayoutMargin
        statusView.containerStackView.addArrangedSubview(statusView.statusMetricView)
        UIContentSizeCategory.publisher
            .sink { category in
                statusView.statusMetricView.containerStackView.axis = category > .accessibilityLarge ? .vertical : .horizontal
                statusView.statusMetricView.containerStackView.alignment = category > .accessibilityLarge ? .leading : .fill
            }
            .store(in: &statusView._disposeBag)
    }
    
    func report(statusView: StatusView) {
        base(statusView: statusView)      // override the base style

        statusView.menuButton.removeFromSuperview()
        statusView.statusVisibilityView.removeFromSuperview()
        statusView.actionToolbarContainer.removeFromSuperview()
    }
    
    func notification(statusView: StatusView) {
        base(statusView: statusView)      // override the base style
        
        statusView.headerContainerView.removeFromSuperview()
        statusView.authorContainerView.removeFromSuperview()
        statusView.statusVisibilityView.removeFromSuperview()
        statusView.spoilerBannerView.removeFromSuperview()
    }
    
    func notificationQuote(statusView: StatusView) {
        base(statusView: statusView)      // override the base style
        
        statusView.contentContainer.layoutMargins.bottom = 16        // fix contentText align to edge issue
        statusView.menuButton.removeFromSuperview()
        statusView.statusVisibilityView.removeFromSuperview()
        statusView.spoilerBannerView.removeFromSuperview()
        statusView.actionToolbarContainer.removeFromSuperview()
    }
    
    func composeStatusReplica(statusView: StatusView) {
        base(statusView: statusView)
        
        statusView.avatarButton.isUserInteractionEnabled = false
        statusView.menuButton.removeFromSuperview()
        statusView.statusVisibilityView.removeFromSuperview()
        statusView.spoilerBannerView.removeFromSuperview()
        statusView.actionToolbarContainer.removeFromSuperview()
    }
    
    func composeStatusAuthor(statusView: StatusView) {
        base(statusView: statusView)
        
        statusView.avatarButton.isUserInteractionEnabled = false
        statusView.menuButton.removeFromSuperview()
        statusView.usernameTrialingDotLabel.removeFromSuperview()
        statusView.dateLabel.removeFromSuperview()
        statusView.contentContainer.removeFromSuperview()
        statusView.spoilerOverlayView.removeFromSuperview()
        statusView.mediaContainerView.removeFromSuperview()
        statusView.pollContainerView.removeFromSuperview()
        statusView.statusVisibilityView.removeFromSuperview()
        statusView.spoilerBannerView.removeFromSuperview()
        statusView.actionToolbarContainer.removeFromSuperview()
    }
    
}

extension StatusView {
    func setHeaderDisplay() {
        headerContainerView.isHidden = false
    }
    
    func setSpoilerOverlayViewHidden(isHidden: Bool) {
        spoilerOverlayView.isHidden = isHidden
        spoilerOverlayView.setComponentHidden(isHidden)
    }
    
    func setMediaDisplay() {
        mediaContainerView.isHidden = false
    }
    
    func setPollDisplay() {
        pollContainerView.isHidden = false
    }
    
    func setVisibilityDisplay() {
        statusVisibilityView.isHidden = false
    }
    
    func setSpoilerBannerViewHidden(isHidden: Bool) {
        spoilerBannerView.isHidden = isHidden
    }
    
    // content text Width
    public var contentMaxLayoutWidth: CGFloat {
        let inset = contentLayoutInset
        return frame.width - inset.left - inset.right
    }
    
    public var contentLayoutInset: UIEdgeInsets {
        // TODO: adaptive iPad regular horizontal size class
        return .zero
    }
}

extension StatusView {
    
    public struct AuthorMenuContext {
        public let name: String
        
        public let isMuting: Bool
        public let isBlocking: Bool
        public let isMyself: Bool
    }
    
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

// MARK: - UITextViewDelegate
extension StatusView: UITextViewDelegate {

    public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch textView {
        case contentMetaText.textView:
            return false
        default:
            assertionFailure()
            return true
        }
    }

    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch textView {
        case contentMetaText.textView:
            return false
        default:
            assertionFailure()
            return true
        }
    }
}

// MARK: - MetaTextViewDelegate
extension StatusView: MetaTextViewDelegate {
    public func metaTextView(_ metaTextView: MetaTextView, didSelectMeta meta: Meta) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        switch metaTextView {
        case contentMetaText.textView:
            delegate?.statusView(self, metaText: contentMetaText, didSelectMeta: meta)
        default:
            assertionFailure()
            break
        }
    }
}

// MARK: - MediaGridContainerViewDelegate
extension StatusView: MediaGridContainerViewDelegate {
    public func mediaGridContainerView(_ container: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
        delegate?.statusView(self, mediaGridContainerView: container, mediaView: mediaView, didSelectMediaViewAt: index)
    }
    
    public func mediaGridContainerView(_ container: MediaGridContainerView, toggleContentWarningOverlayViewDisplay contentWarningOverlayView: ContentWarningOverlayView) {
        fatalError()
    }
}

// MARK: - UITableViewDelegate
extension StatusView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): select \(indexPath.debugDescription)")
        
        switch tableView {
        case pollTableView:
            delegate?.statusView(self, pollTableView: tableView, didSelectRowAt: indexPath)
        default:
            assertionFailure()
        }
    }
}

// MARK: ActionToolbarContainerDelegate
extension StatusView: ActionToolbarContainerDelegate {
    public func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, buttonDidPressed button: UIButton, action: ActionToolbarContainer.Action) {
        delegate?.statusView(self, actionToolbarContainer: actionToolbarContainer, buttonDidPressed: button, action: action)
    }
}

// MARK: - MastodonMenuDelegate
extension StatusView: MastodonMenuDelegate {
    public func menuAction(_ action: MastodonMenu.Action) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.statusView(self, menuButton: menuButton, didSelectAction: action)
    }
}

#if DEBUG
import SwiftUI

struct StatusView_Preview: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            let statusView = StatusView()
            statusView.setup(style: .inline)
            configureStub(statusView: statusView)
            return statusView
        }
    }
    
    static func configureStub(statusView: StatusView) {
        // statusView.viewModel
    }
}
#endif
