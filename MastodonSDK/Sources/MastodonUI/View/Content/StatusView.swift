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
import MastodonCore
import MastodonLocalization

public extension CGSize {
    static let authorAvatarButtonSize = CGSize(width: 46, height: 46)
}

public protocol StatusViewDelegate: AnyObject {
    func statusView(_ statusView: StatusView, headerDidPressed header: UIView)
    func statusView(_ statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton)
    func statusView(_ statusView: StatusView, contentSensitiveeToggleButtonDidPressed button: UIButton)
    func statusView(_ statusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta)
    func statusView(_ statusView: StatusView, didTapCardWithURL url: URL)
    func statusView(_ statusView: StatusView, mediaGridContainerView: MediaGridContainerView, mediaView: MediaView, didSelectMediaViewAt index: Int)
    func statusView(_ statusView: StatusView, pollTableView tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    func statusView(_ statusView: StatusView, pollVoteButtonPressed button: UIButton)
    func statusView(_ statusView: StatusView, actionToolbarContainer: ActionToolbarContainer, buttonDidPressed button: UIButton, action: ActionToolbarContainer.Action)
    func statusView(_ statusView: StatusView, menuButton button: UIButton, didSelectAction action: MastodonMenu.Action)
    func statusView(_ statusView: StatusView, spoilerOverlayViewDidPressed overlayView: SpoilerOverlayView)
    func statusView(_ statusView: StatusView, mediaGridContainerView: MediaGridContainerView, mediaSensitiveButtonDidPressed button: UIButton)
    func statusView(_ statusView: StatusView, statusMetricView: StatusMetricView, reblogButtonDidPressed button: UIButton)
    func statusView(_ statusView: StatusView, statusMetricView: StatusMetricView, favoriteButtonDidPressed button: UIButton)
    func statusView(_ statusView: StatusView, cardControl: StatusCardControl, didTapURL url: URL)
    func statusView(_ statusView: StatusView, cardControlMenu: StatusCardControl) -> UIMenu?
    
    // a11y
    func statusView(_ statusView: StatusView, accessibilityActivate: Void)
}

public final class StatusView: UIView {
    
    public static let containerLayoutMargin: CGFloat = 16
    
    let logger = Logger(subsystem: "StatusView", category: "View")
    
    private var _disposeBag = Set<AnyCancellable>() // which lifetime same to view scope
    public var disposeBag = Set<AnyCancellable>()
    
    public weak var delegate: StatusViewDelegate?
    
    public private(set) var style: Style?

    // accessibility actions
    var toolbarActions = [UIAccessibilityCustomAction]()

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
    let headerAdaptiveMarginContainerView = AdaptiveMarginContainerView()
    public let headerContainerView = UIView()
    
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
    let authorAdaptiveMarginContainerView = AdaptiveMarginContainerView()
    public let authorView = StatusAuthorView()

    // content
    let contentAdaptiveMarginContainerView = AdaptiveMarginContainerView()
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
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular)),
            .foregroundColor: Asset.Colors.Label.primary.color,
        ]
        metaText.linkAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular)),
            .foregroundColor: Asset.Colors.brand.color,
        ]
        return metaText
    }()

    public let statusCardControl = StatusCardControl()
    
    // content warning
    public let spoilerOverlayView = SpoilerOverlayView()

    // media
    public let mediaContainerView = UIView()
    public let mediaGridContainerView = MediaGridContainerView()

    // poll
    let pollAdaptiveMarginContainerView = AdaptiveMarginContainerView()
    let pollContainerView = UIStackView()
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
    
    public let pollStatusStackView = UIStackView()
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
        label.isAccessibilityElement = false
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
        button.setTitleColor(Asset.Colors.brand.color, for: .normal)
        button.setTitleColor(Asset.Colors.brand.color.withAlphaComponent(0.8), for: .highlighted)
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
    let isTranslatingLoadingView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.stopAnimating()
        return activityIndicatorView
    }()
    private let translatedInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .regular))
        label.textColor = Asset.Colors.Label.secondary.color
        label.numberOfLines = 0
        return label
    }()
    lazy var translatedInfoView: UIView = {
        let containerView = UIView()
    
        let revertButton = UIButton()
        revertButton.titleLabel?.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .bold))
        revertButton.setTitle(L10n.Common.Controls.Status.Translation.showOriginal, for: .normal)
        revertButton.setTitleColor(Asset.Colors.brand.color, for: .normal)
        revertButton.addAction(UIAction { [weak self] _ in
            self?.revertTranslation()
        }, for: .touchUpInside)
        
        [containerView, translatedInfoLabel, revertButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        [translatedInfoLabel, revertButton].forEach {
            containerView.addSubview($0)
        }
        
        translatedInfoLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        revertButton.setContentHuggingPriority(.required, for: .horizontal)
        
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 24),
            translatedInfoLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            translatedInfoLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            translatedInfoLabel.trailingAnchor.constraint(equalTo: revertButton.leadingAnchor, constant: -16),
            revertButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            revertButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            revertButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        containerView.isHidden = true
        
        return containerView
    }()

    // toolbar
    let actionToolbarAdaptiveMarginContainerView = AdaptiveMarginContainerView()
    public let actionToolbarContainer = ActionToolbarContainer()

    // metric
    let statusMetricViewAdaptiveMarginContainerView = AdaptiveMarginContainerView()
    public let statusMetricView = StatusMetricView()
    
    // filter hint
    public let filterHintLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = L10n.Common.Controls.Timeline.filtered
        label.font = .systemFont(ofSize: 17, weight: .regular)
        return label
    }()
    
    public func prepareForReuse() {
        disposeBag.removeAll()
        
        viewModel.objects.removeAll()
        viewModel.prepareForReuse()
        
        authorView.avatarButton.avatarImageView.cancelTask()
        if var snapshot = pollTableViewDiffableDataSource?.snapshot() {
            snapshot.deleteAllItems()
            if #available(iOS 15.0, *) {
                pollTableViewDiffableDataSource?.applySnapshotUsingReloadData(snapshot)
            } else {
                // Fallback on earlier versions
                pollTableViewDiffableDataSource?.apply(snapshot, animatingDifferences: false)
            }
        }
        
        setHeaderDisplay(isDisplay: false)
        setContentSensitiveeToggleButtonDisplay(isDisplay: false)
        setSpoilerOverlayViewHidden(isHidden: true)
        setMediaDisplay(isDisplay: false)
        setPollDisplay(isDisplay: false)
        setFilterHintLabelDisplay(isDisplay: false)
        setStatusCardControlDisplay(isDisplay: false)
        setupTranslationIndicator()
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
        containerStackView.pinToParent()
        
        // header
        headerIconImageView.isUserInteractionEnabled = false
        headerInfoLabel.isUserInteractionEnabled = false
        headerInfoLabel.isAccessibilityElement = false
        let headerTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        headerTapGestureRecognizer.addTarget(self, action: #selector(StatusView.headerDidPressed(_:)))
        headerContainerView.addGestureRecognizer(headerTapGestureRecognizer)

        // author view
        authorView.statusView = self

        // content warning
        let spoilerOverlayViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        spoilerOverlayView.addGestureRecognizer(spoilerOverlayViewTapGestureRecognizer)
        spoilerOverlayViewTapGestureRecognizer.addTarget(self, action: #selector(StatusView.spoilerOverlayViewTapGestureRecognizerHandler(_:)))
        
        // content
        contentMetaText.textView.delegate = self
        contentMetaText.textView.linkDelegate = self

        // card
        statusCardControl.addTarget(self, action: #selector(statusCardControlPressed), for: .touchUpInside)
        statusCardControl.delegate = self

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
        
        // toolbar
        actionToolbarContainer.delegate = self
        
        // statusMetricView
        statusMetricView.delegate = self
    }
}

extension StatusView {
    
    @objc private func headerDidPressed(_ sender: UITapGestureRecognizer) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        assert(sender.view === headerContainerView)
        delegate?.statusView(self, headerDidPressed: headerContainerView)
    }
    
    @objc private func pollVoteButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.statusView(self, pollVoteButtonPressed: pollVoteButton)
    }
    
    @objc private func spoilerOverlayViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.statusView(self, spoilerOverlayViewDidPressed: spoilerOverlayView)
    }

    @objc private func statusCardControlPressed(_ sender: StatusCardControl) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        guard let url = viewModel.card?.url else { return }
        delegate?.statusView(self, didTapCardWithURL: url)
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

        statusView.authorView.layout(style: self)
    }
    
    private func base(statusView: StatusView) {
        // container: V - [ header container | author container | content container | media container | pollTableView | actionToolbarContainer ]
        
        // header container: H - [ icon | label ]
        statusView.headerAdaptiveMarginContainerView.contentView = statusView.headerContainerView
        statusView.headerAdaptiveMarginContainerView.margin = StatusView.containerLayoutMargin
        statusView.containerStackView.addArrangedSubview(statusView.headerAdaptiveMarginContainerView)
        
        statusView.headerIconImageView.translatesAutoresizingMaskIntoConstraints = false
        statusView.headerInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        statusView.headerContainerView.addSubview(statusView.headerIconImageView)
        statusView.headerContainerView.addSubview(statusView.headerInfoLabel)
        NSLayoutConstraint.activate([
            statusView.headerIconImageView.leadingAnchor.constraint(equalTo: statusView.headerContainerView.leadingAnchor),
            statusView.headerIconImageView.heightAnchor.constraint(equalTo: statusView.headerInfoLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
            statusView.headerIconImageView.widthAnchor.constraint(equalTo: statusView.headerInfoLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
            statusView.headerInfoLabel.topAnchor.constraint(equalTo: statusView.headerContainerView.topAnchor),
            statusView.headerInfoLabel.leadingAnchor.constraint(equalTo: statusView.headerIconImageView.trailingAnchor, constant: 6),
            statusView.headerInfoLabel.trailingAnchor.constraint(equalTo: statusView.headerContainerView.trailingAnchor),
            statusView.headerInfoLabel.bottomAnchor.constraint(equalTo: statusView.headerContainerView.bottomAnchor),
            statusView.headerInfoLabel.centerYAnchor.constraint(equalTo: statusView.headerIconImageView.centerYAnchor),
        ])
        statusView.headerInfoLabel.setContentHuggingPriority(.required - 1, for: .vertical)
        statusView.headerInfoLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        statusView.headerIconImageView.setContentHuggingPriority(.defaultLow - 100, for: .vertical)
        statusView.headerIconImageView.setContentHuggingPriority(.defaultLow - 100, for: .horizontal)
        statusView.headerIconImageView.setContentCompressionResistancePriority(.defaultLow - 100, for: .vertical)
        statusView.headerIconImageView.setContentCompressionResistancePriority(.defaultLow - 100, for: .horizontal)

        statusView.authorAdaptiveMarginContainerView.contentView = statusView.authorView
        statusView.authorAdaptiveMarginContainerView.margin = StatusView.containerLayoutMargin
        statusView.containerStackView.addArrangedSubview(statusView.authorAdaptiveMarginContainerView)

        // content container: V - [ contentMetaText statusCardControl ]
        statusView.contentContainer.axis = .vertical
        statusView.contentContainer.spacing = 12
        statusView.contentContainer.distribution = .fill
        statusView.contentContainer.alignment = .fill

        statusView.contentAdaptiveMarginContainerView.contentView = statusView.contentContainer
        statusView.contentAdaptiveMarginContainerView.margin = StatusView.containerLayoutMargin
        statusView.containerStackView.addArrangedSubview(statusView.contentAdaptiveMarginContainerView)
        statusView.contentContainer.setContentHuggingPriority(.required - 1, for: .vertical)
        statusView.contentContainer.setContentCompressionResistancePriority(.required - 1, for: .vertical)

        // status content
        statusView.contentContainer.addArrangedSubview(statusView.contentMetaText.textView)
        statusView.contentContainer.addArrangedSubview(statusView.statusCardControl)

        // translated info
        statusView.containerStackView.addArrangedSubview(statusView.isTranslatingLoadingView)
        statusView.containerStackView.addArrangedSubview(statusView.translatedInfoView)

        statusView.spoilerOverlayView.translatesAutoresizingMaskIntoConstraints = false
        statusView.containerStackView.addSubview(statusView.spoilerOverlayView)
        statusView.contentContainer.pinTo(to: statusView.spoilerOverlayView)

        // media container: V - [ mediaGridContainerView ]
        statusView.mediaContainerView.translatesAutoresizingMaskIntoConstraints = false
        statusView.containerStackView.addArrangedSubview(statusView.mediaContainerView)
        NSLayoutConstraint.activate([
            statusView.mediaContainerView.leadingAnchor.constraint(equalTo: statusView.containerStackView.leadingAnchor),
            statusView.mediaContainerView.trailingAnchor.constraint(equalTo: statusView.containerStackView.trailingAnchor),
        ])

        statusView.mediaGridContainerView.translatesAutoresizingMaskIntoConstraints = false
        statusView.mediaContainerView.addSubview(statusView.mediaGridContainerView)
        statusView.mediaGridContainerView.pinToParent()

        // pollContainerView: V - [ pollTableView | pollStatusStackView ]
        statusView.pollAdaptiveMarginContainerView.contentView = statusView.pollContainerView
        statusView.pollAdaptiveMarginContainerView.margin = StatusView.containerLayoutMargin
        statusView.pollContainerView.axis = .vertical
        statusView.containerStackView.addArrangedSubview(statusView.pollAdaptiveMarginContainerView)

        // pollTableView
        statusView.pollContainerView.addArrangedSubview(statusView.pollTableView)

        // pollStatusStackView: H - [ pollVoteCountLabel | pollCountdownLabel | pollVoteButton ]
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
        
        // action toolbar
        statusView.actionToolbarAdaptiveMarginContainerView.contentView = statusView.actionToolbarContainer
        statusView.actionToolbarAdaptiveMarginContainerView.margin = StatusView.containerLayoutMargin
        statusView.actionToolbarContainer.configure(for: .inline)
        statusView.containerStackView.addArrangedSubview(statusView.actionToolbarAdaptiveMarginContainerView)
        
        // filterHintLabel
        statusView.filterHintLabel.translatesAutoresizingMaskIntoConstraints = false
        statusView.addSubview(statusView.filterHintLabel)
        NSLayoutConstraint.activate([
            statusView.filterHintLabel.centerXAnchor.constraint(equalTo: statusView.containerStackView.centerXAnchor),
            statusView.filterHintLabel.centerYAnchor.constraint(equalTo: statusView.containerStackView.centerYAnchor),
        ])
    }
    
    func inline(statusView: StatusView) {
        base(statusView: statusView)
    }
    
    func plain(statusView: StatusView) {
        // container: V - [ … | statusMetricView ]
        base(statusView: statusView)      // override the base style
        
        // statusMetricView
        statusView.statusMetricViewAdaptiveMarginContainerView.contentView = statusView.statusMetricView
        statusView.statusMetricViewAdaptiveMarginContainerView.margin = StatusView.containerLayoutMargin
        statusView.containerStackView.addArrangedSubview(statusView.statusMetricViewAdaptiveMarginContainerView)

        UIContentSizeCategory.publisher
            .sink { category in
                statusView.statusMetricView.containerStackView.axis = category > .accessibilityLarge ? .vertical : .horizontal
                statusView.statusMetricView.containerStackView.alignment = category > .accessibilityLarge ? .leading : .fill
            }
            .store(in: &statusView._disposeBag)
    }
    
    func report(statusView: StatusView) {
        base(statusView: statusView)      // override the base style

        statusView.actionToolbarAdaptiveMarginContainerView.removeFromSuperview()
    }
    
    func notification(statusView: StatusView) {
        base(statusView: statusView)      // override the base style
        
        statusView.headerAdaptiveMarginContainerView.removeFromSuperview()
        statusView.authorAdaptiveMarginContainerView.removeFromSuperview()
        statusView.statusCardControl.removeFromSuperview()
    }
    
    func notificationQuote(statusView: StatusView) {
        base(statusView: statusView)      // override the base style
        
        statusView.contentAdaptiveMarginContainerView.bottomLayoutConstraint?.constant = 16     // fix bottom margin missing issue
        statusView.pollAdaptiveMarginContainerView.bottomLayoutConstraint?.constant = 16        // fix bottom margin missing issue
        statusView.actionToolbarAdaptiveMarginContainerView.removeFromSuperview()
        statusView.statusCardControl.removeFromSuperview()
    }
    
    func composeStatusReplica(statusView: StatusView) {
        base(statusView: statusView)
        
        statusView.actionToolbarAdaptiveMarginContainerView.removeFromSuperview()
    }
    
    func composeStatusAuthor(statusView: StatusView) {
        base(statusView: statusView)
        
        statusView.contentAdaptiveMarginContainerView.removeFromSuperview()
        statusView.spoilerOverlayView.removeFromSuperview()
        statusView.mediaContainerView.removeFromSuperview()
        statusView.pollAdaptiveMarginContainerView.removeFromSuperview()
        statusView.actionToolbarAdaptiveMarginContainerView.removeFromSuperview()
    }
    
}

extension StatusView {
    func setHeaderDisplay(isDisplay: Bool = true) {
        headerAdaptiveMarginContainerView.isHidden = !isDisplay
    }
    
    func setContentSensitiveeToggleButtonDisplay(isDisplay: Bool = true) {
        authorView.contentSensitiveeToggleButton.isHidden = !isDisplay
    }
    
    func setSpoilerOverlayViewHidden(isHidden: Bool) {
        spoilerOverlayView.isHidden = isHidden
        spoilerOverlayView.setComponentHidden(isHidden)
    }
    
    func setMediaDisplay(isDisplay: Bool = true) {
        mediaContainerView.isHidden = !isDisplay
    }
    
    func setPollDisplay(isDisplay: Bool = true) {
        pollAdaptiveMarginContainerView.isHidden = !isDisplay
    }
    
    func setFilterHintLabelDisplay(isDisplay: Bool = true) {
        filterHintLabel.isHidden = !isDisplay
    }

    func setStatusCardControlDisplay(isDisplay: Bool = true) {
        statusCardControl.isHidden = !isDisplay
    }
    
    // container width
    public var contentMaxLayoutWidth: CGFloat {
        return frame.width
    }

}

extension StatusView {
    public override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            (contentMetaText.textView.accessibilityCustomActions ?? [])
            + toolbarActions
            + (authorView.accessibilityCustomActions ?? [])
        }
        set { }
    }
}

// MARK: - AdaptiveContainerView
extension StatusView: AdaptiveContainerView {
    public func updateContainerViewComponentsLayoutMarginsRelativeArrangementBehavior(isEnabled: Bool) {
        let margin = isEnabled ? StatusView.containerLayoutMargin : .zero
        headerAdaptiveMarginContainerView.margin = margin
        authorAdaptiveMarginContainerView.margin = margin
        contentAdaptiveMarginContainerView.margin = margin
        pollAdaptiveMarginContainerView.margin = margin
        actionToolbarAdaptiveMarginContainerView.margin = margin
        statusMetricViewAdaptiveMarginContainerView.margin = margin
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
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): meta: \(String(describing: meta))")
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
    
    public func mediaGridContainerView(_ container: MediaGridContainerView, mediaSensitiveButtonDidPressed button: UIButton) {
        delegate?.statusView(self, mediaGridContainerView: container, mediaSensitiveButtonDidPressed: button)
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

    public func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, showReblogs action: UIAccessibilityCustomAction) {
        delegate?.statusView(self, statusMetricView: statusMetricView, reblogButtonDidPressed: statusMetricView.reblogButton)
    }

    public func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, showFavorites action: UIAccessibilityCustomAction) {
        delegate?.statusView(self, statusMetricView: statusMetricView, favoriteButtonDidPressed: statusMetricView.favoriteButton)
    }
}

// MARK: - StatusMetricViewDelegate
extension StatusView: StatusMetricViewDelegate {
    func statusMetricView(_ statusMetricView: StatusMetricView, reblogButtonDidPressed button: UIButton) {
        delegate?.statusView(self, statusMetricView: statusMetricView, reblogButtonDidPressed: button)
    }
    
    func statusMetricView(_ statusMetricView: StatusMetricView, favoriteButtonDidPressed button: UIButton) {
        delegate?.statusView(self, statusMetricView: statusMetricView, favoriteButtonDidPressed: button)
    }
}

// MARK: - MastodonMenuDelegate
extension StatusView: MastodonMenuDelegate {
    public func menuAction(_ action: MastodonMenu.Action) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.statusView(self, menuButton: authorView.menuButton, didSelectAction: action)
    }
}

extension StatusView {
    func setupTranslationIndicator() {
        viewModel.$isCurrentlyTranslating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isTranslating in
                switch isTranslating {
                case true:
                    self?.isTranslatingLoadingView.startAnimating()
                case false:
                    self?.isTranslatingLoadingView.stopAnimating()
                }
            }
            .store(in: &disposeBag)

        Publishers.CombineLatest(
            viewModel.$translatedFromLanguage,
            viewModel.$translatedUsingProvider
        )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] translatedFromLanguage, translatedUsingProvider in
                guard let self = self else { return }
                if let translatedFromLanguage = translatedFromLanguage {
                    self.translatedInfoLabel.text = L10n.Common.Controls.Status.Translation.translatedFrom(
                        Locale.current.localizedString(forIdentifier: translatedFromLanguage) ?? L10n.Common.Controls.Status.Translation.unknownLanguage,
                        translatedUsingProvider ?? L10n.Common.Controls.Status.Translation.unknownProvider
                    )
                    self.translatedInfoView.isHidden = false
                } else {
                    self.translatedInfoView.isHidden = true
                }
            }
            .store(in: &disposeBag)
    }
}

// MARK: StatusCardControlDelegate
extension StatusView: StatusCardControlDelegate {
    public func statusCardControl(_ statusCardControl: StatusCardControl, didTapURL url: URL) {
        delegate?.statusView(self, cardControl: statusCardControl, didTapURL: url)
    }

    public func statusCardControlMenu(_ statusCardControl: StatusCardControl) -> UIMenu? {
        delegate?.statusView(self, cardControlMenu: statusCardControl)
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
