//
//  ProfileViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-23.
//

import UIKit
import Combine
import MastodonMeta
import MetaTextKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization
import CoreDataStack
import TabBarPager
import XLPagerTabStrip
import MastodonSDK

fileprivate enum ActionableRelationship {
    case blocked
    case domainBlocked
    case muted
    case followed(Bool)
    
    init(_ relationship: Mastodon.Entity.Relationship) {
        if relationship.blocking {
            self = .blocked
        } else if relationship.domainBlocking {
            self = .domainBlocked
        } else if relationship.muting {
            self = .muted
        } else {
            self = .followed(relationship.following)
        }
    }
}

enum ProfileViewError: Error {
    case invalidStateTransition
    case invalidDomain
    case accountNotFound
    case attemptToPushInvalidProfileChanges
    case profileChangeServerError(String)
}

extension ProfileViewController.ProfileType: UserIdentifier {
    public var domain: String {
        return accountToDisplay.domain ?? ""
    }
    
    public var userID: MastodonSDK.Mastodon.Entity.Account.ID {
        return accountToDisplay.id
    }
    
    
}

extension ProfileViewController {
    public enum ProfileType {
        case me(Mastodon.Entity.Account)
        case notMe(me: Mastodon.Entity.Account, displayAccount: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?)
        
        var isMe: Bool {
            switch self {
            case .me:
                return true
            case .notMe:
                return false
            }
        }
        
        var accountToDisplay: Mastodon.Entity.Account {
            switch self {
            case .me(let account):
                return account
            case .notMe(_, let account, _):
                return account
            }
        }
        
        var myAccount: Mastodon.Entity.Account {
            switch self {
            case .me(let account):
                return account
            case .notMe(let myAccount, _, _):
                return myAccount
            }
        }
        
        var myRelationshipToDisplayedAccount: Mastodon.Entity.Relationship? {
            switch self {
            case .me:
                return nil
            case .notMe(_, _, let relationship):
                return relationship
            }
        }
        
        var canEditProfile: Bool {
            switch self {
            case .me: return true
            case .notMe: return false
            }
        }
    }
}

@MainActor
class ProfileViewController: UIViewController, MediaPreviewableViewController, AuthContextProvider {
    
    var subscriptions = Set<AnyCancellable>()
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    private var profilePagingViewController: ProfilePagingViewController?
    
    var authenticationBox: MastodonAuthenticationBox
    private var viewModel: ProfileViewModelImmutable {
        didSet {
            updateDisplay(viewModel)
        }
    }
    
    required init(_ profileType: ProfileType, authenticationBox: MastodonAuthenticationBox) {
        self.authenticationBox = AuthenticationServiceProvider.shared.currentActiveUser.value ?? authenticationBox
        self.viewModel = ProfileViewModelImmutable(profileType: profileType, state: .idle)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createSupplementaryViews()
        setUpSupplementaryViews()
        setAppearanceDetails()
        
        tabBarPagerController.delegate = self
        tabBarPagerController.dataSource = self
        
        navigationItem.titleView = titleView
        
        addChild(tabBarPagerController)
        tabBarPagerController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabBarPagerController.view)
        tabBarPagerController.didMove(toParent: self)
        tabBarPagerController.view.pinToParent()
        
        tabBarPagerController.relayScrollView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(ProfileViewController.refreshControlValueChanged(_:)), for: .valueChanged)
    
        updateDisplay(viewModel)
        
        reloadCurrentTimeline()
        
        PublisherService.shared.statusPublishResult.sink { [weak self] result in
            if case .success(.edit(let status)) = result {
                self?.updateViewModelsWithDataControllers(status: .fromEntity(status.value), intent: .edit)
            }
        }.store(in: &subscriptions)
        
        AuthenticationServiceProvider.shared.instanceConfigurationUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedDomain in
                guard let self else { return }
                if updatedDomain == self.authenticationBox.domain {
                    if let updatedAuthenticationBox = AuthenticationServiceProvider.shared.currentActiveUser.value {
                        authenticationBox = updatedAuthenticationBox
                    }
                }
            }.store(in: &subscriptions)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        Task {
            await self.refetchAllData()
        }
    }
    
    private func updateDisplay(_ viewModel: ProfileViewModelImmutable) {
        guard isViewLoaded else { return }
        // TODO: careful about resetting things if we failed to push edits
        
        if !viewModel.state.isUpdating {
            if refreshControl.isRefreshing {
                refreshControl.endRefreshing()
            }
        }
        
        // Bridge to the old way of doing things until we replace the UI sometime in the future
        updateHeader(viewModel)
        updateAboutView(viewModel)
        updateTabBarPager(viewModel)
        updatePagingViewController(viewModel)
        updateBarButtonItems(viewModel)
        updateMoreButton(viewModel)
    }
    
    private func updateHeader(_ viewModel: ProfileViewModelImmutable) {
        guard let headerViewControllerViewModel = profileHeaderViewController?.viewModel else {
            return
        }
        guard let headerViewViewModel = profileHeaderViewController?.profileHeaderView.viewModel else { return }
        
        let relationship = viewModel.profileType.myRelationshipToDisplayedAccount
        headerViewControllerViewModel.relationship = relationship
        headerViewViewModel.relationship = relationship
        
        headerViewControllerViewModel.account = viewModel.profileType.accountToDisplay
        headerViewControllerViewModel.isEditing = viewModel.state.isEditing
        headerViewControllerViewModel.isUpdating = viewModel.state.isUpdating
        headerViewControllerViewModel.accountForEdit = viewModel.state.isEditing ? viewModel.profileType.accountToDisplay : nil
        
        if viewModel.state.isEditing {
            headerViewControllerViewModel.setProfileInfo(accountForEdit: viewModel.profileType.accountToDisplay)
        }
        
        guard let relationship else { return }
        
        for userTimeLineViewModel in [
            (profilePagingViewController?.viewModel?.postUserTimelineViewController as? UserTimelineViewController)?.viewModel,
            (profilePagingViewController?.viewModel?.repliesUserTimelineViewController as? UserTimelineViewController)?.viewModel,
            (profilePagingViewController?.viewModel?.mediaUserTimelineViewController as? UserTimelineViewController)?.viewModel,
        ] {
            userTimeLineViewModel?.isBlocking = relationship.blocking
            userTimeLineViewModel?.isBlockedBy = relationship.blockedBy
            userTimeLineViewModel?.isSuspended = viewModel.profileType.accountToDisplay.suspended ?? false
        }
    }
    
    private func updateAboutView(_ viewModel: ProfileViewModelImmutable) {
        guard let aboutViewModel = profilePagingViewController?.viewModel?.profileAboutViewController.viewModel else { return }
        aboutViewModel.fields = viewModel.profileType.accountToDisplay.mastodonFields
        aboutViewModel.account = viewModel.profileType.accountToDisplay
        aboutViewModel.isEditing = viewModel.state.isEditing
        aboutViewModel.accountForEdit = viewModel.state.isEditing ? viewModel.profileType.accountToDisplay : nil
    }
    
    private func updateBarButtonItems(_ viewModel: ProfileViewModelImmutable) {
        self.cancelEditingBarButtonItem.isEnabled = !viewModel.state.isUpdating
        
        var items: [UIBarButtonItem] = []
        defer {
            if items.isNotEmpty {
                self.navigationItem.rightBarButtonItems = items
            } else {
                self.navigationItem.rightBarButtonItems = nil
            }
        }
        
        let suspended = viewModel.profileType.accountToDisplay.suspended ?? false
        
        guard !suspended else { return }
        
        guard !viewModel.state.isEditing else {
            items.append(self.cancelEditingBarButtonItem)
            return
        }
        
        let isTitleViewDisplaying = profileHeaderViewController?.viewModel.isTitleViewDisplaying ?? false
        guard !isTitleViewDisplaying else {
            return
        }
        
        guard viewModel.hideIsMeBarButtonItems else {
            items.append(self.settingBarButtonItem)
            items.append(self.shareBarButtonItem)
            items.append(self.favoriteBarButtonItem)
            items.append(self.bookmarkBarButtonItem)
            
            if self.authenticationBox.authentication.instanceConfiguration?.isAvailable(.followTags) == true {
                items.append(self.followedTagsBarButtonItem)
            }
            
            return
        }
        
        if !viewModel.hideMoreMenuBarButtonItem {
            items.append(self.moreMenuBarButtonItem)
        }
        if !viewModel.hideReplyBarButtonItem {
            items.append(self.replyBarButtonItem)
        }
    }
    
    private func updateMoreButton(_ viewModel: ProfileViewModelImmutable) {
        switch viewModel.profileType {
        case .me:
            moreMenuBarButtonItem.menu = nil
        case .notMe(let me, let displayAccount, let relationship):
            guard let relationship, let domain = displayAccount.domainFromAcct, let myDomain = me.domainFromAcct else {
                moreMenuBarButtonItem.menu = nil
                return
            }
            
            let name = displayAccount.displayNameWithFallback
            
            var items: [MastodonMenu.Submenu] = []
            
            items.append(MastodonMenu.Submenu(actions: [
                .shareUser(.init(name: name)),
                .openUserInBrowser(URL(string: displayAccount.url)),
                .copyProfileLink(URL(string: displayAccount.url))
            ]))
            
            
            var relationshipActions: [MastodonMenu.Action] = [
                .followUser(.init(name: name, isFollowing: relationship.following)),
                .muteUser(.init(name: name, isMuting: relationship.muting))
            ]
            
            if relationship.following {
                relationshipActions.append(.hideReblogs(.init(showReblogs: relationship.showingReblogs)))
            }
            
            items.append(MastodonMenu.Submenu(actions: relationshipActions))
            
            var destructiveActions: [MastodonMenu.Action] = [
                .blockUser(.init(name: name, isBlocking: relationship.blocking)),
                .reportUser(.init(name: name)),
            ]
            
            if myDomain != domain {
                destructiveActions.append(
                    .blockDomain(.init(domain: domain, isBlocking: relationship.domainBlocking))
                )
            }
            
            items.append(MastodonMenu.Submenu(actions: destructiveActions))
            
            let menu = MastodonMenu.setupMenu(
                submenus: items,
                delegate: self
            )
            
            moreMenuBarButtonItem.menu = menu
        }
    }
    
    private func updateTabBarPager(_ viewModel: ProfileViewModelImmutable) {
        tabBarPagerController.relayScrollView.refreshControl = viewModel.state.isEditing ? nil : refreshControl
    }
    
    private func updatePagingViewController(_ viewModel: ProfileViewModelImmutable) {
        guard let pagingViewController = profilePagingViewController else { return }
        pagingViewController.containerView.isScrollEnabled = viewModel.isPagingEnabled
        pagingViewController.buttonBarView.isUserInteractionEnabled = viewModel.isPagingEnabled
        
        // set first responder for key command
        if !viewModel.state.isEditing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                pagingViewController.becomeFirstResponder()
            }
            // dismiss keyboard if needs
            self.view.endEditing(true)
        }
        
        if viewModel.state.isEditing,
           let index = pagingViewController.viewControllers.firstIndex(where: { type(of: $0) is ProfileAboutViewController.Type }),
           pagingViewController.canMoveTo(index: index)
        {
            pagingViewController.moveToViewController(at: index)
        }
    }

    
    private func createSupplementaryViews() {
        profileHeaderViewController = createProfileHeaderViewController()
        profilePagingViewController = createProfilePagingViewController()
    }
    
    private func setUpSupplementaryViews() {
        profileHeaderViewController?.delegate = self
        profilePagingViewController?.viewModel?.profileAboutViewController.delegate = self
    }
    
    private func setAppearanceDetails() {
        view.backgroundColor = .secondarySystemBackground
        let barAppearance = UINavigationBarAppearance()
        if isModal {
            barAppearance.configureWithDefaultBackground()
        } else {
            barAppearance.configureWithTransparentBackground()
        }
        navigationItem.standardAppearance = barAppearance
        navigationItem.compactAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance
    }
    
    // MARK: From original ProfileViewController
    
    private(set) lazy var cancelEditingBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(title: L10n.Common.Controls.Actions.cancel, style: .plain, target: self, action: #selector(ProfileViewController.cancelEditingBarButtonItemPressed(_:)))
        barButtonItem.tintColor = .white
        return barButtonItem
    }()
    
    private(set) lazy var settingBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear")?.withRenderingMode(.alwaysTemplate),
            style: .plain,
            target: self,
            action: #selector(ProfileViewController.settingBarButtonItemPressed(_:))
        )
        barButtonItem.tintColor = .white
        barButtonItem.accessibilityLabel = L10n.Common.Controls.Actions.settings
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
        barButtonItem.accessibilityLabel = L10n.Common.Controls.Actions.share
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
        barButtonItem.accessibilityLabel = L10n.Scene.Favorite.title
        return barButtonItem
    }()
    
    private(set) lazy var bookmarkBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(
            image: Asset.ObjectsAndTools.bookmark.image.withRenderingMode(.alwaysTemplate),
            style: .plain,
            target: self,
            action: #selector(ProfileViewController.bookmarkBarButtonItemPressed(_:))
        )
        barButtonItem.tintColor = .white
        barButtonItem.accessibilityLabel = L10n.Scene.Bookmark.title
        return barButtonItem
    }()
    
    private(set) lazy var replyBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrowshape.turn.up.left"), style: .plain, target: self, action: #selector(ProfileViewController.replyBarButtonItemPressed(_:)))
        barButtonItem.tintColor = .white
        barButtonItem.accessibilityLabel = L10n.Common.Controls.Actions.reply
        return barButtonItem
    }()
    
    let moreMenuBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: nil, action: nil)
        barButtonItem.tintColor = .white
        barButtonItem.accessibilityLabel = L10n.Common.Controls.Actions.seeMore
        return barButtonItem
    }()
    
    private(set) lazy var followedTagsBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(image: UIImage(systemName: "number"), style: .plain, target: self, action: #selector(ProfileViewController.followedTagsItemPressed(_:)))
        barButtonItem.tintColor = .white
        barButtonItem.accessibilityLabel = L10n.Scene.FollowedTags.title
        return barButtonItem
    }()
    
    let refreshControl: RefreshControl = {
        let refreshControl = RefreshControl()
        refreshControl.tintColor = .white
        return refreshControl
    }()
    
    private(set) lazy var tabBarPagerController = TabBarPagerController()
    
    private(set) var profileHeaderViewController: ProfileHeaderViewController?
    
    private func createProfileHeaderViewController() -> ProfileHeaderViewController {
        let viewController = ProfileHeaderViewController(authenticationBox: authenticationBox, account: viewModel.profileType.accountToDisplay, me: viewModel.profileType.myAccount, relationship: viewModel.profileType.myRelationshipToDisplayedAccount)
        return viewController
    }
    
    private func createProfilePagingViewController() -> ProfilePagingViewController {
        let profilePagingViewController = ProfilePagingViewController()
        let timelineUserIdentifier = viewModel.profileType
        
        let posts = userTimelineViewModel(.posts)
        let postsAndReplies = userTimelineViewModel(.postsAndReplies)
        let media = userTimelineViewModel(.media)
        posts.userIdentifier = timelineUserIdentifier
        postsAndReplies.userIdentifier = timelineUserIdentifier
        media.userIdentifier = timelineUserIdentifier
        
        profilePagingViewController.viewModel = {
            let profilePagingViewModel = ProfilePagingViewModel(
                postsUserTimelineViewModel: posts,
                repliesUserTimelineViewModel: postsAndReplies,
                mediaUserTimelineViewModel: media,
                profileAboutViewModel: profileAboutViewModel
            )
            return profilePagingViewModel
        }()
        return profilePagingViewController
    }
}

extension ProfileViewController: ProfileHeaderViewControllerDelegate {
    // TODO: replace delegate with async streams
    
    func profileHeaderViewController(_ profileHeaderViewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, relationshipButtonDidPressed button: MastodonUI.ProfileRelationshipActionButton) {
        relationshipActionButtonTapped()
    }
    
    func profileHeaderViewController(_ profileHeaderViewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, metaTextView: MetaTextKit.MetaTextView, metaDidPressed meta: Meta) {
        handleMetaPress(meta)
    }
    
    private func userTimelineViewModel(_ timelineType: TimelineType) -> UserTimelineViewModel {
        return UserTimelineViewModel(
        authenticationBox: authenticationBox,
        title: timelineType.title,
        queryFilter: timelineType.queryFilter
    )
    }

    private var profileAboutViewModel: ProfileAboutViewModel { ProfileAboutViewModel(account: viewModel.profileType.accountToDisplay)
    }
    
    enum TimelineType {
        case posts
        case postsAndReplies
        case media
        
        var title: String {
            switch self {
            case .posts:
                return L10n.Scene.Profile.SegmentedControl.posts
            case .postsAndReplies:
                return L10n.Scene.Profile.SegmentedControl.postsAndReplies
            case .media:
                return L10n.Scene.Profile.SegmentedControl.media
            }
        }
        
        var queryFilter: UserTimelineViewModel.QueryFilter {
            switch self {
            case .posts:
                return UserTimelineViewModel.QueryFilter(excludeReplies: true)
            case .postsAndReplies:
                return UserTimelineViewModel.QueryFilter(excludeReplies: false, excludeReblogs: true)
            case .media:
                return UserTimelineViewModel.QueryFilter(onlyMedia: true)
            }
        }
        
    }
}

// MARK: API Calls
extension ProfileViewController {
    
    private func reloadCurrentTimeline() {
        if let userTimelineViewController = profilePagingViewController?.currentViewController as? UserTimelineViewController {
            userTimelineViewController.viewModel.stateMachine.enter(UserTimelineViewModel.State.Reloading.self)
        }
    }
    
    private func refetchAllData() async {
        guard viewModel.state == .idle else { return }
        
        let reset = viewModel
        
        viewModel = ProfileViewModelImmutable(profileType: viewModel.profileType, state: .updating)
        
        do {
            let account = viewModel.profileType.accountToDisplay
            if let domain = account.domain {
                let updatedAccount = try await refetchDisplayedAccount()
                switch viewModel.profileType {
                case .me:
                    viewModel = ProfileViewModelImmutable(profileType: .me(updatedAccount), state: .idle)
                case .notMe:
                    // also update me and my relationship
                    let updatedMe = try await APIService.shared.accountInfo(authenticationBox)
                    let updatedRelationship = try await APIService.shared.relationship(forAccounts: [updatedAccount], authenticationBox: authenticationBox).value.first
                    viewModel = ProfileViewModelImmutable(profileType: .notMe(me: updatedMe, displayAccount: updatedAccount, relationship: updatedRelationship ?? viewModel.profileType.myRelationshipToDisplayedAccount), state: .idle)
                }
            }
        } catch let error {
            switch viewModel.profileType {
            case .me:
                    displayError(error, andResetView: reset)
            default:
                break
            }
        }
    }
    
    private func refetchDisplayedAccount() async throws -> Mastodon.Entity.Account {
        switch viewModel.profileType {
        case .me:
            let (account, authBox) = try await APIService.shared.verifyAndActivateUser(domain: authenticationBox.domain, clientID: authenticationBox.authentication.clientID, clientSecret: authenticationBox.authentication.clientSecret, authorization: authenticationBox.userAuthorization)
            return account
        case .notMe(_, let displayAccount, let relationship):
            guard let domain = displayAccount.domain else { throw ProfileViewError.invalidDomain }
            guard let refreshedAccount = try await APIService.shared.fetchNotMeUser(username: displayAccount.acct, domain: domain, authenticationBox: authenticationBox) else { throw ProfileViewError.accountNotFound }
            return refreshedAccount
        }
    }
    
    func pushProfileChanges(
        headerDetails: ProfileHeaderDetails,
        profileFields: [ (String, String) ]
    ) async throws -> Mastodon.Entity.Account {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let newBannerImage: UIImage?
        let newAvatarImage: UIImage?
        
        profileHeaderViewController?.viewModel.isUpdating = true
        defer { profileHeaderViewController?.viewModel.isUpdating = false }
        
        if case let .local(image) = headerDetails.bannerImage {
            if image.size.width <= ProfileHeaderViewModel.bannerImageMaxSizeInPixel.width {
                newBannerImage = image
            } else {
                newBannerImage = image.af.imageScaled(to: ProfileHeaderViewModel.bannerImageMaxSizeInPixel)
            }
        } else {
            newBannerImage = nil
        }

        if case let .local(image) = headerDetails.avatarImage {
            if image.size.width <= ProfileHeaderViewModel.avatarImageMaxSizeInPixel.width {
                newAvatarImage = image
            } else {
                newAvatarImage = image.af.imageScaled(to: ProfileHeaderViewModel.avatarImageMaxSizeInPixel)
            }
        } else { newAvatarImage = nil }
        
        let fieldsAttributes = profileFields.map { Mastodon.Entity.Field(name: $0.0, value: $0.1) }
        
        let query = Mastodon.API.Account.UpdateCredentialQuery(
            discoverable: nil,
            bot: nil,
            displayName: headerDetails.displayName,
            note: headerDetails.bioText,
            avatar: newAvatarImage.flatMap { Mastodon.Query.MediaAttachment.png($0.pngData()) },
            header: newBannerImage.flatMap { Mastodon.Query.MediaAttachment.png($0.pngData()) },
            locked: nil,
            source: nil,
            fieldsAttributes: fieldsAttributes
        )
        let response = try await APIService.shared.accountUpdateCredentials(
            domain: domain,
            query: query,
            authorization: authorization
        )
        // TODO: Publish the details, rather than using notification center to broadcast. This may actually already be handled in some other way.
        NotificationCenter.default.post(name: .userFetched, object: nil)
        
        return response.value
    }
}

// MARK: Older code
extension ProfileViewController {
    // title view nested in header
    var titleView: DoubleTitleLabelNavigationBarTitleView? {
        profileHeaderViewController?.titleView
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        profileHeaderViewController?.updateHeaderContainerSafeAreaInset(view.safeAreaInsets)
    }
    
    @objc private func refreshControlValueChanged(_ sender: RefreshControl) {
        let reset = viewModel
        Task { [weak self] in
            guard let s = self else { return }
            do {
                await s.refetchAllData()
            } catch let error {
                s.displayError(error, andResetView: reset)
            }
        }
    }
    
    private func relationshipActionButtonTapped() {
        // if viewing your own profile, this means edit or save
        // if viewing another account, this is unblock if blocked, or unmute if muted, or follow/unfollow
        guard viewModel.state.actionButtonEnabled else { return }

        switch viewModel.profileType {
        case .me:
            toggleEditing()
        case .notMe:
            toggleRelationship()
        }
    }
    
    private func toggleEditing() {
        assert(viewModel.profileType.canEditProfile)
        switch viewModel.state {
        case .idle:
            let reset = viewModel
            Task { [weak self] in
                guard let s = self else { return }
                do {
                    try await s.refetchAllData()
                    s.viewModel = ProfileViewModelImmutable(profileType: s.viewModel.profileType, state: .editing)
                } catch let error {
                    s.displayError(error, andResetView: reset)
                }
            }
        case .editing:
            let reset = viewModel
            Task { [weak self] in
                guard let s = self else { return }
                do {
                    let updatedAccount = try await s.pushProfileEdits()
                    s.viewModel = ProfileViewModelImmutable(profileType: .me(updatedAccount), state: .idle)
                } catch let error {
                    s.displayError(error, andResetView: reset)
                }
            }
        case .updating, .pushingEdits:
            break
        }
    }
    
    private func displayError(_ error: Error, andResetView reset: ProfileViewModelImmutable?) {
        let alertController = UIAlertController(
            for: error,
            title: L10n.Common.Alerts.EditProfileFailure.title,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true)
        if let reset {
            viewModel = reset
        }
    }
    
    private func pushProfileEdits() async throws -> Mastodon.Entity.Account {
        guard viewModel.state == .editing else { throw ProfileViewError.invalidStateTransition }
        guard let editedHeaderDetails = profileHeaderViewController?.editedDetails, let editedAboutFields = profilePagingViewController?.viewModel?.profileAboutViewController.currentEditableFields else { throw ProfileViewError.attemptToPushInvalidProfileChanges }
        
        viewModel = ProfileViewModelImmutable(profileType: viewModel.profileType, state: .pushingEdits)
        
        // TODO: also check that there are actual changes?
        //  cancelEditing() <- if no actual changes
        let updatedAccount = try await pushProfileChanges(headerDetails: editedHeaderDetails, profileFields: editedAboutFields)
        return updatedAccount
    }
    
    private func cancelEditing() {
        viewModel = ProfileViewModelImmutable(profileType: viewModel.profileType, state: .idle)
    }
    
    private func toggleRelationship() {
        guard let relationship = viewModel.profileType.myRelationshipToDisplayedAccount else { return }
        let actionableRelationship = ActionableRelationship(relationship)
        let account = viewModel.profileType.accountToDisplay
        
        if let confirmationAlert = confirmationAlertForRelationshipToggle(onOtherAccount: viewModel.profileType.accountToDisplay, myCurrentRelationship: actionableRelationship) {
            self.sceneCoordinator?.present(scene: .alertController(alertController: confirmationAlert), transition: .alertController(animated: true))
        } else {
            doToggleRelationship(actionableRelationship, on: account)
        }
    }
    
    private func confirmationAlertForRelationshipToggle(onOtherAccount account: Mastodon.Entity.Account, myCurrentRelationship relationship: ActionableRelationship) -> UIAlertController? {
        
        let confirmationAlert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        confirmationAlert.title = confirmationTitle(relationship)
        
        let entityName: String
        switch relationship {
        case .followed:
            return nil
        case .blocked:
            entityName = viewModel.profileType.accountToDisplay.displayNameWithFallback
            
        case .domainBlocked:
            guard let domain = account.domain else { return nil }
            entityName = domain
            
        case .muted:
            entityName = account.displayNameWithFallback
        }
        confirmationAlert.message = confirmationMessage(relationship, entityName: entityName)

        let toggleAction = UIAlertAction(title: confirmationActionTitle(relationship, entityName: entityName), style: .default) { [weak self] _ in
            guard let s = self else { return }
            s.doToggleRelationship(relationship, on: account)
        }
        confirmationAlert.addAction(toggleAction)
        
        let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel)
        confirmationAlert.addAction(cancelAction)
        return confirmationAlert
    }
    
    private func confirmationTitle(_ actionableRelationship: ActionableRelationship) -> String {
        switch actionableRelationship {
        case .followed:
            return ""
        case .blocked:
            return L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.title
        case .domainBlocked:
            return L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockDomain.title
        case .muted:
            return L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.title
        }
    }
    
    private func confirmationMessage(_ relationship: ActionableRelationship, entityName: String) -> String {
        switch relationship {
        case .followed:
            return ""
        case .blocked:
            return L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.message(entityName)
        case .domainBlocked:
            return L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockDomain.message(entityName)
        case .muted:
            return L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.message(entityName)
        }
    }
    
    private func confirmationActionTitle(_ relationship: ActionableRelationship, entityName: String) -> String {
        switch relationship {
        case .followed:
            return ""
        case .blocked:
            return L10n.Common.Controls.Friendship.unblock
        case .domainBlocked:
            return L10n.Common.Controls.Actions.unblockDomain(entityName)
        case .muted:
            return L10n.Common.Controls.Friendship.unmute
        }
    }
    
    private func doToggleRelationship(_ actionableRelationship: ActionableRelationship, on account: Mastodon.Entity.Account) {
        
        let reset = viewModel
        viewModel = ProfileViewModelImmutable(profileType: viewModel.profileType, state: .updating)
        Task { [weak self] in
            guard let s = self else { return }
            do {
                let updatedRelationship: Mastodon.Entity.Relationship
                
                switch actionableRelationship {
                case .followed:
                    updatedRelationship = try await DataSourceFacade.responseToUserFollowAction(
                        dependency: s,
                        account: s.viewModel.profileType.accountToDisplay
                    )
                case .blocked:
                    updatedRelationship = try await DataSourceFacade.responseToUserBlockAction(
                        dependency: s,
                        account: s.viewModel.profileType.accountToDisplay
                    )
                case .domainBlocked:
                    _ = try await DataSourceFacade.responseToDomainBlockAction(dependency: s, account: account)
                    
                    guard let s1 = self, let fetchedRelationship = try await APIService.shared.relationship(forAccounts: [account], authenticationBox: s1.authenticationBox).value.first else { return }
                    updatedRelationship = fetchedRelationship
                case .muted:
                    updatedRelationship = try await DataSourceFacade.responseToUserMuteAction(dependency: s, account: s.viewModel.profileType.accountToDisplay)
                }
                guard let s2 = self else { return }
                let newType = ProfileType.notMe(me: s2.viewModel.profileType.myAccount, displayAccount: s2.viewModel.profileType.accountToDisplay, relationship: updatedRelationship)
                s2.viewModel = ProfileViewModelImmutable(profileType: newType, state: .idle)
            } catch let error {
                self?.displayError(error, andResetView: reset)
            }
        }
    }
    
    private func handleMetaPress(_ meta: Meta) {
        switch meta {
        case .url(_, _, let url, _):
            guard let url = URL(string: url) else { return }
            _ = self.sceneCoordinator?.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
        case .mention(_, _, let userInfo):
            guard let href = userInfo?["href"] as? String,
                  let url = URL(string: href) else { return }
            _ = self.sceneCoordinator?.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
        case .hashtag(_, let hashtag, _):
            let hashtagTimelineViewModel = HashtagTimelineViewModel(authenticationBox: authenticationBox, hashtag: hashtag)
            _ = self.sceneCoordinator?.present(scene: .hashtagTimeline(viewModel: hashtagTimelineViewModel), from: nil, transition: .show)
        case .email, .emoji:
            break
        }
    }
    
    @objc private func cancelEditingBarButtonItemPressed(_ sender: UIBarButtonItem) {
        cancelEditing()
    }
    
    @objc private func settingBarButtonItemPressed(_ sender: UIBarButtonItem) {
        guard let setting = SettingService.shared.currentSetting.value else { return }
        
        _ = self.sceneCoordinator?.present(scene: .settings(setting: setting), from: self, transition: .none)
    }
    
    @objc private func shareBarButtonItemPressed(_ sender: UIBarButtonItem) {
        let activityViewController = DataSourceFacade.createActivityViewController(
            dependency: self,
            account: viewModel.profileType.accountToDisplay
        )
        _ = self.sceneCoordinator?.present(
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
        let favoriteViewModel = FavoriteViewModel(authenticationBox: authenticationBox)
        _ = self.sceneCoordinator?.present(scene: .favorite(viewModel: favoriteViewModel), from: self, transition: .show)
    }
    
    @objc private func bookmarkBarButtonItemPressed(_ sender: UIBarButtonItem) {
        let bookmarkViewModel = BookmarkViewModel(authenticationBox: authenticationBox)
        _ = self.sceneCoordinator?.present(scene: .bookmark(viewModel: bookmarkViewModel), from: self, transition: .show)
    }
    
    @objc private func replyBarButtonItemPressed(_ sender: UIBarButtonItem) {
        let mention = "@" + viewModel.profileType.accountToDisplay.acct
        UITextChecker.learnWord(mention)
        let composeViewModel = ComposeViewModel(
            authenticationBox: authenticationBox,
            composeContext: .composeStatus(quoting: nil),
            destination: .topLevel,
            initialContent: mention
        )
        _ = self.sceneCoordinator?.present(scene: .compose(viewModel: composeViewModel), from: self, transition: .modal(animated: true, completion: nil))
    }
    
    @objc private func followedTagsItemPressed(_ sender: UIBarButtonItem) {
        let followedTagsViewModel = FollowedTagsViewModel(authenticationBox: authenticationBox)
        _ = self.sceneCoordinator?.present(scene: .followedTags(viewModel: followedTagsViewModel), from: self, transition: .show)
    }
}

// MARK: - ProfileAboutViewControllerDelegate
extension ProfileViewController: ProfileAboutViewControllerDelegate {
    // TODO: replace delegate with async stream
    func profileAboutViewController(
        _ viewController: ProfileAboutViewController,
        profileFieldCollectionViewCell: ProfileFieldCollectionViewCell,
        metaLabel: MetaLabel,
        didSelectMeta meta: Meta
    ) {
        handleMetaPress(meta)
    }
}

// MARK: - MastodonMenuDelegate
extension ProfileViewController: MastodonMenuDelegate {
    func menuAction(_ action: MastodonMenu.Action) {
        switch action {
        case .muteUser(_), .blockUser(_), .blockDomain(_), .hideReblogs(_), .reportUser(_), .shareUser(_), .openUserInBrowser(_), .copyProfileLink(_), .followUser(_):
            Task {
                try await DataSourceFacade.responseToMenuAction(
                    dependency: self,
                    action: action,
                    menuContext: DataSourceFacade.MenuContext(
                        author: viewModel.profileType.accountToDisplay,
                        statusViewModel: nil,
                        button: nil,
                        barButtonItem: self.moreMenuBarButtonItem
                    ))
            }
        case .translateStatus(_), .showOriginal, .bookmarkStatus(_), .shareStatus, .deleteStatus, .editStatus, .boostStatus(_), .favoriteStatus(_), .copyStatusLink, .openStatusInBrowser:
            break
        }
    }
}

// MARK: - ScrollViewContainer
extension ProfileViewController: ScrollViewContainer {
    var scrollView: UIScrollView {
        return tabBarPagerController.relayScrollView
    }
}

extension ProfileViewController {
    
    override var keyCommands: [UIKeyCommand]? {
        switch viewModel.state {
        case .idle:
            return pagerTabStripNavigateKeyCommands
        case .editing, .pushingEdits, .updating:
            return nil
        }
    }
    
}

// MARK: - PagerTabStripNavigateable
extension ProfileViewController: PagerTabStripNavigateable {
    
    var navigateablePageViewController: PagerTabStripViewController? {
        return profilePagingViewController
    }
    
    @objc func pagerTabStripNavigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        pagerTabStripNavigateKeyCommandHandler(sender)
    }
    
}

extension ProfileViewController: DataSourceProvider {
    var filterContext: MastodonSDK.Mastodon.Entity.FilterContext? {
        .none
    }
    
    func didToggleContentWarningDisplayStatus(status: MastodonSDK.MastodonStatus) {
        reloadTables()
    }
    
    func item(from source: DataSourceItem.Source) async -> DataSourceItem? {
        assertionFailure("Not required")
        return nil
    }
    
    func reloadTables() {
        profilePagingViewController?.reloadTables()
    }
    
    func update(contentStatus: MastodonStatus, intent: MastodonStatus.UpdateIntent) {
        updateViewModelsWithDataControllers(status: contentStatus, intent: intent)
    }
    
    func updateViewModelsWithDataControllers(status: MastodonStatus, intent: MastodonStatus.UpdateIntent) {
        
        (profilePagingViewController?.viewModel?.postUserTimelineViewController as? UserTimelineViewController)?.update(contentStatus: status, intent: intent)
        (profilePagingViewController?.viewModel?.repliesUserTimelineViewController as? UserTimelineViewController)?.update(contentStatus: status, intent: intent)
        (profilePagingViewController?.viewModel?.mediaUserTimelineViewController as? UserTimelineViewController)?.update(contentStatus: status, intent: intent)
    }
}

// MARK: - TabBarPagerDelegate
extension ProfileViewController: TabBarPagerDelegate {
    func tabBarMinimalHeight() -> CGFloat {
        return ProfileHeaderViewController.headerMinHeight
    }
    
    func resetPageContentOffset(_ tabBarPagerController: TabBarPagerController) {
        for viewController in profilePagingViewController?.viewModel?.viewControllers ?? [] {
            viewController.pageScrollView.contentOffset = .zero
        }
    }
    
    func tabBarPagerController(_ tabBarPagerController: TabBarPagerController, didScroll scrollView: UIScrollView) {
        // try to find some patterns:
        // print("""
        // -----
        // headerMinHeight: \(ProfileHeaderViewController.headerMinHeight)
        // scrollView.contentOffset.y: \(scrollView.contentOffset.y)
        // scrollView.contentSize.height: \(scrollView.contentSize.height)
        // scrollView.frame: \(scrollView.frame)
        // scrollView.adjustedContentInset.top: \(scrollView.adjustedContentInset.top)
        // scrollView.adjustedContentInset.bottom: \(scrollView.adjustedContentInset.bottom)
        // """
        // )
        
        guard let profileHeaderViewController = profileHeaderViewController else { return }
        
        // elastically banner
        
        // make banner top snap to window top
        // do not rely on the view frame becase the header frame is .zero during the initial call
        profileHeaderViewController.profileHeaderView.bannerImageViewTopLayoutConstraint.constant = min(0, scrollView.contentOffset.y)
        
        if profileHeaderViewController.profileHeaderView.frame != .zero {
            // make banner bottom not higher than navigation bar bottom
            let bannerContainerInWindow = profileHeaderViewController.profileHeaderView.convert(
                profileHeaderViewController.profileHeaderView.bannerContainerView.frame,
                to: nil
            )
            let bannerContainerBottomOffset = bannerContainerInWindow.origin.y + bannerContainerInWindow.height
            // print("bannerContainerBottomOffset: \(bannerContainerBottomOffset)")
            
            let height = profileHeaderViewController.view.frame.height - bannerContainerInWindow.height
            // make avatar hidden when scroll 0.5x avatar height
            let throttle = height != .zero ? 0.5 * ProfileHeaderView.avatarImageViewSize.height / height : 0
            let progress: CGFloat
            
            if bannerContainerBottomOffset < tabBarPagerController.containerScrollView.safeAreaInsets.top {
                let offset = bannerContainerBottomOffset - tabBarPagerController.containerScrollView.safeAreaInsets.top
                profileHeaderViewController.profileHeaderView.bannerImageViewBottomLayoutConstraint.constant = offset
                // the progress for header move from banner bottom to header bottom (from 0 to 1)
                progress = height != .zero ? abs(offset) / height : 0
            } else {
                profileHeaderViewController.profileHeaderView.bannerImageViewBottomLayoutConstraint.constant = 0
                progress = 0
            }
            
            // setup follows you mask
            // 1. set mask size
            profileHeaderViewController.profileHeaderView.followsYouMaskView.frame = profileHeaderViewController.profileHeaderView.followsYouBlurEffectView.bounds
            // 2. check follows you view overflow navigation bar or not
            let followsYouBlurEffectViewInWindow = profileHeaderViewController.profileHeaderView.convert(
                profileHeaderViewController.profileHeaderView.followsYouBlurEffectView.frame,
                to: nil
            )
            if followsYouBlurEffectViewInWindow.minY < tabBarPagerController.containerScrollView.safeAreaInsets.top {
                let offestY = tabBarPagerController.containerScrollView.safeAreaInsets.top - followsYouBlurEffectViewInWindow.minY
                let height = profileHeaderViewController.profileHeaderView.followsYouMaskView.frame.height
                profileHeaderViewController.profileHeaderView.followsYouMaskView.frame.origin.y = min(offestY, height)
            } else {
                profileHeaderViewController.profileHeaderView.followsYouMaskView.frame.origin.y = .zero
            }
            
            // setup titleView offset and fade avatar
            profileHeaderViewController.updateHeaderScrollProgress(progress, throttle: throttle)
            
            // setup buttonBar shadow
            profilePagingViewController?.updateButtonBarShadow(progress: progress)
        }
    }
    
}

// MARK: - TabBarPagerDataSource
extension ProfileViewController: TabBarPagerDataSource {
    func headerViewController() -> UIViewController & TabBarPagerHeader {
        return profileHeaderViewController!  // no good way around this force unwrap given the requirement that the return value be non-optional
    }
    
    func pageViewController() -> UIViewController & TabBarPageViewController {
        return profilePagingViewController!  // no good way around this force unwrap given the requirement that the return value be non-optional
    }
}

extension ProfileViewController {
    static func containerViewMargin(forHorizontalSizeClass sizeClass: UIUserInterfaceSizeClass) -> CGFloat {
        // TODO: this might be better gated on actual size than on sizeClass (we had previously treated the phone as always compact, for instance)
        switch sizeClass {
        case .compact:
            return 16
        case .regular, .unspecified:
            return 64
        @unknown default:
            return 16
        }
    }
}

extension TimelineListViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: XLPagerTabStrip.PagerTabStripViewController) -> XLPagerTabStrip.IndicatorInfo {
        return IndicatorInfo(title: type.tabTitle ?? "No Title")
    }
}
