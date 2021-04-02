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
    
    private var preferredStatusBarStyleForBanner: UIStatusBarStyle = .lightContent {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
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
    private(set) lazy var profileHeaderViewController = ProfileHeaderViewController()
    private var profileBannerImageViewLayoutConstraint: NSLayoutConstraint!
    
    private var contentOffsets: [Int: CGFloat] = [:]
    var currentPostTimelineTableViewContentSizeObservation: NSKeyValueObservation?
    
    
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
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: contentSize: %s", ((#file as NSString).lastPathComponent), #line, #function, contentSize.debugDescription)
    }
    
}

extension ProfileViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return preferredStatusBarStyleForBanner
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        profileHeaderViewController.updateHeaderContainerSafeAreaInset(view.safeAreaInsets)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
        
        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = barAppearance
        navigationItem.compactAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance
        navigationItem.titleView = UIView()
        
//        if navigationController?.viewControllers.first == self {
//            navigationItem.leftBarButtonItem = avatarBarButtonItem
//        }
//        avatarBarButtonItem.avatarButton.addTarget(self, action: #selector(ProfileViewController.avatarButtonPressed(_:)), for: .touchUpInside)
        
//        unmuteMenuBarButtonItem.target = self
//        unmuteMenuBarButtonItem.action = #selector(ProfileViewController.unmuteBarButtonItemPressed(_:))
        
//        Publishers.CombineLatest4(
//            viewModel.muted.eraseToAnyPublisher(),
//            viewModel.blocked.eraseToAnyPublisher(),
//            viewModel.twitterUser.eraseToAnyPublisher(),
//            context.authenticationService.activeTwitterAuthenticationBox.eraseToAnyPublisher()
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] muted, blocked, twitterUser, activeTwitterAuthenticationBox in
//            guard let self = self else { return }
//            guard let twitterUser = twitterUser,
//                  let activeTwitterAuthenticationBox = activeTwitterAuthenticationBox,
//                  twitterUser.id != activeTwitterAuthenticationBox.twitterUserID else {
//                self.navigationItem.rightBarButtonItems = []
//                return
//            }
//
//            if #available(iOS 14.0, *) {
//                self.moreMenuBarButtonItem.target = nil
//                self.moreMenuBarButtonItem.action = nil
//                self.moreMenuBarButtonItem.menu = UserProviderFacade.createMenuForUser(
//                    twitterUser: twitterUser,
//                    muted: muted,
//                    blocked: blocked,
//                    dependency: self
//                )
//            } else {
//                // no menu supports for early version
//                self.moreMenuBarButtonItem.target = self
//                self.moreMenuBarButtonItem.action = #selector(ProfileViewController.moreMenuBarButtonItemPressed(_:))
//            }
//
//            var rightBarButtonItems: [UIBarButtonItem] = [self.moreMenuBarButtonItem]
//            if muted {
//                rightBarButtonItems.append(self.unmuteMenuBarButtonItem)
//            }
//
//            self.navigationItem.rightBarButtonItems = rightBarButtonItems
//        }
//        .store(in: &disposeBag)
        
        overlayScrollView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(ProfileViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        
//        drawerSidebarTransitionController = DrawerSidebarTransitionController(drawerSidebarTransitionableViewController: self)
        
        let postsUserTimelineViewModel = UserTimelineViewModel(context: context, domain: viewModel.domain.value, userID: viewModel.userID.value, queryFilter: UserTimelineViewModel.QueryFilter())
        viewModel.domain.assign(to: \.value, on: postsUserTimelineViewModel.domain).store(in: &disposeBag)
        viewModel.userID.assign(to: \.value, on: postsUserTimelineViewModel.userID).store(in: &disposeBag)

        let repliesUserTimelineViewModel = UserTimelineViewModel(context: context, domain: viewModel.domain.value, userID: viewModel.userID.value, queryFilter: UserTimelineViewModel.QueryFilter(excludeReplies: true))
        viewModel.domain.assign(to: \.value, on: repliesUserTimelineViewModel.domain).store(in: &disposeBag)
        viewModel.userID.assign(to: \.value, on: repliesUserTimelineViewModel.userID).store(in: &disposeBag)

        let mediaUserTimelineViewModel = UserTimelineViewModel(context: context, domain: viewModel.domain.value, userID: viewModel.userID.value, queryFilter: UserTimelineViewModel.QueryFilter(onlyMedia: true))
        viewModel.domain.assign(to: \.value, on: mediaUserTimelineViewModel.domain).store(in: &disposeBag)
        viewModel.userID.assign(to: \.value, on: mediaUserTimelineViewModel.userID).store(in: &disposeBag)
        
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

//        // add segmented bar to header
//        profileSegmentedViewController.pagingViewController.addBar(
//            bar,
//            dataSource: profileSegmentedViewController.pagingViewController.viewModel,
//            at: .custom(view: profileHeaderViewController.view, layout: { bar in
//                bar.translatesAutoresizingMaskIntoConstraints = false
//                self.profileHeaderViewController.view.addSubview(bar)
//                NSLayoutConstraint.activate([
//                    bar.leadingAnchor.constraint(equalTo: self.profileHeaderViewController.view.leadingAnchor),
//                    bar.trailingAnchor.constraint(equalTo: self.profileHeaderViewController.view.trailingAnchor),
//                    bar.bottomAnchor.constraint(equalTo: self.profileHeaderViewController.view.bottomAnchor),
//                    bar.heightAnchor.constraint(equalToConstant: ProfileHeaderViewController.headerMinHeight).priority(.defaultHigh),
//                ])
//            })
//        )

        // bind view model
        Publishers.CombineLatest(
            viewModel.bannerImageURL.eraseToAnyPublisher(),
            viewModel.viewDidAppear.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] bannerImageURL, _ in
            guard let self = self else { return }
            self.profileHeaderViewController.profileBannerView.bannerImageView.af.cancelImageRequest()
            let placeholder = UIImage.placeholder(color: Asset.Colors.Background.systemGroupedBackground.color)
            guard let bannerImageURL = bannerImageURL else {
                self.profileHeaderViewController.profileBannerView.bannerImageView.image = placeholder
                return
            }
            self.profileHeaderViewController.profileBannerView.bannerImageView.af.setImage(
                withURL: bannerImageURL,
                placeholderImage: placeholder,
                imageTransition: .crossDissolve(0.3),
                runImageTransitionIfCached: false,
                completion: { [weak self] response in
                    guard let self = self else { return }
                    switch response.result {
                    case .success(let image):
                        self.viewModel.headerDomainLumaStyle.value = image.domainLumaCoefficientsStyle ?? .dark
                    case .failure:
                        break
                    }
                }
            )
        }
        .store(in: &disposeBag)
        viewModel.headerDomainLumaStyle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] style in
                guard let self = self else { return }
                let textColor: UIColor
                let shadowColor: UIColor
                switch style {
                case .light:
                    self.preferredStatusBarStyleForBanner = .darkContent
                    textColor = .black
                    shadowColor = .white
                case .dark:
                    self.preferredStatusBarStyleForBanner = .lightContent
                    textColor = .white
                    shadowColor = .black
                default:
                    self.preferredStatusBarStyleForBanner = .default
                    textColor = .white
                    shadowColor = .black
                }
                
                self.profileHeaderViewController.profileBannerView.nameLabel.textColor = textColor
                self.profileHeaderViewController.profileBannerView.usernameLabel.textColor = textColor
                self.profileHeaderViewController.profileBannerView.nameLabel.applyShadow(color: shadowColor, alpha: 0.5, x: 0, y: 2, blur: 2)
                self.profileHeaderViewController.profileBannerView.usernameLabel.applyShadow(color: shadowColor, alpha: 0.5, x: 0, y: 2, blur: 2)
            }
            .store(in: &disposeBag)
        Publishers.CombineLatest(
            viewModel.avatarImageURL.eraseToAnyPublisher(),
            viewModel.viewDidAppear.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] avatarImageURL, _ in
            guard let self = self else { return }
            self.profileHeaderViewController.profileBannerView.configure(
                with: AvatarConfigurableViewConfiguration(avatarImageURL: avatarImageURL)
            )
        }
        .store(in: &disposeBag)
//        viewModel.protected
//            .map { $0 != true }
//            .assign(to: \.isHidden, on: profileHeaderViewController.profileBannerView.lockImageView)
//            .store(in: &disposeBag)
        viewModel.name
            .map { $0 ?? " " }
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: profileHeaderViewController.profileBannerView.nameLabel)
            .store(in: &disposeBag)
        viewModel.username
            .map { username in username.flatMap { "@" + $0 } ?? " " }
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: profileHeaderViewController.profileBannerView.usernameLabel)
            .store(in: &disposeBag)
//        viewModel.friendship
//            .sink { [weak self] friendship in
//                guard let self = self else { return }
//                let followingButton = self.profileHeaderViewController.profileBannerView.profileBannerInfoActionView.followActionButton
//                followingButton.isHidden = friendship == nil
//
//                if let friendship = friendship {
//                    switch friendship {
//                    case .following:    followingButton.style = .following
//                    case .pending:      followingButton.style = .pending
//                    case .none:         followingButton.style = .follow
//                    }
//                }
//            }
//            .store(in: &disposeBag)
//        viewModel.followedBy
//            .sink { [weak self] followedBy in
//                guard let self = self else { return }
//                let followStatusLabel = self.profileHeaderViewController.profileBannerView.profileBannerInfoActionView.followStatusLabel
//                followStatusLabel.isHidden = followedBy != true
//            }
//            .store(in: &disposeBag)
//
        viewModel.bioDescription
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] bio in
                guard let self = self else { return }
                self.profileHeaderViewController.profileBannerView.bioActiveLabel.configure(note: bio ?? "")
            })
            .store(in: &disposeBag)
//        Publishers.CombineLatest(
//            viewModel.url.eraseToAnyPublisher(),
//            viewModel.suspended.eraseToAnyPublisher()
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] url, isSuspended in
//            guard let self = self else { return }
//            let url = url.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? " "
//            self.profileHeaderViewController.profileBannerView.linkButton.setTitle(url, for: .normal)
//            let isEmpty = url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//            self.profileHeaderViewController.profileBannerView.linkContainer.isHidden = isEmpty || isSuspended
//        }
//        .store(in: &disposeBag)
//        Publishers.CombineLatest(
//            viewModel.location.eraseToAnyPublisher(),
//            viewModel.suspended.eraseToAnyPublisher()
//        )
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] location, isSuspended in
//            guard let self = self else { return }
//            let location = location.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? " "
//            self.profileHeaderViewController.profileBannerView.geoButton.setTitle(location, for: .normal)
//            let isEmpty = location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//            self.profileHeaderViewController.profileBannerView.geoContainer.isHidden = isEmpty || isSuspended
//        }
//        .store(in: &disposeBag)
        viewModel.statusesCount
            .sink { [weak self] count in
                guard let self = self else { return }
                let text = count.flatMap { String($0) } ?? "-"
                self.profileHeaderViewController.profileBannerView.statusDashboardView.postDashboardMeterView.numberLabel.text = text
            }
            .store(in: &disposeBag)
        viewModel.followingCount
            .sink { [weak self] count in
                guard let self = self else { return }
                let text = count.flatMap { String($0) } ?? "-"
                self.profileHeaderViewController.profileBannerView.statusDashboardView.followingDashboardMeterView.numberLabel.text = text
            }
            .store(in: &disposeBag)
        viewModel.followersCount
            .sink { [weak self] count in
                guard let self = self else { return }
                let text = count.flatMap { String($0) } ?? "-"
                self.profileHeaderViewController.profileBannerView.statusDashboardView.followersDashboardMeterView.numberLabel.text = text
            }
            .store(in: &disposeBag)
//        viewModel.followersCount
//            .sink { [weak self] count in
//                guard let self = self else { return }
//                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.followersStatusItemView.countLabel.text = count.flatMap { "\($0)" } ?? "-"
//            }
//            .store(in: &disposeBag)
//        viewModel.listedCount
//            .sink { [weak self] count in
//                guard let self = self else { return }
//                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.listedStatusItemView.countLabel.text = count.flatMap { "\($0)" } ?? "-"
//            }
//            .store(in: &disposeBag)
//        viewModel.suspended
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] isSuspended in
//                guard let self = self else { return }
//                self.profileHeaderViewController.profileBannerView.profileBannerStatusView.isHidden = isSuspended
//                self.profileHeaderViewController.profileBannerView.profileBannerInfoActionView.isHidden = isSuspended
//                if isSuspended {
//                    self.profileSegmentedViewController
//                        .pagingViewController.viewModel
//                        .profileTweetPostTimelineViewController.viewModel
//                        .stateMachine
//                        .enter(UserTimelineViewModel.State.Suspended.self)
//                    self.profileSegmentedViewController
//                        .pagingViewController.viewModel
//                        .profileMediaPostTimelineViewController.viewModel
//                        .stateMachine
//                        .enter(UserMediaTimelineViewModel.State.Suspended.self)
//                    self.profileSegmentedViewController
//                        .pagingViewController.viewModel
//                        .profileLikesPostTimelineViewController.viewModel
//                        .stateMachine
//                        .enter(UserLikeTimelineViewModel.State.Suspended.self)
//                }
//            }
//            .store(in: &disposeBag)

//
        profileHeaderViewController.profileBannerView.delegate = self
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

//    @objc private func avatarButtonPressed(_ sender: UIButton) {
//        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        coordinator.present(scene: .drawerSidebar, from: self, transition: .custom(transitioningDelegate: drawerSidebarTransitionController))
//    }
//
//    @objc private func unmuteBarButtonItemPressed(_ sender: UIBarButtonItem) {
//        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        guard let twitterUser = viewModel.twitterUser.value else {
//            assertionFailure()
//            return
//        }
//
//        UserProviderFacade.toggleMuteUser(
//            context: context,
//            twitterUser: twitterUser,
//            muted: viewModel.muted.value
//        )
//        .sink { _ in
//            // do nothing
//        } receiveValue: { _ in
//            // do nothing
//        }
//        .store(in: &disposeBag)
//    }
//
//    @objc private func moreMenuBarButtonItemPressed(_ sender: UIBarButtonItem) {
//        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//        guard let twitterUser = viewModel.twitterUser.value else {
//            assertionFailure()
//            return
//        }
//
//        let moreMenuAlertController = UserProviderFacade.createMoreMenuAlertControllerForUser(
//            twitterUser: twitterUser,
//            muted: viewModel.muted.value,
//            blocked: viewModel.blocked.value,
//            sender: sender,
//            dependency: self
//        )
//        present(moreMenuAlertController, animated: true, completion: nil)
//    }
    
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
            if let customScrollViewContainerController = profileSegmentedViewController.pagingViewController.currentViewController as? ScrollViewContainer {
                let contentOffsetY = scrollView.contentOffset.y - containerScrollView.contentOffset.y
                customScrollViewContainerController.scrollView.contentOffset.y = contentOffsetY
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
        
        // save content offset
        overlayScrollView.contentOffset.y = contentOffsets[index] ?? containerScrollView.contentOffset.y
        
        // setup observer and gesture fallback
        currentPostTimelineTableViewContentSizeObservation = observeTableViewContentSize(scrollView: postTimelineViewController.scrollView)
        postTimelineViewController.scrollView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
        
        
//        if let userMediaTimelineViewController = postTimelineViewController as? UserMediaTimelineViewController,
//           let currentState = userMediaTimelineViewController.viewModel.stateMachine.currentState {
//            switch currentState {
//            case is UserMediaTimelineViewModel.State.NoMore,
//                 is UserMediaTimelineViewModel.State.NotAuthorized,
//                 is UserMediaTimelineViewModel.State.Blocked:
//                break
//            default:
//                if userMediaTimelineViewController.viewModel.items.value.isEmpty {
//                    userMediaTimelineViewController.viewModel.stateMachine.enter(UserMediaTimelineViewModel.State.Reloading.self)
//                }
//            }
//        }
//        
//        if let userLikeTimelineViewController = postTimelineViewController as? UserLikeTimelineViewController,
//           let currentState = userLikeTimelineViewController.viewModel.stateMachine.currentState {
//            switch currentState {
//            case is UserLikeTimelineViewModel.State.NoMore,
//                 is UserLikeTimelineViewModel.State.NotAuthorized,
//                 is UserLikeTimelineViewModel.State.Blocked:
//                break
//            default:
//                if userLikeTimelineViewController.viewModel.items.value.isEmpty {
//                    userLikeTimelineViewController.viewModel.stateMachine.enter(UserLikeTimelineViewModel.State.Reloading.self)
//                }
//            }
//        }
    }

}

// MARK: - ProfileBannerInfoActionViewDelegate
//extension ProfileViewController: ProfileBannerInfoActionViewDelegate {
//
//    func profileBannerInfoActionView(_ profileBannerInfoActionView: ProfileBannerInfoActionView, followActionButtonPressed button: FollowActionButton) {
//        UserProviderFacade
//            .toggleUserFriendship(provider: self, sender: button)
//            .sink { _ in
//                // do nothing
//            } receiveValue: { _ in
//                // do nothing
//            }
//            .store(in: &disposeBag)
//    }
//
//}

// MARK: - ProfileHeaderViewDelegate
extension ProfileViewController: ProfileHeaderViewDelegate {
    
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, activeLabel: ActiveLabel, entityDidPressed entity: ActiveEntity) {
        
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
