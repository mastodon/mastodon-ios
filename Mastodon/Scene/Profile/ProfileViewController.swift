//
//  ProfileViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-23.
//

import os.log
import UIKit
import Combine
import ActiveLabel

final class ProfileViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ProfileViewModel!
    
    private(set) lazy var cancelEditingBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.cancel, style: .plain, target: self, action: #selector(ProfileViewController.cancelEditingBarButtonItemPressed(_:)))
        barButtonItem.tintColor = .white
        return barButtonItem
    }()
    
    private(set) lazy var settingBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(ProfileViewController.settingBarButtonItemPressed(_:)))
        barButtonItem.tintColor = .white
        return barButtonItem
    }()
    
    private(set) lazy var shareBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(ProfileViewController.shareBarButtonItemPressed(_:)))
        barButtonItem.tintColor = .white
        return barButtonItem
    }()
    
    private(set) lazy var favoriteBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "star"), style: .plain, target: self, action: #selector(ProfileViewController.favoriteBarButtonItemPressed(_:)))
        barButtonItem.tintColor = .white
        return barButtonItem
    }()
    
    private(set) lazy var replyBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrowshape.turn.up.left"), style: .plain, target: self, action: #selector(ProfileViewController.replyBarButtonItemPressed(_:)))
        barButtonItem.tintColor = .white
        return barButtonItem
    }()
    
    let moreMenuBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: nil, action: nil)
        barButtonItem.tintColor = .white
        return barButtonItem
    }()
    
    let refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .label
        return refreshControl
    }()
    
    let containerScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.scrollsToTop = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.preservesSuperviewLayoutMargins = true
        scrollView.delaysContentTouches = false
        return scrollView
    }()
    
    let overlayScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.delaysContentTouches = false
        return scrollView
    }()
    
    private(set) lazy var profileSegmentedViewController = ProfileSegmentedViewController()
    private(set) lazy var profileHeaderViewController: ProfileHeaderViewController = {
        let viewController = ProfileHeaderViewController()
        viewController.viewModel = ProfileHeaderViewModel(context: context)
        return viewController
    }()
    private var profileBannerImageViewLayoutConstraint: NSLayoutConstraint!
    
    private var contentOffsets: [Int: CGFloat] = [:]
    var currentPostTimelineTableViewContentSizeObservation: NSKeyValueObservation?
    
    // title view nested in header
    var titleView: DoubleTitleLabelNavigationBarTitleView {
        profileHeaderViewController.titleView
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s: deinit", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension ProfileViewController {
    
    func observeTableViewContentSize(scrollView: UIScrollView) -> NSKeyValueObservation {
        updateOverlayScrollViewContentSize(scrollView: scrollView)
        return scrollView.observe(\.contentSize, options: .new) { scrollView, change in
            self.updateOverlayScrollViewContentSize(scrollView: scrollView)
        }
    }
    
    func updateOverlayScrollViewContentSize(scrollView: UIScrollView) {
        let bottomPageHeight = max(scrollView.contentSize.height, self.containerScrollView.frame.height - ProfileHeaderViewController.headerMinHeight - self.containerScrollView.safeAreaInsets.bottom)
        let headerViewHeight: CGFloat = profileHeaderViewController.view.frame.height
        let contentSize = CGSize(
            width: self.containerScrollView.contentSize.width,
            height: bottomPageHeight + headerViewHeight
        )
        self.overlayScrollView.contentSize = contentSize
        // os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: contentSize: %s", ((#file as NSString).lastPathComponent), #line, #function, contentSize.debugDescription)
    }
    
}

extension ProfileViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        profileHeaderViewController.updateHeaderContainerSafeAreaInset(view.safeAreaInsets)
    }
    
    override var isViewLoaded: Bool {
        return super.isViewLoaded
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Asset.Colors.Background.systemGroupedBackground.color

        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = barAppearance
        navigationItem.compactAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance
        
        navigationItem.titleView = titleView

        let editingAndUpdatingPublisher = Publishers.CombineLatest(
            viewModel.isEditing.eraseToAnyPublisher(),
            viewModel.isUpdating.eraseToAnyPublisher()
        )
        // note: not add .share() here
        
        let barButtonItemHiddenPublisher = Publishers.CombineLatest3(
            viewModel.isMeBarButtonItemsHidden.eraseToAnyPublisher(),
            viewModel.isReplyBarButtonItemHidden.eraseToAnyPublisher(),
            viewModel.isMoreMenuBarButtonItemHidden.eraseToAnyPublisher()
        )
        
        editingAndUpdatingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEditing, isUpdating in
                guard let self = self else { return }
                self.cancelEditingBarButtonItem.isEnabled = !isUpdating
            }
            .store(in: &disposeBag)
            
        Publishers.CombineLatest3 (
            viewModel.suspended.eraseToAnyPublisher(),
            editingAndUpdatingPublisher.eraseToAnyPublisher(),
            barButtonItemHiddenPublisher.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] suspended, tuple1, tuple2 in
            guard let self = self else { return }
            let (isEditing, _) = tuple1
            let (isMeBarButtonItemsHidden, isReplyBarButtonItemHidden, isMoreMenuBarButtonItemHidden) = tuple2
            
            var items: [UIBarButtonItem] = []
            defer {
                self.navigationItem.rightBarButtonItems = !items.isEmpty ? items : nil
            }

            guard !suspended else {
                return
            }
            
            guard !isEditing else {
                items.append(self.cancelEditingBarButtonItem)
                return
            }
            
            guard isMeBarButtonItemsHidden else {
                items.append(self.settingBarButtonItem)
                items.append(self.shareBarButtonItem)
                items.append(self.favoriteBarButtonItem)
                return
            }
            
            if !isReplyBarButtonItemHidden {
                items.append(self.replyBarButtonItem)
            }
            if !isMoreMenuBarButtonItemHidden {
                items.append(self.moreMenuBarButtonItem)
            }
        }
        .store(in: &disposeBag)

        overlayScrollView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(ProfileViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        
        let postsUserTimelineViewModel = UserTimelineViewModel(context: context, domain: viewModel.domain.value, userID: viewModel.userID.value, queryFilter: UserTimelineViewModel.QueryFilter())
        bind(userTimelineViewModel: postsUserTimelineViewModel)
        
        let repliesUserTimelineViewModel = UserTimelineViewModel(context: context, domain: viewModel.domain.value, userID: viewModel.userID.value, queryFilter: UserTimelineViewModel.QueryFilter(excludeReplies: true))
        bind(userTimelineViewModel: repliesUserTimelineViewModel)
        
        let mediaUserTimelineViewModel = UserTimelineViewModel(context: context, domain: viewModel.domain.value, userID: viewModel.userID.value, queryFilter: UserTimelineViewModel.QueryFilter(onlyMedia: true))
        bind(userTimelineViewModel: mediaUserTimelineViewModel)
        
        profileSegmentedViewController.pagingViewController.viewModel = {
            let profilePagingViewModel = ProfilePagingViewModel(
                postsUserTimelineViewModel: postsUserTimelineViewModel,
                repliesUserTimelineViewModel: repliesUserTimelineViewModel,
                mediaUserTimelineViewModel: mediaUserTimelineViewModel
            )
            profilePagingViewModel.viewControllers.forEach { viewController in
                if let viewController = viewController as? NeedsDependency {
                    viewController.context = context
                    viewController.coordinator = coordinator
                }
            }
            return profilePagingViewModel
        }()
        
        profileHeaderViewController.pageSegmentedControl.removeAllSegments()
        profileSegmentedViewController.pagingViewController.viewModel.barItems.forEach { item in
            let index = profileHeaderViewController.pageSegmentedControl.numberOfSegments
            profileHeaderViewController.pageSegmentedControl.insertSegment(withTitle: item.title, at: index, animated: false)
        }
        profileHeaderViewController.pageSegmentedControl.selectedSegmentIndex = 0
        
        overlayScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayScrollView)
        NSLayoutConstraint.activate([
            overlayScrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            overlayScrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: overlayScrollView.frameLayoutGuide.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: overlayScrollView.frameLayoutGuide.bottomAnchor),
            overlayScrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])

        containerScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerScrollView)
        NSLayoutConstraint.activate([
            containerScrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            containerScrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: containerScrollView.frameLayoutGuide.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerScrollView.frameLayoutGuide.bottomAnchor),
            containerScrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])

        // add segmented list
        addChild(profileSegmentedViewController)
        profileSegmentedViewController.view.translatesAutoresizingMaskIntoConstraints = false
        containerScrollView.addSubview(profileSegmentedViewController.view)
        profileSegmentedViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            profileSegmentedViewController.view.leadingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.leadingAnchor),
            profileSegmentedViewController.view.trailingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.trailingAnchor),
            profileSegmentedViewController.view.bottomAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.bottomAnchor),
            profileSegmentedViewController.view.heightAnchor.constraint(equalTo: containerScrollView.frameLayoutGuide.heightAnchor),
        ])

        // add header
        addChild(profileHeaderViewController)
        profileHeaderViewController.view.translatesAutoresizingMaskIntoConstraints = false
        containerScrollView.addSubview(profileHeaderViewController.view)
        profileHeaderViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            profileHeaderViewController.view.topAnchor.constraint(equalTo: containerScrollView.topAnchor),
            profileHeaderViewController.view.leadingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.leadingAnchor),
            containerScrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: profileHeaderViewController.view.trailingAnchor),
            profileSegmentedViewController.view.topAnchor.constraint(equalTo: profileHeaderViewController.view.bottomAnchor),
        ])

        containerScrollView.addGestureRecognizer(overlayScrollView.panGestureRecognizer)
        overlayScrollView.layer.zPosition = .greatestFiniteMagnitude    // make vision top-most
        overlayScrollView.delegate = self
        profileHeaderViewController.delegate = self
        profileSegmentedViewController.pagingViewController.pagingDelegate = self

        // bind view model
        Publishers.CombineLatest(
            viewModel.name.eraseToAnyPublisher(),
            viewModel.statusesCount.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] name, statusesCount in
            guard let self = self else { return }
            guard let title = name, let statusesCount = statusesCount,
                  let formattedStatusCount = MastodonMetricFormatter().string(from: statusesCount) else {
                self.titleView.isHidden = true
                return
            }
            let subtitle = L10n.Scene.Profile.subtitle(formattedStatusCount)
            self.titleView.update(title: title, subtitle: subtitle)
            self.titleView.isHidden = false
        }
        .store(in: &disposeBag)
        viewModel.name
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                guard let self = self else { return }
                self.navigationItem.title = name
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            viewModel.bannerImageURL.eraseToAnyPublisher(),
            viewModel.viewDidAppear.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] bannerImageURL, _ in
            guard let self = self else { return }
            self.profileHeaderViewController.profileHeaderView.bannerImageView.af.cancelImageRequest()
            let placeholder = UIImage.placeholder(color: ProfileHeaderView.bannerImageViewPlaceholderColor)
            guard let bannerImageURL = bannerImageURL else {
                self.profileHeaderViewController.profileHeaderView.bannerImageView.image = placeholder
                return
            }
            self.profileHeaderViewController.profileHeaderView.bannerImageView.af.setImage(
                withURL: bannerImageURL,
                placeholderImage: placeholder,
                imageTransition: .crossDissolve(0.3),
                runImageTransitionIfCached: false,
                completion: { [weak self] response in
                    guard let self = self else { return }
                    guard let image = response.value else { return }
                    guard image.size.width > 1 && image.size.height > 1 else {
                        // restore to placeholder when image invalid
                        self.profileHeaderViewController.profileHeaderView.bannerImageView.image = placeholder
                        return
                    }
                }
            )
        }
        .store(in: &disposeBag)
        viewModel.avatarImageURL
            .receive(on: DispatchQueue.main)
            .map { url in ProfileHeaderViewModel.ProfileInfo.ImageResource.url(url) }
            .assign(to: \.value, on: profileHeaderViewController.viewModel.displayProfileInfo.avatarImageResource)
            .store(in: &disposeBag)
        viewModel.name
            .map { $0 ?? "" }
            .receive(on: DispatchQueue.main)
            .assign(to: \.value, on: profileHeaderViewController.viewModel.displayProfileInfo.name)
            .store(in: &disposeBag)
        viewModel.username
            .map { username in username.flatMap { "@" + $0 } ?? " " }
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: profileHeaderViewController.profileHeaderView.usernameLabel)
            .store(in: &disposeBag)
        viewModel.relationshipActionOptionSet
            .receive(on: DispatchQueue.main)
            .sink { [weak self] relationshipActionOptionSet in
                guard let self = self else { return }
                guard let mastodonUser = self.viewModel.mastodonUser.value else {
                    self.moreMenuBarButtonItem.menu = nil
                    return
                }
                let isMuting = relationshipActionOptionSet.contains(.muting)
                let isBlocking = relationshipActionOptionSet.contains(.blocking)
                let needsShareAction = self.viewModel.isMeBarButtonItemsHidden.value
                self.moreMenuBarButtonItem.menu = UserProviderFacade.createProfileActionMenu(for: mastodonUser, isMuting: isMuting, isBlocking: isBlocking, needsShareAction: needsShareAction, provider: self, sourceView: nil, barButtonItem: self.moreMenuBarButtonItem)
            }
            .store(in: &disposeBag)
        viewModel.isRelationshipActionButtonHidden
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isHidden in
                guard let self = self else { return }
                self.profileHeaderViewController.profileHeaderView.relationshipActionButton.isHidden = isHidden
            }
            .store(in: &disposeBag)
        Publishers.CombineLatest3(
            viewModel.relationshipActionOptionSet.eraseToAnyPublisher(),
            viewModel.isEditing.eraseToAnyPublisher(),
            viewModel.isUpdating.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] relationshipActionSet, isEditing, isUpdating in
            guard let self = self else { return }
            let friendshipButton = self.profileHeaderViewController.profileHeaderView.relationshipActionButton
            if relationshipActionSet.contains(.edit) {
                // check .edit state and set .editing when isEditing
                friendshipButton.configure(actionOptionSet: isUpdating ? .updating : (isEditing ? .editing : .edit))
                self.profileHeaderViewController.profileHeaderView.configure(state: isUpdating || isEditing ? .editing : .normal)
            } else {
                friendshipButton.configure(actionOptionSet: relationshipActionSet)
            }
        }
        .store(in: &disposeBag)
        viewModel.isEditing
            .handleEvents(receiveOutput: { [weak self] isEditing in
                guard let self = self else { return }
                // dismiss keyboard if needs
                if !isEditing { self.view.endEditing(true) }
                
                self.profileHeaderViewController.pageSegmentedControl.isEnabled = !isEditing
                self.profileSegmentedViewController.view.isUserInteractionEnabled = !isEditing
                
                let animator = UIViewPropertyAnimator(duration: 0.33, curve: .easeInOut)
                animator.addAnimations {
                    self.profileSegmentedViewController.view.alpha = isEditing ? 0.2 : 1.0
                    self.profileHeaderViewController.profileHeaderView.statusDashboardView.alpha = isEditing ? 0.2 : 1.0
                }
                animator.startAnimation()
            })
            .assign(to: \.value, on: profileHeaderViewController.viewModel.isEditing)
            .store(in: &disposeBag)
        Publishers.CombineLatest3(
            viewModel.isBlocking.eraseToAnyPublisher(),
            viewModel.isBlockedBy.eraseToAnyPublisher(),
            viewModel.suspended.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isBlocking, isBlockedBy, suspended in
            guard let self = self else { return }
            let isNeedSetHidden = isBlocking || isBlockedBy || suspended
            self.profileHeaderViewController.viewModel.needsSetupBottomShadow.value = !isNeedSetHidden
            self.profileHeaderViewController.profileHeaderView.bioContainerView.isHidden = isNeedSetHidden
            self.profileHeaderViewController.pageSegmentedControl.isHidden = isNeedSetHidden
            self.viewModel.needsPagePinToTop.value = isNeedSetHidden
        }
        .store(in: &disposeBag)
        viewModel.bioDescription
            .receive(on: DispatchQueue.main)
            .assign(to: \.value, on: profileHeaderViewController.viewModel.displayProfileInfo.note)
            .store(in: &disposeBag)
        viewModel.statusesCount
            .sink { [weak self] count in
                guard let self = self else { return }
                let text = count.flatMap { MastodonMetricFormatter().string(from: $0) } ?? "-"
                self.profileHeaderViewController.profileHeaderView.statusDashboardView.postDashboardMeterView.numberLabel.text = text
            }
            .store(in: &disposeBag)
        viewModel.followingCount
            .sink { [weak self] count in
                guard let self = self else { return }
                let text = count.flatMap { MastodonMetricFormatter().string(from: $0) } ?? "-"
                self.profileHeaderViewController.profileHeaderView.statusDashboardView.followingDashboardMeterView.numberLabel.text = text
            }
            .store(in: &disposeBag)
        viewModel.followersCount
            .sink { [weak self] count in
                guard let self = self else { return }
                let text = count.flatMap { MastodonMetricFormatter().string(from: $0) } ?? "-"
                self.profileHeaderViewController.profileHeaderView.statusDashboardView.followersDashboardMeterView.numberLabel.text = text
            }
            .store(in: &disposeBag)
        
        profileHeaderViewController.profileHeaderView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // set back button tint color in SceneCoordinator.present(scene:from:transition:)

        // force layout to make banner image tweak take effect
        view.layoutIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppear.send()

        // set overlay scroll view initial content size
        guard let currentViewController = profileSegmentedViewController.pagingViewController.currentViewController as? ScrollViewContainer else { return }
        currentPostTimelineTableViewContentSizeObservation = observeTableViewContentSize(scrollView: currentViewController.scrollView)
        currentViewController.scrollView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        currentPostTimelineTableViewContentSizeObservation = nil
    }
    
}

extension ProfileViewController {

    private func bind(userTimelineViewModel: UserTimelineViewModel) {
        viewModel.domain.assign(to: \.value, on: userTimelineViewModel.domain).store(in: &disposeBag)
        viewModel.userID.assign(to: \.value, on: userTimelineViewModel.userID).store(in: &disposeBag)
        viewModel.isBlocking.assign(to: \.value, on: userTimelineViewModel.isBlocking).store(in: &disposeBag)
        viewModel.isBlockedBy.assign(to: \.value, on: userTimelineViewModel.isBlockedBy).store(in: &disposeBag)
        viewModel.suspended.assign(to: \.value, on: userTimelineViewModel.isSuspended).store(in: &disposeBag)
        viewModel.name.assign(to: \.value, on: userTimelineViewModel.userDisplayName).store(in: &disposeBag)
    }
    
}

extension ProfileViewController {
    
    @objc private func cancelEditingBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        viewModel.isEditing.value = false
    }
    
    @objc private func settingBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

    }
    
    @objc private func shareBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let mastodonUser = viewModel.mastodonUser.value else { return }
        let activityViewController = UserProviderFacade.createActivityViewControllerForMastodonUser(mastodonUser: mastodonUser, dependency: self)
        coordinator.present(
            scene: .activityViewController(
                activityViewController: activityViewController,
                sourceView: nil,
                barButtonItem: sender
            ),
            from: self,
            transition: .activityViewControllerPresent(animated: true, completion: nil)
        )
    }
    
    @objc private func favoriteBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        let favoriteViewModel = FavoriteViewModel(context: context)
        coordinator.present(scene: .favorite(viewModel: favoriteViewModel), from: self, transition: .show)
    }
    
    @objc private func replyBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let mastodonUser = viewModel.mastodonUser.value else { return }
        let composeViewModel = ComposeViewModel(
            context: context,
            composeKind: .mention(mastodonUserObjectID: mastodonUser.objectID)
        )
        coordinator.present(scene: .compose(viewModel: composeViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        let currentViewController = profileSegmentedViewController.pagingViewController.currentViewController
        if let currentViewController = currentViewController as? UserTimelineViewController {
            currentViewController.viewModel.stateMachine.enter(UserTimelineViewModel.State.Reloading.self)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            sender.endRefreshing()
        }
    }
    
}

// MARK: - UIScrollViewDelegate
extension ProfileViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        contentOffsets[profileSegmentedViewController.pagingViewController.currentIndex!] = scrollView.contentOffset.y
        let topMaxContentOffsetY = profileSegmentedViewController.view.frame.minY - ProfileHeaderViewController.headerMinHeight - containerScrollView.safeAreaInsets.top
        if scrollView.contentOffset.y < topMaxContentOffsetY {
            self.containerScrollView.contentOffset.y = scrollView.contentOffset.y
            for postTimelineView in profileSegmentedViewController.pagingViewController.viewModel.viewControllers {
                postTimelineView.scrollView.contentOffset.y = 0
            }
            contentOffsets.removeAll()
        } else {
            containerScrollView.contentOffset.y = topMaxContentOffsetY
            if viewModel.needsPagePinToTop.value {
                // do nothing
            } else {
                if let customScrollViewContainerController = profileSegmentedViewController.pagingViewController.currentViewController as? ScrollViewContainer {
                    let contentOffsetY = scrollView.contentOffset.y - containerScrollView.contentOffset.y
                    customScrollViewContainerController.scrollView.contentOffset.y = contentOffsetY
                }
            }
            
        }

        // elastically banner image
        let headerScrollProgress = containerScrollView.contentOffset.y / topMaxContentOffsetY
        profileHeaderViewController.updateHeaderScrollProgress(headerScrollProgress)
    }

}

// MARK: - ProfileHeaderViewControllerDelegate
extension ProfileViewController: ProfileHeaderViewControllerDelegate {
    
    func profileHeaderViewController(_ viewController: ProfileHeaderViewController, viewLayoutDidUpdate view: UIView) {
        guard let scrollView = (profileSegmentedViewController.pagingViewController.currentViewController as? UserTimelineViewController)?.scrollView else {
            // assertionFailure()
            return
        }
        
        updateOverlayScrollViewContentSize(scrollView: scrollView)
    }
    
    func profileHeaderViewController(_ viewController: ProfileHeaderViewController, pageSegmentedControlValueChanged segmentedControl: UISegmentedControl, selectedSegmentIndex index: Int) {
        profileSegmentedViewController.pagingViewController.scrollToPage(
            .at(index: index),
            animated: true
        )
    }
    
}

// MARK: - ProfilePagingViewControllerDelegate
extension ProfileViewController: ProfilePagingViewControllerDelegate {

    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostCustomScrollViewContainerController postTimelineViewController: ScrollViewContainer, atIndex index: Int) {
        os_log("%{public}s[%{public}ld], %{public}s: select at index: %ld", ((#file as NSString).lastPathComponent), #line, #function, index)
        
        // update segemented control
        if index < profileHeaderViewController.pageSegmentedControl.numberOfSegments {
            profileHeaderViewController.pageSegmentedControl.selectedSegmentIndex = index
        }
        
        // save content offset
        overlayScrollView.contentOffset.y = contentOffsets[index] ?? containerScrollView.contentOffset.y
        
        // setup observer and gesture fallback
        currentPostTimelineTableViewContentSizeObservation = observeTableViewContentSize(scrollView: postTimelineViewController.scrollView)
        postTimelineViewController.scrollView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
    }

}

// MARK: - ProfileHeaderViewDelegate
extension ProfileViewController: ProfileHeaderViewDelegate {
    
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, relationshipButtonDidPressed button: ProfileRelationshipActionButton) {
        let relationshipActionSet = viewModel.relationshipActionOptionSet.value
        if relationshipActionSet.contains(.edit) {
            guard !viewModel.isUpdating.value else { return }
            
            if profileHeaderViewController.viewModel.isProfileInfoEdited() {
                viewModel.isUpdating.value = true
                profileHeaderViewController.viewModel.updateProfileInfo()
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] completion in
                        guard let self = self else { return }
                        switch completion {
                        case .failure(let error):
                            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: update profile info fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        case .finished:
                            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: update profile info success", ((#file as NSString).lastPathComponent), #line, #function)
                        }
                        self.viewModel.isUpdating.value = false
                    } receiveValue: { [weak self] _ in
                        guard let self = self else { return }
                        self.viewModel.isEditing.value = false
                    }
                    .store(in: &disposeBag)
            } else {
                viewModel.isEditing.value.toggle()
            }
        } else {
            guard let relationshipAction = relationshipActionSet.highPriorityAction(except: .editOptions) else { return }
            switch relationshipAction {
            case .none:
                break
            case .follow, .reqeust, .pending, .following:
                UserProviderFacade.toggleUserFollowRelationship(provider: self)
                    .sink { _ in
                        // TODO: handle error
                    } receiveValue: { _ in
                        // do nothing
                    }
                    .store(in: &disposeBag)
            case .muting:
                guard let mastodonUser = viewModel.mastodonUser.value else { return }
                let name = mastodonUser.displayNameWithFallback
                let alertController = UIAlertController(
                    title: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.title,
                    message: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.message(name),
                    preferredStyle: .alert
                )
                let unmuteAction = UIAlertAction(title: L10n.Common.Controls.Firendship.unmute, style: .default) { [weak self] _ in
                    guard let self = self else { return }
                    UserProviderFacade.toggleUserMuteRelationship(provider: self)
                        .sink { _ in
                            // do nothing
                        } receiveValue: { _ in
                            // do nothing
                        }
                        .store(in: &self.context.disposeBag)
                }
                alertController.addAction(unmuteAction)
                let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                present(alertController, animated: true, completion: nil)
            case .blocking:
                guard let mastodonUser = viewModel.mastodonUser.value else { return }
                let name = mastodonUser.displayNameWithFallback
                let alertController = UIAlertController(
                    title: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUsre.title,
                    message: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUsre.message(name),
                    preferredStyle: .alert
                )
                let unblockAction = UIAlertAction(title: L10n.Common.Controls.Firendship.unblock, style: .default) { [weak self] _ in
                    guard let self = self else { return }
                    UserProviderFacade.toggleUserBlockRelationship(provider: self)
                        .sink { _ in
                            // do nothing
                        } receiveValue: { _ in
                            // do nothing
                        }
                        .store(in: &self.context.disposeBag)
                }
                alertController.addAction(unblockAction)
                let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                present(alertController, animated: true, completion: nil)
            case .blocked:
                break
            default:
                assertionFailure()
            }
        }
    }
    
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, activeLabel: ActiveLabel, entityDidPressed entity: ActiveEntity) {
        switch entity.type {
        case .url(_, _, let url, _):
            guard let url = URL(string: url) else { return }
            coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
        default:
            // TODO:
            break
        }
    }
    
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, profileStatusDashboardView: ProfileStatusDashboardView, postDashboardMeterViewDidPressed dashboardMeterView: ProfileStatusDashboardMeterView) {

    }
    
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, profileStatusDashboardView: ProfileStatusDashboardView, followingDashboardMeterViewDidPressed dwingDashboardMeterView: ProfileStatusDashboardMeterView) {
        
    }
    
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, profileStatusDashboardView: ProfileStatusDashboardView, followersDashboardMeterViewDidPressed dwersDashboardMeterView: ProfileStatusDashboardMeterView) {
        
    }

}

// MARK: - ScrollViewContainer
extension ProfileViewController: ScrollViewContainer {
    var scrollView: UIScrollView { return overlayScrollView }
}
