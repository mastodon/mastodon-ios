//
//  HomeTimelineViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/5.
//

import UIKit
import AVKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK
import AlamofireImage
import StoreKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

final class HomeTimelineViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: HomeTimelineViewModel?

    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    enum EmptyViewUseCase {
        case timeline, list
    }

    let friendsAssetImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.Asset.friends.image
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    lazy var emptyView: UIStackView = {
        let emptyView = UIStackView()
        emptyView.axis = .vertical
        emptyView.distribution = .fill
        emptyView.isLayoutMarginsRelativeArrangement = true
        return emptyView
    }()

    lazy var timelineSelectorButton = {
        let button = UIButton(type: .custom)

        button.setAttributedTitle(
            .init(string: L10n.Scene.HomeTimeline.TimelineMenu.following, attributes: [
                .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
            ]),
            for: .normal)

        let imageConfiguration = UIImage.SymbolConfiguration(paletteColors: [.secondaryLabel, .secondarySystemFill])
            .applying(UIImage.SymbolConfiguration(textStyle: .subheadline))
            .applying(UIImage.SymbolConfiguration(pointSize: 16, weight: .bold, scale: .medium))

        button.configuration = {
            var config = UIButton.Configuration.plain()
            config.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            config.imagePadding = 8
            config.image = UIImage(systemName: "chevron.down.circle.fill", withConfiguration: imageConfiguration)
            config.imagePlacement = .trailing
            return config
        }()

        button.showsMenuAsPrimaryAction = true
        button.menu = generateTimelineSelectorMenu()
        return button
    }()

    let settingBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem()
        barButtonItem.tintColor = Asset.Colors.Brand.blurple.color
        barButtonItem.image = UIImage(systemName: "gear")
        barButtonItem.accessibilityLabel = L10n.Common.Controls.Actions.settings
        return barButtonItem
    }()
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    let publishProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.alpha = 0
        return progressView
    }()
    
    let refreshControl = RefreshControl()
    let timelinePill = TimelineStatusPill()
    var timelinePillCenterXAnchor: NSLayoutConstraint?
    var timelinePillVisibleTopAnchor: NSLayoutConstraint?
    var timelinePillHiddenTopAnchor: NSLayoutConstraint?


    private func generateTimelineSelectorMenu() -> UIMenu {
        let showFollowingAction = UIAction(title: L10n.Scene.HomeTimeline.TimelineMenu.following, image: .init(systemName: "house")) { [weak self] _ in
            guard let self, let viewModel = self.viewModel else { return }

            viewModel.timelineContext = .home
            viewModel.dataController.records = []

            viewModel.loadLatestStateMachine.enter(HomeTimelineViewModel.LoadLatestState.ContextSwitch.self)
            timelineSelectorButton.setAttributedTitle(
                .init(string: L10n.Scene.HomeTimeline.TimelineMenu.following, attributes: [
                    .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
                ]),
                for: .normal)

            timelineSelectorButton.sizeToFit()
            timelineSelectorButton.menu = generateTimelineSelectorMenu()
        }

        let showLocalTimelineAction = UIAction(title: L10n.Scene.HomeTimeline.TimelineMenu.localCommunity, image: .init(systemName: "building.2")) { [weak self] action in
            guard let self, let viewModel = self.viewModel else { return }

            viewModel.timelineContext = .public
            viewModel.loadLatestStateMachine.enter(HomeTimelineViewModel.LoadLatestState.ContextSwitch.self)
            timelineSelectorButton.setAttributedTitle(
                .init(string: L10n.Scene.HomeTimeline.TimelineMenu.localCommunity, attributes: [
                    .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
                ]),
                for: .normal)
            timelineSelectorButton.sizeToFit()
            timelineSelectorButton.menu = generateTimelineSelectorMenu()
        }

        if let viewModel {
            switch viewModel.timelineContext {
            case .public:
                showLocalTimelineAction.state = .on
                showFollowingAction.state = .off
            case .home:
                showLocalTimelineAction.state = .off
                showFollowingAction.state = .on
            case .list:
                showLocalTimelineAction.state = .off
                showFollowingAction.state = .off
            case .hashtag:
                showLocalTimelineAction.state = .off
                showFollowingAction.state = .off
            }
        }
        
        let listsSubmenu = UIDeferredMenuElement.uncached { [weak self] callback in
            guard let self else { return callback([]) }
            
            Task { @MainActor in
                let lists = (try? await Mastodon.API.Lists.getLists(
                    session: .shared,
                    domain: self.authContext.mastodonAuthenticationBox.domain,
                    authorization: self.authContext.mastodonAuthenticationBox.userAuthorization
                ).singleOutput().value) ?? []
                
                var listEntries = lists.map { entry in
                    return LabeledAction(title: entry.title, image: nil, handler: { [weak self] in
                        guard let self, let viewModel = self.viewModel else { return }
                        viewModel.timelineContext = .list(entry.id)
                        viewModel.loadLatestStateMachine.enter(HomeTimelineViewModel.LoadLatestState.ContextSwitch.self)
                        timelineSelectorButton.setAttributedTitle(
                            .init(string: entry.title, attributes: [
                                .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
                            ]),
                            for: .normal)
                        timelineSelectorButton.sizeToFit()
                        timelineSelectorButton.menu = generateTimelineSelectorMenu()
                    }).menuElement
                }
                
                if listEntries.isEmpty {
                    listEntries = [
                        UIAction(title: L10n.Scene.HomeTimeline.TimelineMenu.Lists.emptyMessage, attributes: [.disabled], handler: {_ in })
                    ]
                }

                callback(listEntries)
            }
        }
        
        let listsMenu = UIMenu(
            title: L10n.Scene.HomeTimeline.TimelineMenu.Lists.title,
            image: UIImage(systemName: "list.bullet.rectangle.portrait"),
            children: [listsSubmenu]
        )
        
        let hashtagsSubmenu = UIDeferredMenuElement.uncached { [weak self] callback in
            guard let self else { return callback([]) }
            
            Task { @MainActor in
                let lists = (try? await Mastodon.API.Account.followedTags(
                    session: .shared,
                    domain: self.authContext.mastodonAuthenticationBox.domain,
                    query: .init(limit: nil),
                    authorization: self.authContext.mastodonAuthenticationBox.userAuthorization
                ).singleOutput().value) ?? []
                
                var listEntries = lists.map { entry in
                    let entryName = "#\(entry.name)"
                    return LabeledAction(title: entryName, image: nil, handler: { [weak self] in
                        guard let self, let viewModel = self.viewModel else { return }
                        viewModel.timelineContext = .hashtag(entry.name)
                        viewModel.loadLatestStateMachine.enter(HomeTimelineViewModel.LoadLatestState.ContextSwitch.self)
                        timelineSelectorButton.setAttributedTitle(
                            .init(string: entryName, attributes: [
                                .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
                            ]),
                            for: .normal)
                        timelineSelectorButton.sizeToFit()
                        timelineSelectorButton.menu = generateTimelineSelectorMenu()
                    }).menuElement
                }
                
                if listEntries.isEmpty {
                    listEntries = [
                        UIAction(title: L10n.Scene.HomeTimeline.TimelineMenu.Hashtags.emptyMessage, attributes: [.disabled], handler: {_ in })
                    ]
                }

                callback(listEntries)
            }
        }

        let hashtagsMenu = UIMenu(
            title: L10n.Scene.HomeTimeline.TimelineMenu.Hashtags.title,
            image: UIImage(systemName: "number"),
            children: [hashtagsSubmenu]
        )
        
        let listsDivider = UIMenu(title: "", options: .displayInline, children: [listsMenu, hashtagsMenu])

        return UIMenu(children: [showFollowingAction, showLocalTimelineAction, listsDivider])
    }
}

extension HomeTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = nil
        view.backgroundColor = .secondarySystemBackground

        viewModel?.$displaySettingBarButtonItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] displaySettingBarButtonItem in
                guard let self = self else { return }

                self.navigationItem.rightBarButtonItem = displaySettingBarButtonItem ? self.settingBarButtonItem : nil
            }
            .store(in: &disposeBag)

        settingBarButtonItem.target = self
        settingBarButtonItem.action = #selector(HomeTimelineViewController.settingBarButtonItemPressed(_:))
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: timelineSelectorButton)
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(HomeTimelineViewController.refreshControlValueChanged(_:)), for: .valueChanged)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.pinToParent()
        
        // // layout publish progress
        publishProgressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(publishProgressView)
        NSLayoutConstraint.activate([
            publishProgressView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            publishProgressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            publishProgressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        viewModel?.tableView = tableView
        tableView.delegate = self
        viewModel?.setupDiffableDataSource(
            tableView: tableView,
            statusTableViewCellDelegate: self,
            timelineMiddleLoaderTableViewCellDelegate: self
        )

        // bind refresh control
        viewModel?.didLoadLatest
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.5) { [weak self] in
                    guard let self = self else { return }
                    self.refreshControl.endRefreshing()
                } completion: { _ in }
            }
            .store(in: &disposeBag)
        
        context.publisherService.statusPublishResult.receive(on: DispatchQueue.main).sink { result in
            if case .success(.edit(let status)) = result {
                self.viewModel?.hasPendingStatusEditReload = true
                self.viewModel?.dataController.update(status: .fromEntity(status.value), intent: .edit)
            }
        }.store(in: &disposeBag)
        
        context.publisherService.$currentPublishProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self = self else { return }
                let progress = Float(progress)

                guard progress > 0 else {
                    let dismissAnimator = UIViewPropertyAnimator(duration: 0.1, curve: .easeInOut)
                    dismissAnimator.addAnimations {
                        self.publishProgressView.alpha = 0
                    }
                    dismissAnimator.addCompletion { _ in
                        self.publishProgressView.setProgress(0, animated: false)
                    }
                    dismissAnimator.startAnimation()
                    return
                }
                if self.publishProgressView.alpha == 0 {
                    let progressAnimator = UIViewPropertyAnimator(duration: 0.1, curve: .easeOut)
                    progressAnimator.addAnimations {
                        self.publishProgressView.alpha = 1
                    }
                    progressAnimator.startAnimation()
                }
                
                self.publishProgressView.setProgress(progress, animated: true)
            }
            .store(in: &disposeBag)
        
        viewModel?.timelineIsEmpty
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let state else {
                    self?.emptyView.removeFromSuperview()
                    return
                }
                self?.showEmptyView(state)

                let userDoesntFollowPeople: Bool
                if let authContext = self?.authContext,
                   let me = authContext.mastodonAuthenticationBox.authentication.account() {
                    userDoesntFollowPeople = me.followersCount == 0
                } else {
                    userDoesntFollowPeople = true
                }

                if (self?.viewModel?.presentedSuggestions == false) && userDoesntFollowPeople {
                    self?.findPeopleButtonPressed(self)
                    self?.viewModel?.presentedSuggestions = true
                }
            }
            .store(in: &disposeBag)
        
        NotificationCenter.default
            .publisher(for: .statusBarTapped, object: nil)
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] notification in
                guard let self = self else { return }
                guard let _ = self.view.window else { return } // displaying
                
                // https://developer.limneos.net/index.php?ios=13.1.3&framework=UIKitCore.framework&header=UIStatusBarTapAction.h
                guard let action = notification.object as AnyObject?,
                    let xPosition = action.value(forKey: "xPosition") as? Double
                else { return }
                
                let viewFrameInWindow = self.view.convert(self.view.frame, to: nil)
                guard xPosition >= viewFrameInWindow.minX && xPosition <= viewFrameInWindow.maxX else { return }

                // check if scroll to top
                guard self.shouldRestoreScrollPosition() else { return }
                self.restorePositionWhenScrollToTop()
            }
            .store(in: &disposeBag)

        timelinePill.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timelinePill)

        let timelinePillCenterXAnchor = timelinePill.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let timelinePillVisibleTopAnchor = timelinePill.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
        let timelinePillHiddenTopAnchor = view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: timelinePill.bottomAnchor, constant: 8)

        NSLayoutConstraint.activate([
            timelinePillHiddenTopAnchor, timelinePillCenterXAnchor
        ])

        timelinePill.addTarget(self, action: #selector(HomeTimelineViewController.timelinePillTouched(_:)), for: .touchDown)
        timelinePill.addTarget(self, action: #selector(HomeTimelineViewController.timelinePillPressedInside(_:)), for: .touchUpInside)
        timelinePill.addTarget(self, action: #selector(HomeTimelineViewController.timelinePillTouchedOutside(_:)), for: .touchUpOutside)

        self.timelinePillCenterXAnchor = timelinePillCenterXAnchor
        self.timelinePillVisibleTopAnchor = timelinePillVisibleTopAnchor
        self.timelinePillHiddenTopAnchor = timelinePillHiddenTopAnchor

        viewModel?.hasNewPosts
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] hasNewPosts in
                guard let self else { return }

                if hasNewPosts {
                    self.timelinePill.update(with: .newPosts)
                    self.showTimelinePill()
                } else {
                    self.hideTimelinePill()
                }
            })
            .store(in: &disposeBag)

        viewModel?.isOffline
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isOffline in
                guard let self else { return }

                if isOffline {
                    self.timelinePill.update(with: .offline)
                    self.showTimelinePill()
                }
            })
            .store(in: &disposeBag)

        context.publisherService.statusPublishResult.prepend(.failure(AppError.badRequest))
        .receive(on: DispatchQueue.main)
        .sink { [weak self] publishResult in
            guard let self else { return }
            switch publishResult {
            case .success:
                self.timelinePill.update(with: .postSent)
                self.showTimelinePill()
            case .failure:
                self.hideTimelinePill()
            }
        }
        .store(in: &disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshControl.endRefreshing()
        tableView.deselectRow(with: transitionCoordinator, animated: animated)
        
        // needs trigger manually after onboarding dismiss
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let timestamp = viewModel?.lastAutomaticFetchTimestamp {
            let now = Date()
            if now.timeIntervalSince(timestamp) > 60 {
                self.viewModel?.lastAutomaticFetchTimestamp = now
                self.viewModel?.homeTimelineNeedRefresh.send()
            } else {
                // do nothing
            }
        } else {
            self.viewModel?.homeTimelineNeedRefresh.send()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { _ in
            // do nothing
        } completion: { _ in
            // fix AutoLayout cell height not update after rotate issue
            self.viewModel?.cellFrameCache.removeAllObjects()
            self.tableView.reloadData()
        }
    }
}

extension HomeTimelineViewController {
    func showEmptyView(_ state: HomeTimelineViewModel.EmptyViewState) {
        if emptyView.superview != nil {
            return
        }
        view.addSubview(emptyView)
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
        ])
        
        if emptyView.arrangedSubviews.count > 0 {
            return
        }

        switch state {
        case .list:
            let noStatusesLabel: UILabel = {
                let label = UILabel()
                label.text = L10n.Scene.HomeTimeline.EmptyState.listEmptyMessageTitle
                label.textColor = Asset.Colors.Label.secondary.color
                label.textAlignment = .center
                return label
            }()
            emptyView.addArrangedSubview(noStatusesLabel)
        case .timeline:
            let findPeopleButton: PrimaryActionButton = {
                let button = PrimaryActionButton()
                button.setTitle(L10n.Common.Controls.Actions.findPeople, for: .normal)
                button.addTarget(self, action: #selector(HomeTimelineViewController.findPeopleButtonPressed(_:)), for: .touchUpInside)
                return button
            }()
            NSLayoutConstraint.activate([
                findPeopleButton.heightAnchor.constraint(equalToConstant: 46)
            ])
            
            let manuallySearchButton: HighlightDimmableButton = {
                let button = HighlightDimmableButton()
                button.titleLabel?.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
                button.setTitle(L10n.Common.Controls.Actions.manuallySearch, for: .normal)
                button.setTitleColor(Asset.Colors.Brand.blurple.color, for: .normal)
                button.addTarget(self, action: #selector(HomeTimelineViewController.manuallySearchButtonPressed(_:)), for: .touchUpInside)
                return button
            }()

            let topPaddingView = UIView()
            let bottomPaddingView = UIView()

            emptyView.addArrangedSubview(topPaddingView)
            emptyView.addArrangedSubview(friendsAssetImageView)
            emptyView.addArrangedSubview(bottomPaddingView)

            topPaddingView.translatesAutoresizingMaskIntoConstraints = false
            bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                topPaddingView.heightAnchor.constraint(equalTo: bottomPaddingView.heightAnchor, multiplier: 0.8),
                manuallySearchButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
            ])

            let buttonContainerStackView = UIStackView()
            emptyView.addArrangedSubview(buttonContainerStackView)
            buttonContainerStackView.isLayoutMarginsRelativeArrangement = true
            buttonContainerStackView.layoutMargins = UIEdgeInsets(top: 0, left: 32, bottom: 22, right: 32)
            buttonContainerStackView.axis = .vertical
            buttonContainerStackView.spacing = 17

            buttonContainerStackView.addArrangedSubview(findPeopleButton)
            buttonContainerStackView.addArrangedSubview(manuallySearchButton)
        }
    }
}

//MARK: - Actions
extension HomeTimelineViewController {
    
    @objc private func findPeopleButtonPressed(_ sender: Any?) {
        guard let authContext = viewModel?.authContext else { return }

        let suggestionAccountViewModel = SuggestionAccountViewModel(context: context, authContext: authContext)
        suggestionAccountViewModel.delegate = viewModel
        _ = coordinator.present(
            scene: .suggestionAccount(viewModel: suggestionAccountViewModel),
            from: self,
            transition: .modal(animated: true, completion: nil)
        )
    }
    
    @objc private func manuallySearchButtonPressed(_ sender: UIButton) {
        guard let authContext = viewModel?.authContext else { return }

        let searchDetailViewModel = SearchDetailViewModel(authContext: authContext)
        _ = coordinator.present(scene: .searchDetail(viewModel: searchDetailViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
    @objc private func settingBarButtonItemPressed(_ sender: UIBarButtonItem) {
        guard let setting = context.settingService.currentSetting.value else { return }

        _ = coordinator.present(scene: .settings(setting: setting), from: self, transition: .none)
    }

    @objc private func refreshControlValueChanged(_ sender: RefreshControl) {
        guard let viewModel, viewModel.loadLatestStateMachine.enter(HomeTimelineViewModel.LoadLatestState.LoadingManually.self) else {
            sender.endRefreshing()
            return
        }
    }
    
    @objc func signOutAction(_ sender: UIAction) {
        guard let authContext = viewModel?.authContext else { return }

        Task { @MainActor in
            try await context.authenticationService.signOutMastodonUser(authenticationBox: authContext.mastodonAuthenticationBox)
            let userIdentifier = authContext.mastodonAuthenticationBox
            FileManager.default.invalidateHomeTimelineCache(for: userIdentifier)
            FileManager.default.invalidateNotificationsAll(for: userIdentifier)
            FileManager.default.invalidateNotificationsMentions(for: userIdentifier)
            self.coordinator.setup()
        }
    }

    @objc private func timelinePillTouched(_ sender: TimelineStatusPill) {
        UIView.animate(withDuration: 0.05) {
            sender.transform = CGAffineTransform.identity.scaledBy(x: 0.95, y: 0.95)
        }
    }

    @objc private func timelinePillTouchedOutside(_ sender: TimelineStatusPill) {
        UIView.animate(withDuration: 0.05) {
            sender.transform = CGAffineTransform.identity.scaledBy(x: 100/95.0, y: 100/95.0)
        }
    }

    @objc private func timelinePillPressedInside(_ sender: TimelineStatusPill) {
        guard let reason = sender.reason else { return }

        UIView.animate(withDuration: 0.05) {
            sender.transform = CGAffineTransform.identity.scaledBy(x: 100/95.0, y: 100/95.0)
        }

        switch reason {
        case .newPosts:
            scrollToTop(animated: true)
            viewModel?.hasNewPosts.value = false
        case .postSent:
            scrollToTop(animated: true)
            hideTimelinePill()
        case .offline:
            hideTimelinePill()
        }
    }

    private func showTimelinePill() {
        guard let timelinePillHiddenTopAnchor, let timelinePillVisibleTopAnchor else { return }

        timelinePill.setNeedsLayout()
        timelinePill.layoutIfNeeded()
        timelinePill.alpha = 0
        NSLayoutConstraint.deactivate([timelinePillHiddenTopAnchor])
        NSLayoutConstraint.activate([timelinePillVisibleTopAnchor])

        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.9) { [weak self] in
            self?.timelinePill.alpha = 1
            self?.view.layoutIfNeeded()
        }
    }

    private func hideTimelinePill() {
        guard let timelinePillHiddenTopAnchor, let timelinePillVisibleTopAnchor else { return }

        NSLayoutConstraint.deactivate([timelinePillVisibleTopAnchor])
        NSLayoutConstraint.activate([timelinePillHiddenTopAnchor])
        timelinePill.alpha = 1
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.timelinePill.alpha = 0
            self?.view.layoutIfNeeded()
        })
    }

}
// MARK: - UIScrollViewDelegate
extension HomeTimelineViewController {
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        switch scrollView {
        case tableView:
            
            let indexPath = IndexPath(row: 0, section: 0)
            guard viewModel?.diffableDataSource?.itemIdentifier(for: indexPath) != nil else {
                return true
            }
            // save position
            savePositionBeforeScrollToTop()
            // override by custom scrollToRow
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            return false
        default:
            assertionFailure()
            return true
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        Self.scrollViewDidScrollToEnd(scrollView) {
            guard let viewModel,
                  let currentState = viewModel.loadLatestStateMachine.currentState as? HomeTimelineViewModel.LoadLatestState,
                  (currentState.self is HomeTimelineViewModel.LoadLatestState.ContextSwitch) == false else { return }

            viewModel.timelineDidReachEnd()
        }

        
        guard (scrollView.safeAreaInsets.top + scrollView.contentOffset.y) == 0 else {
            return
        }

        hideTimelinePill()


    }

    private func savePositionBeforeScrollToTop() {
        // check save action interval
        // should not fast than 0.5s to prevent save when scrollToTop on-flying
        if let record = viewModel?.scrollPositionRecord {
            let now = Date()
            guard now.timeIntervalSince(record.timestamp) > 0.5 else {
                // skip this save action
                return
            }
        }
        
        guard let diffableDataSource = viewModel?.diffableDataSource else { return }
        guard let anchorIndexPaths = tableView.indexPathsForVisibleRows?.sorted() else { return }
        guard !anchorIndexPaths.isEmpty else { return }
        let anchorIndexPath = anchorIndexPaths[anchorIndexPaths.count / 2]
        guard let anchorItem = diffableDataSource.itemIdentifier(for: anchorIndexPath) else { return }
        
        let offset: CGFloat = {
            guard let anchorCell = tableView.cellForRow(at: anchorIndexPath) else { return 0 }
            let cellFrameInView = tableView.convert(anchorCell.frame, to: view)
            return cellFrameInView.origin.y
        }()
        viewModel?.scrollPositionRecord = HomeTimelineViewModel.ScrollPositionRecord(
            item: anchorItem,
            offset: offset,
            timestamp: Date()
        )
    }
    
    private func shouldRestoreScrollPosition() -> Bool {
        // check if scroll to top
        guard self.tableView.safeAreaInsets.top > 0 else { return false }
        let zeroOffset = -self.tableView.safeAreaInsets.top
        return abs(self.tableView.contentOffset.y - zeroOffset) < 2.0
    }
    
    private func restorePositionWhenScrollToTop() {
        guard let diffableDataSource = viewModel?.diffableDataSource else { return }
        guard let record = viewModel?.scrollPositionRecord,
              let indexPath = diffableDataSource.indexPath(for: record.item)
        else { return }
        
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        viewModel?.scrollPositionRecord = nil
    }
}

// MARK: - AuthContextProvider
extension HomeTimelineViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel!.authContext }
}

// MARK: - UITableViewDelegate
extension HomeTimelineViewController: UITableViewDelegate, AutoGenerateTableViewDelegate {
    // sourcery:inline:HomeTimelineViewController.AutoGenerateTableViewDelegate

    // Generated using Sourcery
    // DO NOT EDIT
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        aspectTableView(tableView, didSelectRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return aspectTableView(tableView, contextMenuConfigurationForRowAt: indexPath, point: point)
    }

    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return aspectTableView(tableView, previewForHighlightingContextMenuWithConfiguration: configuration)
    }

    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return aspectTableView(tableView, previewForDismissingContextMenuWithConfiguration: configuration)
    }

    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        aspectTableView(tableView, willPerformPreviewActionForMenuWith: configuration, animator: animator)
    }

    // sourcery:end
}

// MARK: - TimelineMiddleLoaderTableViewCellDelegate
extension HomeTimelineViewController: TimelineMiddleLoaderTableViewCellDelegate {
    func timelineMiddleLoaderTableViewCell(_ cell: TimelineMiddleLoaderTableViewCell, loadMoreButtonDidPressed button: UIButton) {
        guard let diffableDataSource = viewModel?.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }

        Task {
            await viewModel?.loadMore(item: item, at: indexPath)
        }
    }
}

// MARK: - ScrollViewContainer
extension HomeTimelineViewController: ScrollViewContainer {
    
    var scrollView: UIScrollView { return tableView }
    
    func scrollToTop(animated: Bool) {
        guard let viewModel else { return }

        if scrollView.contentOffset.y < scrollView.frame.height,
           viewModel.loadLatestStateMachine.canEnterState(HomeTimelineViewModel.LoadLatestState.Loading.self),
           (scrollView.contentOffset.y + scrollView.adjustedContentInset.top) == 0.0,
           !refreshControl.isRefreshing {
            scrollView.scrollRectToVisible(CGRect(origin: CGPoint(x: 0, y: -refreshControl.frame.height), size: CGSize(width: 1, height: 1)), animated: animated)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.refreshControl.beginRefreshing()
                self.refreshControl.sendActions(for: .valueChanged)
            }
        } else {
            let indexPath = IndexPath(row: 0, section: 0)
            guard viewModel.diffableDataSource?.itemIdentifier(for: indexPath) != nil else { return }
            // save position
            savePositionBeforeScrollToTop()
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
}

// MARK: - StatusTableViewCellDelegate
extension HomeTimelineViewController: StatusTableViewCellDelegate { }

extension HomeTimelineViewController {
    override var keyCommands: [UIKeyCommand]? {
        return navigationKeyCommands + statusNavigationKeyCommands
    }
}

// MARK: - StatusTableViewControllerNavigateable
extension HomeTimelineViewController: StatusTableViewControllerNavigateable {
    @objc func navigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        navigateKeyCommandHandler(sender)
    }

    @objc func statusKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        statusKeyCommandHandler(sender)
    }
}
