//
//  ProfileViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-23.
//

import os.log
import UIKit
import Combine
import MastodonMeta
import MetaTextKit
import MastodonAsset
import MastodonLocalization
import MastodonUI
import Tabman
import CoreDataStack

protocol ProfileViewModelEditable {
    func isEdited() -> Bool
}

final class ProfileViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    public static let containerViewMarginForRegularHorizontalSizeClass: CGFloat = 64
    public static let containerViewMarginForCompactHorizontalSizeClass: CGFloat = 16
    
    let logger = Logger(subsystem: "ProfileViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ProfileViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    private(set) lazy var cancelEditingBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.cancel, style: .plain, target: self, action: #selector(ProfileViewController.cancelEditingBarButtonItemPressed(_:)))
        barButtonItem.tintColor = .white
        return barButtonItem
    }()
    
    private(set) lazy var settingBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(
            image: Asset.ObjectsAndTools.gear.image.withRenderingMode(.alwaysTemplate),
            style: .plain,
            target: self,
            action: #selector(ProfileViewController.settingBarButtonItemPressed(_:))
        )
        barButtonItem.tintColor = .white
        return barButtonItem
    }()
    
    private(set) lazy var shareBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(
            image: Asset.Arrow.squareAndArrowUp.image.withRenderingMode(.alwaysTemplate),
            style: .plain,
            target: self,
            action: #selector(ProfileViewController.shareBarButtonItemPressed(_:))
        )
        barButtonItem.tintColor = .white
        return barButtonItem
    }()
    
    private(set) lazy var favoriteBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(
            image: Asset.ObjectsAndTools.star.image.withRenderingMode(.alwaysTemplate),
            style: .plain,
            target: self,
            action: #selector(ProfileViewController.favoriteBarButtonItemPressed(_:))
        )
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
        refreshControl.tintColor = .white
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
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
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

        view.backgroundColor = ThemeService.shared.currentTheme.value.secondarySystemBackgroundColor
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.view.backgroundColor = theme.secondarySystemBackgroundColor
            }
            .store(in: &disposeBag)

        let barAppearance = UINavigationBarAppearance()
        if isModal {
            barAppearance.configureWithDefaultBackground()
        } else {
            barAppearance.configureWithTransparentBackground()
        }
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
            
        Publishers.CombineLatest4 (
            viewModel.suspended.eraseToAnyPublisher(),
            profileHeaderViewController.viewModel.isTitleViewDisplaying.eraseToAnyPublisher(),
            editingAndUpdatingPublisher.eraseToAnyPublisher(),
            barButtonItemHiddenPublisher.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] suspended, isTitleViewDisplaying, tuple1, tuple2 in
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
            
            guard !isTitleViewDisplaying else {
                return
            }
            
            guard isMeBarButtonItemsHidden else {
                items.append(self.settingBarButtonItem)
                items.append(self.shareBarButtonItem)
                items.append(self.favoriteBarButtonItem)
                return
            }
            
            if !isMoreMenuBarButtonItemHidden {
                items.append(self.moreMenuBarButtonItem)
            }
            if !isReplyBarButtonItemHidden {
                items.append(self.replyBarButtonItem)
            }
        }
        .store(in: &disposeBag)

        overlayScrollView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(ProfileViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        
        let postsUserTimelineViewModel = UserTimelineViewModel(context: context, domain: viewModel.domain.value, userID: viewModel.userID.value, queryFilter: UserTimelineViewModel.QueryFilter(excludeReplies: true))
        bind(userTimelineViewModel: postsUserTimelineViewModel)
        
        let repliesUserTimelineViewModel = UserTimelineViewModel(context: context, domain: viewModel.domain.value, userID: viewModel.userID.value, queryFilter: UserTimelineViewModel.QueryFilter(excludeReplies: false))
        bind(userTimelineViewModel: repliesUserTimelineViewModel)
        
        let mediaUserTimelineViewModel = UserTimelineViewModel(context: context, domain: viewModel.domain.value, userID: viewModel.userID.value, queryFilter: UserTimelineViewModel.QueryFilter(onlyMedia: true))
        bind(userTimelineViewModel: mediaUserTimelineViewModel)
        
        let profileAboutViewModel = ProfileAboutViewModel(context: context)
        
        profileSegmentedViewController.pagingViewController.viewModel = {
            let profilePagingViewModel = ProfilePagingViewModel(
                postsUserTimelineViewModel: postsUserTimelineViewModel,
                repliesUserTimelineViewModel: repliesUserTimelineViewModel,
                mediaUserTimelineViewModel: mediaUserTimelineViewModel,
                profileAboutViewModel: profileAboutViewModel
            )
            profilePagingViewModel.viewControllers.forEach { viewController in
                if let viewController = viewController as? NeedsDependency {
                    viewController.context = context
                    viewController.coordinator = coordinator
                }
            }
            return profilePagingViewModel
        }()
        
        profileSegmentedViewController.pagingViewController.addBar(
            profileHeaderViewController.buttonBar,
            dataSource: profileSegmentedViewController.pagingViewController.viewModel,
            at: .custom(view: profileHeaderViewController.view, layout: { buttonBar in
                buttonBar.translatesAutoresizingMaskIntoConstraints = false
                self.profileHeaderViewController.view.addSubview(buttonBar)
                NSLayoutConstraint.activate([
                    buttonBar.topAnchor.constraint(equalTo: self.profileHeaderViewController.profileHeaderView.bottomAnchor),
                    buttonBar.leadingAnchor.constraint(equalTo: self.profileHeaderViewController.view.leadingAnchor),
                    buttonBar.trailingAnchor.constraint(equalTo: self.profileHeaderViewController.view.trailingAnchor),
                    buttonBar.bottomAnchor.constraint(equalTo: self.profileHeaderViewController.view.bottomAnchor),
                    buttonBar.heightAnchor.constraint(equalToConstant: ProfileHeaderViewController.segmentedControlHeight).priority(.required - 1),
                ])
            })
        )
        updateBarButtonInsets()
        
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
        profileSegmentedViewController.pagingViewController.viewModel.profileAboutViewController.delegate = self
        profileSegmentedViewController.pagingViewController.pagingDelegate = self

        // bind view model
        bindProfile(
            headerViewModel: profileHeaderViewController.viewModel,
            aboutViewModel: profileAboutViewModel
        )
        
        bindTitleView()
        bindHeader()
        bindProfileRelationship()
        bindProfileDashboard()
        
        viewModel.needsPagingEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] needsPaingEnabled in
                guard let self = self else { return }
                self.profileSegmentedViewController.pagingViewController.isScrollEnabled = needsPaingEnabled
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
        guard let currentViewController = profileSegmentedViewController.pagingViewController.currentViewController as? ScrollViewContainer,
              let scrollView = currentViewController.scrollView
        else { return }
        
        currentPostTimelineTableViewContentSizeObservation = observeTableViewContentSize(scrollView: scrollView)
        scrollView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        currentPostTimelineTableViewContentSizeObservation = nil
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateBarButtonInsets()
    }
    
}

extension ProfileViewController {
    
    private func updateBarButtonInsets() {
        let margin: CGFloat = {
            switch traitCollection.userInterfaceIdiom {
            case .phone:
                return ProfileViewController.containerViewMarginForCompactHorizontalSizeClass
            default:
                return traitCollection.horizontalSizeClass == .regular ?
                    ProfileViewController.containerViewMarginForRegularHorizontalSizeClass :
                    ProfileViewController.containerViewMarginForCompactHorizontalSizeClass
            }
        }()
        
        profileHeaderViewController.buttonBar.layout.contentInset.left = margin
        profileHeaderViewController.buttonBar.layout.contentInset.right = margin
    }
    
}

extension ProfileViewController {

    private func bind(userTimelineViewModel: UserTimelineViewModel) {
        viewModel.domain.assign(to: \.domain, on: userTimelineViewModel).store(in: &disposeBag)
        viewModel.userID.assign(to: \.userID, on: userTimelineViewModel).store(in: &disposeBag)
        viewModel.isBlocking.assign(to: \.value, on: userTimelineViewModel.isBlocking).store(in: &disposeBag)
        viewModel.isBlockedBy.assign(to: \.value, on: userTimelineViewModel.isBlockedBy).store(in: &disposeBag)
        viewModel.suspended.assign(to: \.value, on: userTimelineViewModel.isSuspended).store(in: &disposeBag)
        viewModel.name.assign(to: \.value, on: userTimelineViewModel.userDisplayName).store(in: &disposeBag)
    }
    
    private func bindProfile(
        headerViewModel: ProfileHeaderViewModel,
        aboutViewModel: ProfileAboutViewModel
    ) {
        // header
        viewModel.avatarImageURL
            .receive(on: DispatchQueue.main)
            .assign(to: \.avatarImageURL, on: headerViewModel.displayProfileInfo)
            .store(in: &disposeBag)
        viewModel.name
            .map { $0 ?? "" }
            .receive(on: DispatchQueue.main)
            .assign(to: \.name, on: headerViewModel.displayProfileInfo)
            .store(in: &disposeBag)
        viewModel.bioDescription
            .receive(on: DispatchQueue.main)
            .assign(to: \.note, on: headerViewModel.displayProfileInfo)
            .store(in: &disposeBag)
    
        // about
        Publishers.CombineLatest(
            viewModel.fields.removeDuplicates(),
            viewModel.emojiMeta.removeDuplicates()
        )
        .map { fields, emojiMeta -> [ProfileFieldItem.FieldValue] in
            fields.map { ProfileFieldItem.FieldValue(name: $0.name, value: $0.value, emojiMeta: emojiMeta) }
        }
        .receive(on: DispatchQueue.main)
        .assign(to: \.fields, on: aboutViewModel.displayProfileInfo)
        .store(in: &disposeBag)
        
        // common
        viewModel.accountForEdit
            .assign(to: \.accountForEdit, on: headerViewModel)
            .store(in: &disposeBag)
        viewModel.accountForEdit
            .assign(to: \.accountForEdit, on: aboutViewModel)
            .store(in: &disposeBag)
        viewModel.emojiMeta
            .receive(on: DispatchQueue.main)
            .assign(to: \.emojiMeta, on: headerViewModel)
            .store(in: &disposeBag)
        viewModel.emojiMeta
            .receive(on: DispatchQueue.main)
            .assign(to: \.emojiMeta, on: aboutViewModel)
            .store(in: &disposeBag)
        viewModel.isEditing
            .assign(to: \.isEditing, on: headerViewModel)
            .store(in: &disposeBag)
        viewModel.isEditing
            .assign(to: \.isEditing, on: aboutViewModel)
            .store(in: &disposeBag)
    }
    
    private func bindTitleView() {
        Publishers.CombineLatest3(
            viewModel.name,
            viewModel.emojiMeta,
            viewModel.statusesCount
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] name, emojiMeta, statusesCount in
            guard let self = self else { return }
            guard let title = name, let statusesCount = statusesCount,
                  let formattedStatusCount = MastodonMetricFormatter().string(from: statusesCount) else {
                self.titleView.isHidden = true
                return
            }
            self.titleView.isHidden = false
            let subtitle = L10n.Plural.Count.MetricFormatted.post(formattedStatusCount, statusesCount)
            let mastodonContent = MastodonContent(content: title, emojis: emojiMeta)
            do {
                let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
                self.titleView.update(titleMetaContent: metaContent, subtitle: subtitle)
            } catch {

            }
        }
        .store(in: &disposeBag)
        viewModel.name
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                guard let self = self else { return }
                self.navigationItem.title = name
            }
            .store(in: &disposeBag)
    }
    
    private func bindHeader() {
        // heaer UI
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
        
        viewModel.username
            .map { username in username.flatMap { "@" + $0 } ?? " " }
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: profileHeaderViewController.profileHeaderView.usernameLabel)
            .store(in: &disposeBag)
        
        viewModel.isEditing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEditing in
                guard let self = self else { return }
                // set first responder for key command
                if !isEditing {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.profileSegmentedViewController.pagingViewController.becomeFirstResponder()
                    }
                }
                
                // dismiss keyboard if needs
                if !isEditing { self.view.endEditing(true) }
                
                self.profileHeaderViewController.buttonBar.isUserInteractionEnabled = !isEditing
                if isEditing {
                    // scroll to About page
                    self.profileSegmentedViewController.pagingViewController.scrollToPage(
                        .last,
                        animated: true,
                        completion: nil
                    )
                    self.profileSegmentedViewController.pagingViewController.isScrollEnabled = false
                } else {
                    self.profileSegmentedViewController.pagingViewController.isScrollEnabled = true
                }
                
                let animator = UIViewPropertyAnimator(duration: 0.33, curve: .easeInOut)
                animator.addAnimations {
                    self.profileHeaderViewController.profileHeaderView.statusDashboardView.alpha = isEditing ? 0.2 : 1.0
                }
                animator.startAnimation()
            }
            .store(in: &disposeBag)
        
        viewModel.needsImageOverlayBlurred
            .receive(on: DispatchQueue.main)
            .sink { [weak self] needsImageOverlayBlurred in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.33) {
                    let bannerEffect: UIVisualEffect? = needsImageOverlayBlurred ? ProfileHeaderView.bannerImageViewOverlayBlurEffect : nil
                    self.profileHeaderViewController.profileHeaderView.bannerImageViewOverlayVisualEffectView.effect = bannerEffect
                    let avatarEffect: UIVisualEffect? = needsImageOverlayBlurred ? ProfileHeaderView.avatarImageViewOverlayBlurEffect : nil
                    self.profileHeaderViewController.profileHeaderView.avatarImageViewOverlayVisualEffectView.effect = avatarEffect
                }
            }
            .store(in: &disposeBag)
    }
    
    private func bindProfileRelationship() {
        Publishers.CombineLatest(
            viewModel.$user,
            viewModel.relationshipActionOptionSet
        )
        .asyncMap { [weak self] user, relationshipSet -> UIMenu? in
            guard let self = self else { return nil }
            guard let user = user else {
                return nil
            }
            let name = user.displayNameWithFallback
            let _ = ManagedObjectRecord<MastodonUser>(objectID: user.objectID)
            let menu = MastodonMenu.setupMenu(
                actions: [
                    .muteUser(.init(name: name, isMuting: self.viewModel.isMuting.value)),
                    .blockUser(.init(name: name, isBlocking: self.viewModel.isBlocking.value)),
                    .reportUser(.init(name: name)),
                    .shareUser(.init(name: name)),
                ],
                delegate: self
            )
            return menu
        }
        .sink { [weak self] completion in
            guard let self = self else { return }
            switch completion {
            case .failure:
                self.moreMenuBarButtonItem.menu = nil
            case .finished:
                break
            }
        } receiveValue: { [weak self] menu in
            guard let self = self else { return }
            self.moreMenuBarButtonItem.menu = menu
        }
        .store(in: &disposeBag)
        
        viewModel.isRelationshipActionButtonHidden
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isHidden in
                guard let self = self else { return }
                self.profileHeaderViewController.profileHeaderView.relationshipActionButtonShadowContainer.isHidden = isHidden
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
                self.profileHeaderViewController.profileHeaderView.configure(state: isEditing ? .editing : .normal)
            } else {
                friendshipButton.configure(actionOptionSet: relationshipActionSet)
            }
        }
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
            self.profileHeaderViewController.viewModel.needsFiledCollectionViewHidden.value = isNeedSetHidden
            self.profileHeaderViewController.buttonBar.isUserInteractionEnabled = !isNeedSetHidden
            self.viewModel.needsPagePinToTop.value = isNeedSetHidden
        }
        .store(in: &disposeBag)
    }   // end func bindProfileRelationship
    
    private func bindProfileDashboard() {
        viewModel.statusesCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                guard let self = self else { return }
                let text = count.flatMap { MastodonMetricFormatter().string(from: $0) } ?? "-"
                self.profileHeaderViewController.profileHeaderView.statusDashboardView.postDashboardMeterView.numberLabel.text = text
                self.profileHeaderViewController.profileHeaderView.statusDashboardView.postDashboardMeterView.isAccessibilityElement = true
                self.profileHeaderViewController.profileHeaderView.statusDashboardView.postDashboardMeterView.accessibilityLabel = L10n.Plural.Count.post(count ?? 0)
            }
            .store(in: &disposeBag)
        viewModel.followingCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                guard let self = self else { return }
                let text = count.flatMap { MastodonMetricFormatter().string(from: $0) } ?? "-"
                self.profileHeaderViewController.profileHeaderView.statusDashboardView.followingDashboardMeterView.numberLabel.text = text
                self.profileHeaderViewController.profileHeaderView.statusDashboardView.followingDashboardMeterView.isAccessibilityElement = true
                self.profileHeaderViewController.profileHeaderView.statusDashboardView.followingDashboardMeterView.accessibilityLabel = L10n.Plural.Count.following(count ?? 0)
            }
            .store(in: &disposeBag)
        viewModel.followersCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                guard let self = self else { return }
                let text = count.flatMap { MastodonMetricFormatter().string(from: $0) } ?? "-"
                self.profileHeaderViewController.profileHeaderView.statusDashboardView.followersDashboardMeterView.numberLabel.text = text
                self.profileHeaderViewController.profileHeaderView.statusDashboardView.followersDashboardMeterView.isAccessibilityElement = true
                self.profileHeaderViewController.profileHeaderView.statusDashboardView.followersDashboardMeterView.accessibilityLabel = L10n.Plural.Count.follower(count ?? 0)
            }
            .store(in: &disposeBag)
    }
    
    private func handleMetaPress(_ meta: Meta) {
        switch meta {
        case .url(_, _, let url, _):
            guard let url = URL(string: url) else { return }
            coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
        case .mention(_, _, let userInfo):
            guard let href = userInfo?["href"] as? String,
                  let url = URL(string: href) else { return }
            coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
        case .hashtag(_, let hashtag, _):
            let hashtagTimelineViewModel = HashtagTimelineViewModel(context: context, hashtag: hashtag)
            coordinator.present(scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel), from: nil, transition: .show)
        case .email, .emoji:
            break
        }
    }

}

extension ProfileViewController {
    
    @objc private func cancelEditingBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        viewModel.isEditing.value = false
    }
    
    @objc private func settingBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let setting = context.settingService.currentSetting.value else { return }
        let settingsViewModel = SettingsViewModel(context: context, setting: setting)
        coordinator.present(scene: .settings(viewModel: settingsViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
    @objc private func shareBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let user = viewModel.user else { return }
        let record: ManagedObjectRecord<MastodonUser> = .init(objectID: user.objectID)
        Task {
            let _activityViewController = try await DataSourceFacade.createActivityViewController(
                dependency: self,
                user: record
            )
            guard let activityViewController = _activityViewController else { return }
            self.coordinator.present(
                scene: .activityViewController(
                    activityViewController: activityViewController,
                    sourceView: nil,
                    barButtonItem: sender
                ),
                from: self,
                transition: .activityViewControllerPresent(animated: true, completion: nil)
            )
        }   // end Task
    }
    
    @objc private func favoriteBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        let favoriteViewModel = FavoriteViewModel(context: context)
        coordinator.present(scene: .favorite(viewModel: favoriteViewModel), from: self, transition: .show)
    }
    
    @objc private func replyBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        guard let mastodonUser = viewModel.user else { return }
        let composeViewModel = ComposeViewModel(
            context: context,
            composeKind: .mention(user: .init(objectID: mastodonUser.objectID)),
            authenticationBox: authenticationBox
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
                postTimelineView.scrollView?.contentOffset.y = 0
            }
            contentOffsets.removeAll()
        } else {
            containerScrollView.contentOffset.y = topMaxContentOffsetY
            if viewModel.needsPagePinToTop.value {
                // do nothing
            } else {
                if let customScrollViewContainerController = profileSegmentedViewController.pagingViewController.currentViewController as? ScrollViewContainer {
                    let contentOffsetY = scrollView.contentOffset.y - containerScrollView.contentOffset.y
                    customScrollViewContainerController.scrollView?.contentOffset.y = contentOffsetY
                }
            }
            
        }

        // elastically banner image
        let headerScrollProgress = (containerScrollView.contentOffset.y - containerScrollView.safeAreaInsets.top) / topMaxContentOffsetY
        let throttle = ProfileHeaderViewController.headerMinHeight / topMaxContentOffsetY
        profileHeaderViewController.updateHeaderScrollProgress(headerScrollProgress, throttle: throttle)
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
    
}

// MARK: - ProfilePagingViewControllerDelegate
extension ProfileViewController: ProfilePagingViewControllerDelegate {

    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostCustomScrollViewContainerController postTimelineViewController: ScrollViewContainer, atIndex index: Int) {
        os_log("%{public}s[%{public}ld], %{public}s: select at index: %ld", ((#file as NSString).lastPathComponent), #line, #function, index)
        
//        // update segemented control
//        if index < profileHeaderViewController.pageSegmentedControl.numberOfSegments {
//            profileHeaderViewController.pageSegmentedControl.selectedSegmentIndex = index
//        }
        
        // save content offset
        overlayScrollView.contentOffset.y = contentOffsets[index] ?? containerScrollView.contentOffset.y
        
        // setup observer and gesture fallback
        if let scrollView = postTimelineViewController.scrollView {
            currentPostTimelineTableViewContentSizeObservation = observeTableViewContentSize(scrollView: scrollView)
            scrollView.panGestureRecognizer.require(toFail: overlayScrollView.panGestureRecognizer)
        }
    }

}

// MARK: - ProfileHeaderViewDelegate
extension ProfileViewController: ProfileHeaderViewDelegate {
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, avatarButtonDidPressed button: AvatarButton) {
        guard let user = viewModel.user else { return }
        let record: ManagedObjectRecord<MastodonUser> = .init(objectID: user.objectID)
        
        Task {
            try await DataSourceFacade.coordinateToMediaPreviewScene(
                dependency: self,
                user: record,
                previewContext: DataSourceFacade.ImagePreviewContext(
                    imageView: button.avatarImageView,
                    containerView: .profileAvatar(profileHeaderView)
                )
            )
        }   // end Task
    }
    
    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, bannerImageViewDidPressed imageView: UIImageView) {
        guard let user = viewModel.user else { return }
        let record: ManagedObjectRecord<MastodonUser> = .init(objectID: user.objectID)
        
        Task {
            try await DataSourceFacade.coordinateToMediaPreviewScene(
                dependency: self,
                user: record,
                previewContext: DataSourceFacade.ImagePreviewContext(
                    imageView: imageView,
                    containerView: .profileBanner(profileHeaderView)
                )
            )
        }   // end Task
    }
    
    func profileHeaderView(
        _ profileHeaderView: ProfileHeaderView,
        relationshipButtonDidPressed button: ProfileRelationshipActionButton
    ) {
        let relationshipActionSet = viewModel.relationshipActionOptionSet.value

        // handle edit logic for editable profile
        // handle relationship logic for non-editable profile
        if relationshipActionSet.contains(.edit) {
            // do nothing when updating
            guard !viewModel.isUpdating.value else { return }
            
            guard let profileHeaderViewModel = profileHeaderViewController.viewModel else { return }
            guard let profileAboutViewModel = profileSegmentedViewController.pagingViewController.viewModel.profileAboutViewController.viewModel else { return }
            
            let isEdited = profileHeaderViewModel.isEdited()
                        || profileAboutViewModel.isEdited()
            
            if isEdited {
                // update profile if changed
                viewModel.isUpdating.value = true
                Task {
                    do {
                        _ = try await viewModel.updateProfileInfo(
                            headerProfileInfo: profileHeaderViewModel.editProfileInfo,
                            aboutProfileInfo: profileAboutViewModel.editProfileInfo
                        )
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update profile info success")
                        self.viewModel.isEditing.value = false
                        
                    } catch {
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update profile info fail: \(error.localizedDescription)")
                    }
                    
                    // finish updating
                    self.viewModel.isUpdating.value = false
                }
            } else {
                // set `updating` then toggle `edit` state
                viewModel.isUpdating.value = true
                viewModel.fetchEditProfileInfo()
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] completion in
                        guard let self = self else { return }
                        defer {
                            // finish updating
                            self.viewModel.isUpdating.value = false
                        }
                        switch completion {
                        case .failure(let error):
                            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch profile info for edit fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                            let alertController = UIAlertController(for: error, title: L10n.Common.Alerts.EditProfileFailure.title, preferredStyle: .alert)
                            let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default, handler: nil)
                            alertController.addAction(okAction)
                            self.coordinator.present(
                                scene: .alertController(alertController: alertController),
                                from: nil,
                                transition: .alertController(animated: true, completion: nil)
                            )
                        case .finished:
                            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch profile info for edit success", ((#file as NSString).lastPathComponent), #line, #function)
                            // enter editing mode
                            self.viewModel.isEditing.value.toggle()
                        }
                    } receiveValue: { [weak self] response in
                        guard let self = self else { return }
                        self.viewModel.accountForEdit.value = response.value
                    }
                    .store(in: &disposeBag)
            }
        } else {
            guard let relationshipAction = relationshipActionSet.highPriorityAction(except: .editOptions) else { return }
            switch relationshipAction {
            case .none:
                break
            case .follow, .request, .pending, .following:
                guard let user = viewModel.user else { return }
                let reocrd = ManagedObjectRecord<MastodonUser>(objectID: user.objectID)
                guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
                Task {
                    try await DataSourceFacade.responseToUserFollowAction(
                        dependency: self,
                        user: reocrd,
                        authenticationBox: authenticationBox
                    )
                }
            case .muting:
                guard let authenticationBox = self.context.authenticationService.activeMastodonAuthenticationBox.value else { return }
                guard let user = viewModel.user else { return }
                let name = user.displayNameWithFallback
                
                let alertController = UIAlertController(
                    title: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.title,
                    message: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.message(name),
                    preferredStyle: .alert
                )
                let record = ManagedObjectRecord<MastodonUser>(objectID: user.objectID)
                let unmuteAction = UIAlertAction(title: L10n.Common.Controls.Friendship.unmute, style: .default) { [weak self] _ in
                    guard let self = self else { return }
                    Task {
                        try await DataSourceFacade.responseToUserMuteAction(
                            dependency: self,
                            user: record,
                            authenticationBox: authenticationBox
                        )
                    }
                }
                alertController.addAction(unmuteAction)
                let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                present(alertController, animated: true, completion: nil)
            case .blocking:
                guard let authenticationBox = self.context.authenticationService.activeMastodonAuthenticationBox.value else { return }
                guard let user = viewModel.user else { return }
                let name = user.displayNameWithFallback
                
                let alertController = UIAlertController(
                    title: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.title,
                    message: L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.message(name),
                    preferredStyle: .alert
                )
                let record = ManagedObjectRecord<MastodonUser>(objectID: user.objectID)
                let unblockAction = UIAlertAction(title: L10n.Common.Controls.Friendship.unblock, style: .default) { [weak self] _ in
                    guard let self = self else { return }
                    Task {
                        try await DataSourceFacade.responseToUserBlockAction(
                            dependency: self,
                            user: record,
                            authenticationBox: authenticationBox
                        )
                    }
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

    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, metaTextView: MetaTextView, metaDidPressed meta: Meta) {
        handleMetaPress(meta)
    }

    func profileHeaderView(_ profileHeaderView: ProfileHeaderView, profileStatusDashboardView dashboardView: ProfileStatusDashboardView, dashboardMeterViewDidPressed dashboardMeterView: ProfileStatusDashboardMeterView, meter: ProfileStatusDashboardView.Meter) {
        switch meter {
        case .post:
            // do nothing
            break
        case .follower:
            guard let domain = viewModel.domain.value,
                  let userID = viewModel.userID.value
            else { return }
            let followerListViewModel = FollowerListViewModel(
                context: context,
                domain: domain,
                userID: userID
            )
            coordinator.present(
                scene: .follower(viewModel: followerListViewModel),
                from: self,
                transition: .show
            )
        case .following:
            guard let domain = viewModel.domain.value,
                  let userID = viewModel.userID.value
            else { return }
            let followingListViewModel = FollowingListViewModel(
                context: context,
                domain: domain,
                userID: userID
            )
            coordinator.present(
                scene: .following(viewModel: followingListViewModel),
                from: self,
                transition: .show
            )
        }
    }

}

// MARK: - ProfileAboutViewControllerDelegate
extension ProfileViewController: ProfileAboutViewControllerDelegate {
    func profileAboutViewController(_ viewController: ProfileAboutViewController, profileFieldCollectionViewCell: ProfileFieldCollectionViewCell, metaLabel: MetaLabel, didSelectMeta meta: Meta) {
        handleMetaPress(meta)
    }
}

// MARK: - MastodonMenuDelegate
extension ProfileViewController: MastodonMenuDelegate {
    func menuAction(_ action: MastodonMenu.Action) {
        guard let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return }
        guard let user = viewModel.user else { return }
        
        let userRecord: ManagedObjectRecord<MastodonUser> = .init(objectID: user.objectID)
        
        Task {
            try await DataSourceFacade.responseToMenuAction(
                dependency: self,
                action: action,
                menuContext: DataSourceFacade.MenuContext(
                    author: userRecord,
                    status: nil,
                    button: nil,
                    barButtonItem: self.moreMenuBarButtonItem
                ),
                authenticationBox: authenticationBox
            )
        }   // end Task
    }
}

// MARK: - ScrollViewContainer
extension ProfileViewController: ScrollViewContainer {
    var scrollView: UIScrollView? {
        return overlayScrollView
    }
}

//extension ProfileViewController {
//
//    override var keyCommands: [UIKeyCommand]? {
//        if !viewModel.isEditing.value {
//            return segmentedControlNavigateKeyCommands
//        }
//
//        return nil
//    }
//
//}

// MARK: - SegmentedControlNavigateable
//extension ProfileViewController: SegmentedControlNavigateable {
//    var navigateableSegmentedControl: UISegmentedControl {
//        profileHeaderViewController.pageSegmentedControl
//    }
//
//    @objc func segmentedControlNavigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
//        segmentedControlNavigateKeyCommandHandler(sender)
//    }
//}
