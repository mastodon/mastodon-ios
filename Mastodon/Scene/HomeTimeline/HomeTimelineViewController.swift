//
//  HomeTimelineViewController.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/5.
//

import os.log
import UIKit
import AVKit
import Combine
import CoreData
import CoreDataStack
import GameplayKit
import MastodonSDK
import AlamofireImage

final class HomeTimelineViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = HomeTimelineViewModel(context: context)
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()

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
    
    let titleView = HomeTimelineNavigationBarTitleView()
    
    let settingBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem()
        barButtonItem.tintColor = Asset.Colors.brandBlue.color
        barButtonItem.image = UIImage(systemName: "gear")?.withRenderingMode(.alwaysTemplate)
        return barButtonItem
    }()
    
    let composeBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem()
        barButtonItem.tintColor = Asset.Colors.brandBlue.color
        barButtonItem.image = UIImage(systemName: "square.and.pencil")?.withRenderingMode(.alwaysTemplate)
        return barButtonItem
    }()
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(TimelineMiddleLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
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
    
    let refreshControl = UIRefreshControl()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension HomeTimelineViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.Scene.HomeTimeline.title
        view.backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.view.backgroundColor = theme.secondarySystemBackgroundColor
            }
            .store(in: &disposeBag)
        navigationItem.leftBarButtonItem = settingBarButtonItem
        navigationItem.titleView = titleView
        titleView.delegate = self
        
        viewModel.homeTimelineNavigationBarTitleViewModel.state
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                self.titleView.configure(state: state)
            }
            .store(in: &disposeBag)
        
        #if DEBUG
        // long press to trigger debug menu
        settingBarButtonItem.menu = debugMenu
        #else
        settingBarButtonItem.target = self
        settingBarButtonItem.action = #selector(HomeTimelineViewController.settingBarButtonItemPressed(_:))
        #endif
        
        navigationItem.rightBarButtonItem = composeBarButtonItem
        composeBarButtonItem.target = self
        composeBarButtonItem.action = #selector(HomeTimelineViewController.composeBarButtonItemPressed(_:))
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(HomeTimelineViewController.refreshControlValueChanged(_:)), for: .valueChanged)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        publishProgressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(publishProgressView)
        NSLayoutConstraint.activate([
            publishProgressView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            publishProgressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            publishProgressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        viewModel.tableView = tableView
        viewModel.contentOffsetAdjustableTimelineViewControllerDelegate = self
        tableView.delegate = self
        tableView.prefetchDataSource = self
        viewModel.setupDiffableDataSource(
            for: tableView,
            dependency: self,
            statusTableViewCellDelegate: self,
            timelineMiddleLoaderTableViewCellDelegate: self
        )

        // bind refresh control
        viewModel.isFetchingLatestTimeline
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFetching in
                guard let self = self else { return }
                if !isFetching {
                    UIView.animate(withDuration: 0.5) { [weak self] in
                        guard let self = self else { return }
                        self.refreshControl.endRefreshing()
                    } completion: { _ in }
                }
            }
            .store(in: &disposeBag)
        
        viewModel.homeTimelineNavigationBarTitleViewModel.publishingProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self = self else { return }
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
        
        viewModel.timelineIsEmpty
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEmpty in
                if isEmpty {
                    self?.showEmptyView()
                } else {
                    self?.emptyView.removeFromSuperview()
                }
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        aspectViewWillAppear(animated)
        
        // needs trigger manually after onboarding dismiss
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppear.send()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            // always try to refresh timeline after appear
            self.viewModel.homeTimelineNeedRefresh.send()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        aspectViewDidDisappear(animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { _ in
            // do nothing
        } completion: { _ in
            // fix AutoLayout cell height not update after rotate issue
            self.viewModel.cellFrameCache.removeAllObjects()
            self.tableView.reloadData()
        }
    }
}

extension HomeTimelineViewController {
    func showEmptyView() {
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
            button.setTitleColor(Asset.Colors.brandBlue.color, for: .normal)
            button.addTarget(self, action: #selector(HomeTimelineViewController.manuallySearchButtonPressed(_:)), for: .touchUpInside)
            return button
        }()

        let topPaddingView = UIView()
        let bottomPaddingView = UIView()

        emptyView.addArrangedSubview(topPaddingView)
        emptyView.addArrangedSubview(friendsAssetImageView)
        emptyView.addArrangedSubview(bottomPaddingView)

        friendsAssetImageView.isHidden = traitCollection.userInterfaceIdiom != .phone

        topPaddingView.translatesAutoresizingMaskIntoConstraints = false
        bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topPaddingView.heightAnchor.constraint(equalTo: bottomPaddingView.heightAnchor, multiplier: 0.8),
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

extension HomeTimelineViewController {
    
    @objc private func findPeopleButtonPressed(_ sender: PrimaryActionButton) {
        let viewModel = SuggestionAccountViewModel(context: context)
        viewModel.delegate = self.viewModel
        coordinator.present(scene: .suggestionAccount(viewModel: viewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
    @objc private func manuallySearchButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        let searchDetailViewModel = SearchDetailViewModel()
        coordinator.present(scene: .searchDetail(viewModel: searchDetailViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
    @objc private func settingBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let setting = context.settingService.currentSetting.value else { return }
        let settingsViewModel = SettingsViewModel(context: context, setting: setting)
        coordinator.present(scene: .settings(viewModel: settingsViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
    @objc private func composeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        let composeViewModel = ComposeViewModel(context: context, composeKind: .post)
        coordinator.present(scene: .compose(viewModel: composeViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        guard viewModel.loadLatestStateMachine.enter(HomeTimelineViewModel.LoadLatestState.Loading.self) else {
            sender.endRefreshing()
            return
        }
    }
    
    @objc func signOutAction(_ sender: UIAction) {
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }

        context.authenticationService.signOutMastodonUser(
            domain: activeMastodonAuthenticationBox.domain,
            userID: activeMastodonAuthenticationBox.userID
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                assertionFailure(error.localizedDescription)
            case .success(let isSignOut):
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: sign out %s", ((#file as NSString).lastPathComponent), #line, #function, isSignOut ? "success" : "fail")
                guard isSignOut else { return }
                self.coordinator.setup()
                self.coordinator.setupOnboardingIfNeeds(animated: true)
            }
        }
        .store(in: &disposeBag)
    }

}

// MARK: - StatusTableViewControllerAspect
extension HomeTimelineViewController: StatusTableViewControllerAspect { }

extension HomeTimelineViewController: TableViewCellHeightCacheableContainer {
    var cellFrameCache: NSCache<NSNumber, NSValue> { return viewModel.cellFrameCache }
}

// MARK: - UIScrollViewDelegate
extension HomeTimelineViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        aspectScrollViewDidScroll(scrollView)
        viewModel.homeTimelineNavigationBarTitleViewModel.handleScrollViewDidScroll(scrollView)
    }
}

extension HomeTimelineViewController: LoadMoreConfigurableTableViewContainer {
    typealias BottomLoaderTableViewCell = TimelineBottomLoaderTableViewCell
    typealias LoadingState = HomeTimelineViewModel.LoadOldestState.Loading
    var loadMoreConfigurableTableView: UITableView { return tableView }
    var loadMoreConfigurableStateMachine: GKStateMachine { return viewModel.loadLatestStateMachine }
}

// MARK: - UITableViewDelegate
extension HomeTimelineViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        aspectTableView(tableView, estimatedHeightForRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        aspectTableView(tableView, willDisplay: cell, forRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        aspectTableView(tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }
    
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
    
}

// MARK: - UITableViewDataSourcePrefetching
extension HomeTimelineViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        aspectTableView(tableView, prefetchRowsAt: indexPaths)
    }

    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        aspectTableView(tableView, cancelPrefetchingForRowsAt: indexPaths)
    }
}

// MARK: - ContentOffsetAdjustableTimelineViewControllerDelegate
extension HomeTimelineViewController: ContentOffsetAdjustableTimelineViewControllerDelegate {
    func navigationBar() -> UINavigationBar? {
        return navigationController?.navigationBar
    }
}

// MARK: - TimelineMiddleLoaderTableViewCellDelegate
extension HomeTimelineViewController: TimelineMiddleLoaderTableViewCellDelegate {
    func configure(cell: TimelineMiddleLoaderTableViewCell, upperTimelineStatusID: String?, timelineIndexobjectID: NSManagedObjectID?) {
        guard let upperTimelineIndexObjectID = timelineIndexobjectID else {
            return
        }
        viewModel.loadMiddleSateMachineList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                guard let _ = self else { return }
                if let stateMachine = ids[upperTimelineIndexObjectID] {
                    guard let state = stateMachine.currentState else {
                        assertionFailure()
                        return
                    }

                    // make success state same as loading due to snapshot updating delay
                    let isLoading = state is HomeTimelineViewModel.LoadMiddleState.Loading || state is HomeTimelineViewModel.LoadMiddleState.Success
                    if isLoading {
                        cell.startAnimating()
                    } else {
                        cell.stopAnimating()
                    }
                } else {
                    cell.stopAnimating()
                }
            }
            .store(in: &cell.disposeBag)
        
        var dict = viewModel.loadMiddleSateMachineList.value
        if let _ = dict[upperTimelineIndexObjectID] {
            // do nothing
        } else {
            let stateMachine = GKStateMachine(states: [
                HomeTimelineViewModel.LoadMiddleState.Initial(viewModel: viewModel, upperTimelineIndexObjectID: upperTimelineIndexObjectID),
                HomeTimelineViewModel.LoadMiddleState.Loading(viewModel: viewModel, upperTimelineIndexObjectID: upperTimelineIndexObjectID),
                HomeTimelineViewModel.LoadMiddleState.Fail(viewModel: viewModel, upperTimelineIndexObjectID: upperTimelineIndexObjectID),
                HomeTimelineViewModel.LoadMiddleState.Success(viewModel: viewModel, upperTimelineIndexObjectID: upperTimelineIndexObjectID),
            ])
            stateMachine.enter(HomeTimelineViewModel.LoadMiddleState.Initial.self)
            dict[upperTimelineIndexObjectID] = stateMachine
            viewModel.loadMiddleSateMachineList.value = dict
        }
    }
    
    func timelineMiddleLoaderTableViewCell(_ cell: TimelineMiddleLoaderTableViewCell, loadMoreButtonDidPressed button: UIButton) {
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .homeMiddleLoader(let upper):
            guard let stateMachine = viewModel.loadMiddleSateMachineList.value[upper] else {
                assertionFailure()
                return
            }
            stateMachine.enter(HomeTimelineViewModel.LoadMiddleState.Loading.self)
        default:
            assertionFailure()
        }
    }
}

// MARK: - ScrollViewContainer
extension HomeTimelineViewController: ScrollViewContainer {
    
    var scrollView: UIScrollView { return tableView }
    
    func scrollToTop(animated: Bool) {
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
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
}

// MARK: - AVPlayerViewControllerDelegate
extension HomeTimelineViewController: AVPlayerViewControllerDelegate {
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        handlePlayerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
    
    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        handlePlayerViewController(playerViewController, willEndFullScreenPresentationWithAnimationCoordinator: coordinator)
    }
    
}

// MARK: - StatusTableViewCellDelegate
extension HomeTimelineViewController: StatusTableViewCellDelegate {
    weak var playerViewControllerDelegate: AVPlayerViewControllerDelegate? { return self }
    func parent() -> UIViewController { return self }
}

// MARK: - HomeTimelineNavigationBarTitleViewDelegate
extension HomeTimelineViewController: HomeTimelineNavigationBarTitleViewDelegate {
    func homeTimelineNavigationBarTitleView(_ titleView: HomeTimelineNavigationBarTitleView, logoButtonDidPressed sender: UIButton) {
        scrollToTop(animated: true)
    }
    
    func homeTimelineNavigationBarTitleView(_ titleView: HomeTimelineNavigationBarTitleView, buttonDidPressed sender: UIButton) {
        switch titleView.state {
        case .newPostButton:
            guard let diffableDataSource = viewModel.diffableDataSource else { return }
            let indexPath = IndexPath(row: 0, section: 0)
            guard diffableDataSource.itemIdentifier(for: indexPath) != nil else { return }
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        case .offlineButton:
            // TODO: retry
            break
        case .publishedButton:
            break
        default:
            break
        }
    }
}

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
