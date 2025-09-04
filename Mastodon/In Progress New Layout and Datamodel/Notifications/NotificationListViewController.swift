// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Combine
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonSDK
import SwiftUI

class NotificationListViewController: UIHostingController<NotificationListView>
{
    fileprivate var viewModel: NotificationListViewModel
    private var picker = UISegmentedControl(items: [ ListType.everything.pickerLabel, ListType.mentions.pickerLabel ])

    init() {
        viewModel = NotificationListViewModel()
        let root = NotificationListView(viewModel: viewModel)
        super.init(rootView: root)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), style: .plain, target: self, action: #selector(showNotificationPolicySettings))

        viewModel.presentError = { [weak self] error in
            let alert = UIAlertController(
                title: "Error", message: error.localizedDescription,
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.sceneCoordinator?.rootViewController?.topMost?.present(
                alert, animated: true)
        }

        viewModel.navigateToScene = { [weak self] scene, transition in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.sceneCoordinator?.present(
                    scene: scene, from: self, transition: transition)
            }
        }
        
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.selectedSegmentIndex = 0
        navigationItem.titleView = picker
        NSLayoutConstraint.activate([
            picker.widthAnchor.constraint(greaterThanOrEqualToConstant: 287)
        ])
        picker.addTarget(self, action: #selector(pickerValueChanged(_:)), for: .valueChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError(
            "init(coder:) not implemented for NotificationListViewController")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewModel.checkCanGroupNotifications()
    }
    
    @objc private func pickerValueChanged(_ sender: UISegmentedControl) {
        viewModel.displayedNotifications = ListType(rawValue: sender.selectedSegmentIndex) ?? .everything
    }
    
    @objc private func showNotificationPolicySettings(_ sender: Any) {
        guard let policy = viewModel.filteredNotificationsViewModel.policy else { return }
        Task {
            let adminSettings: AdminNotificationFilterSettings? = await {
                guard let user = AuthenticationServiceProvider.shared.currentActiveUser.value, let role = user.cachedAccount?.role else { print("no role"); return nil }
                let permissions = role.rolePermissions()
                let hasAdminPermissions = permissions.contains(.administrator) || permissions.contains(.manageReports) || permissions.contains(.manageUsers)
                guard hasAdminPermissions else { print("no permissions"); return nil }
                if let existingPreferences = await BodegaPersistence.Notifications.currentPreferences(for: user.authentication) {
                    return existingPreferences
                } else {
                    return AdminNotificationFilterSettings(forReports: .accept, forSignups: .accept)
                }
            }()
            
            let policyViewModel = await NotificationPolicyViewModel(
                NotificationFilterSettings(
                    forNotFollowing: policy.forNotFollowing,
                    forNotFollowers: policy.forNotFollowers,
                    forNewAccounts: policy.forNewAccounts,
                    forPrivateMentions: policy.forPrivateMentions,
                    forLimitedAccounts: policy.forLimitedAccounts
                ),
                adminSettings: adminSettings
            )
            
            guard let policyViewController = self.sceneCoordinator?.present(scene: .notificationPolicy(viewModel: policyViewModel), transition: .formSheet(policyViewModel.adminFilterSettings != nil ? [.large()] : nil)) as? NotificationPolicyViewController else { return }
            
            policyViewController.delegate = self
        }
    }
}

extension NotificationListViewController: NotificationPolicyViewControllerDelegate {
    func policyUpdated(_ viewController: NotificationPolicyViewController, newPolicy: MastodonSDK.Mastodon.Entity.NotificationPolicy) {
        viewModel.updateFilteredNotificationsPolicy(newPolicy)
    }
}

private enum ListType: Int {
    case everything = 0
    case mentions = 1

    var pickerLabel: String {
        switch self {
        case .everything:
            L10n.Scene.Notification.Title.everything
        case .mentions:
            L10n.Scene.Notification.Title.mentions
        }
    }

    var feedKind: MastodonFeedKind {
        switch self {
        case .everything:
            return .notificationsAll
        case .mentions:
            return .notificationsMentionsOnly
        }
    }
}
extension ListType: Identifiable {
    var id: String {
        return pickerLabel
    }
}

struct NotificationListView: View {
    @ObservedObject private var viewModel: NotificationListViewModel
    @State private var scrollManager = ScrollManager()

    fileprivate init(viewModel: NotificationListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(viewModel.notificationItems, id: \.self) { item in // without explicit id, scrollTo(:) does not work
                        let isUnread = viewModel.isUnread(item)
                        rowView(item, isUnread: isUnread ?? false)
                            .onAppear {
                                didAppear(item)
                            }
                            .onDisappear {
                                didDisappear(item, wasUnread: isUnread ?? false)
                            }
                            .onTapGesture {
                                didTap(item: item)
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.refreshFeedFromTop()
                }
                .onChange(of: viewModel.notificationItems, initial: true) { oldValue, newValue in
                    if let newest = newValue.first?.rowViewModel, let stableScroll = scrollManager.stableScroll(withNewestOfAll: newest, newestRead: newValue.first(where: { !(viewModel.isUnread($0) ?? false) })?.rowViewModel)
                    {
                        doScrollRequest(stableScroll, currentItems: viewModel.notificationItems, proxy: proxy)
                    }
                }
                .onAppear() {
                    viewDidAppear()
                }
                .onDisappear() {
                    viewDidDisappear()
                }
                .accessibilityAction(named: L10n.Common.Controls.Actions.seeMore) {
                    viewModel.requestLoad(.newer)
                }
            }
        }
    }

    @ViewBuilder func rowView(_ notificationListItem: NotificationListItem, isUnread: Bool)
        -> some View
    {
        switch notificationListItem {
        case .bottomLoader:
            HStack {
                Spacer()
                ProgressView().progressViewStyle(.circular)
                Spacer()
            }
        case .filteredNotificationsInfo(_, let viewModel):
            if let viewModel {
                FilteredNotificationsRowView(contentWidth: 300)
                    .environment(viewModel)
                    .accessibilityElement(children: .combine)
                    .accessibilityAction {
                        didTap(item: notificationListItem)
                    }
            } else {
                Text("Some notifications have been filtered.")
            }
        case .notification:
            Text("obsolete item")
        case .groupedNotification(let viewModel):
            NotificationRowView(viewModel: viewModel)
                .padding(.vertical, 4)
                .listRowBackground(
                    backgroundView(isPrivate: viewModel.usePrivateBackground, isUnread: isUnread)
                )
#if DEBUG && false
                .overlay {
                    Text(viewModel.identifier.id)
                        .padding()
                        .background(Color.secondary.opacity(0.5))
                }
#endif
        }
    }
    
    
    @ViewBuilder func backgroundView(isPrivate: Bool, isUnread: Bool) -> some View {
        HStack(spacing: 0) {
            if isUnread && UserDefaults.standard.testUnreadMarkersForNotifications {
                Rectangle()
                    .fill(Asset.Colors.accent.swiftUIColor)
                    .frame(width: 8)
            }
            Rectangle()
                .fill(isPrivate ?  Asset.Colors.accent.swiftUIColor : .clear)
                .opacity(0.1)
        }
    }
    
    func didAppear(_ item: NotificationListItem) {
        switch item {
        case .groupedNotification(let viewModel):
            viewModel.prepareForDisplay()
        case .bottomLoader:
            loadMore()
        default:
            break
        }
        scrollManager.didAppear(item)
    }

    func didDisappear(_ item: NotificationListItem, wasUnread: Bool) {
        if wasUnread {
            viewModel.markAsRead(item)
        }
        scrollManager.didDisappear(item)
    }
    
    func viewDidAppear() {
        scrollManager.viewDidAppear()
        NotificationService.shared.clearNotificationCountForActiveUser()
        viewModel.requestLoad(.newer)
    }
    
    func viewDidDisappear() {
        scrollManager.viewDidDisappear()
        NotificationService.shared.clearNotificationCountForActiveUser()
        Task {
            await viewModel.commitToCache()
        }
    }
    
    func loadMore() {
        viewModel.requestLoad(.older)
    }

    func didTap(item: NotificationListItem) {
        switch item {
        case .filteredNotificationsInfo(_, let viewModel):
            guard let viewModel else { return }
            Task {
                viewModel.isPreparingToNavigate = true
                await navigateToFilteredNotifications()
                viewModel.isPreparingToNavigate = false
            }
        case .notification:
            return
        case .groupedNotification(let notificationViewModel):
            notificationViewModel.doPrimaryNavigation()
        default:
            return
        }
    }

    func navigateToFilteredNotifications() async {
        guard
            let authBox = AuthenticationServiceProvider.shared.currentActiveUser
                .value
        else { return }

        do {
            let notificationRequests = try await APIService.shared
                .notificationRequests(authenticationBox: authBox).value
            let requestsViewModel = NotificationRequestsViewModel(
                authenticationBox: authBox, requests: notificationRequests)

            viewModel.navigateToScene?(
                .notificationRequests(viewModel: requestsViewModel), .show)  // TODO: should be .modal(animated) on large screens?
        } catch {
            viewModel.presentError?(error)
        }
    }
}

fileprivate extension NotificationListView {
    func calculateStableScroll(newItems: [NotificationListItem], oldItems: [NotificationListItem]) -> ScrollManager.ScrollRequest? {
        
        let newestRead = oldItems.first(where: { item in
            if let isUnread = viewModel.isUnread(item) {
                return !isUnread
            } else {
                return false
            }
        })
        guard let newestRead else {
            return nil
        }
        
        func newItemWithID(_ id: String) -> NotificationListItem? {
            return newItems.first { item in
                return item.id == id
            }
        }
        
        if let newestOfAllModel = newItems.first?.rowViewModel, let newestReadModel = newestRead.rowViewModel, let stableScroll = scrollManager.stableScroll(withNewestOfAll: newestOfAllModel, newestRead: newestReadModel) {
            scrollManager.reset()
            return stableScroll
        } else {
            return nil
        }
    }
    
    func doScrollRequest(_ stableScroll: ScrollManager.ScrollRequest, currentItems: [NotificationListItem], proxy: ScrollViewProxy) {
        guard UserDefaults.standard.testUnreadMarkersForNotifications else { return }
        switch stableScroll {
        case .middle(let id):
            if let scrollItem = currentItems.first(where: { $0.id == id }) {
                proxy.scrollTo(scrollItem, anchor: .center)
            }
        case .top(let id):
            if let anchorItem = currentItems.first(where: { $0.id == id }), let anchorIndex = currentItems.firstIndex(of: anchorItem) {
                if anchorIndex > 0 {
                    let firstUnreadItem = currentItems[anchorIndex - 1]
                    proxy.scrollTo(firstUnreadItem)
                } else {
                    proxy.scrollTo(anchorItem, anchor: .top)
                }
            }
        }
    }
}

@MainActor
private class NotificationListViewModel: ObservableObject {

    var displayedNotifications: ListType = .everything {
        didSet {
            Task { [weak self] in
                guard let self else { return }
                await self.groupedFeedLoader?.commitToCache()
                await self.ungroupedFeedLoader?.commitToCache()
                self.groupedFeedLoader = nil
                self.ungroupedFeedLoader = nil
                self.createNewFeedLoader()
            }
        }
    }
    @Published var notificationItems = [NotificationListItem]()
    
    private let timestampUpdater = TimestampUpdater.timestamper(withInterval: 30)
    
    private var firstUnreadItem: NotificationListItem? {
        guard let marker =  groupedFeedLoader?.lastReadMarker ?? ungroupedFeedLoader?.lastReadMarker else { return nil }
        let firstUnread = notificationItems.reversed().first( where: { item in
            switch item {
            case .groupedNotification(let itemViewModel):
                if let itemNewestID =  itemViewModel.notification.newestID {
                    return itemNewestID > marker.lastReadID
                } else {
                    return false
                }
            default:
                return false
            }
        })
        return firstUnread
    }
    
    var filteredNotificationsViewModel =
        FilteredNotificationsRowView.ViewModel(policy: nil)
    private var notificationPolicyBannerRow: [NotificationListItem] {
        if filteredNotificationsViewModel.shouldShow {
            return [
                NotificationListItem.filteredNotificationsInfo(
                    nil, filteredNotificationsViewModel)
            ]
        } else {
            return []
        }
    }

    private var feedSubscription: AnyCancellable?
    private var errorSubscription: AnyCancellable?
    
    private var groupedFeedUnavailable = false {
        didSet {
            createNewFeedLoader()
        }
    }
    
    private var groupedFeedLoader: GroupedNotificationsFeedLoader?
    private var ungroupedFeedLoader: UngroupedNotificationsFeedLoader?
    
    fileprivate var navigateToScene:
        ((SceneCoordinator.Scene, SceneCoordinator.Transition) -> Void)?
    {
        didSet {
            createNewFeedLoader()
        }
    }
    fileprivate var presentError: ((Error) -> Void)? {
        didSet {
            createNewFeedLoader()
        }
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(notificationFilteringPolicyDidChange), name: .notificationFilteringChanged, object: nil)
    }
    
    @objc func notificationFilteringPolicyDidChange(_ notification: Notification) {
        fetchFilteredNotificationsPolicy()
    }

    private func fetchFilteredNotificationsPolicy() {
        guard presentError != nil && navigateToScene != nil else { return }
        guard
            let authBox = AuthenticationServiceProvider.shared.currentActiveUser
                .value
        else { return }
        Task {
            let policy = try? await APIService.shared.notificationPolicy(
                authenticationBox: authBox)
            updateFilteredNotificationsPolicy(policy?.value)
        }
    }

    func updateFilteredNotificationsPolicy(
        _ policy: Mastodon.Entity.NotificationPolicy?
    ) {

        filteredNotificationsViewModel.policy = policy

        let withoutFilteredRow = notificationItems.filter {
            !$0.isFilteredNotificationsRow
        }

        notificationItems =
            notificationPolicyBannerRow
            + withoutFilteredRow
        
        groupedFeedLoader?.requestLoad(MastodonFeedLoaderRequest.reload)
        ungroupedFeedLoader?.requestLoad(MastodonFeedLoaderRequest.reload)
    }
    
    func isUnread(_ item: NotificationListItem) -> Bool? {
        switch item {
        case .bottomLoader, .filteredNotificationsInfo:
            return nil
        case .groupedNotification(let viewModel):
            if let id = viewModel.notification.newestID {
                return groupedFeedLoader?.isUnread(id) ?? ungroupedFeedLoader?.isUnread(id) ?? false
            } else {
                return false
            }
        case .notification:
            assert(false)
            return nil
        }
    }
    
    func markAsRead(_ item: NotificationListItem) {
        switch item {
        case .bottomLoader, .filteredNotificationsInfo:
            break
        case .groupedNotification(let viewModel):
            if let id = viewModel.notification.newestID {
                groupedFeedLoader?.markAsRead(id)
                ungroupedFeedLoader?.markAsRead(id)
            }
        case .notification:
            assert(false)
            break
        }
    }
    
    func checkCanGroupNotifications() {
        guard let currentInstance = AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication.instanceConfiguration else {
            presentError?(APIService.APIError.implicit(.authenticationMissing))
            return
        }
        if currentInstance.canGroupNotifications, groupedFeedLoader == nil {
            ungroupedFeedLoader = nil
            createNewFeedLoader()
        }
    }

    private func createNewFeedLoader() {
        guard let navigateToScene, let presentError else { return }
        guard let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication else { return }
        
        fetchFilteredNotificationsPolicy()
        
        let useGrouped = {
            guard !groupedFeedUnavailable else { return false }
            switch displayedNotifications.feedKind {
            case .home:
                assertionFailure("nonsensical")
                groupedFeedUnavailable = true
                return false
            case .notificationsAll, .notificationsMentionsOnly:
                if let currentInstance = authBox.instanceConfiguration {
                    return currentInstance.canGroupNotifications
                } else {
                    //assertionFailure("no instance configuration") // This situation resolves quickly, but it would be nice to avoid it altogether. See Github issue #1432
                    return false
                }
            case .notificationsWithAccount:
                groupedFeedUnavailable = true
                return false
            }
        }()
        
        func notificationListItem(fromInfo info: GroupedNotificationInfo) -> NotificationListItem {
            let rowViewModel = NotificationRowViewModel(info, timestamper: self.timestampUpdater, myAccountID: authBox.userID, myAccountDomain: authBox.domain, navigateToScene: navigateToScene, presentError: presentError)
            return NotificationListItem.groupedNotification(rowViewModel)
        }
        
        if useGrouped {
            guard groupedFeedLoader == nil else { return }
            ungroupedFeedLoader = nil
            groupedFeedLoader = GroupedNotificationsFeedLoader(displayedNotifications.feedKind, forUser: authBox.userIdentifier())
            feedSubscription = groupedFeedLoader!.$records
                .receive(on: DispatchQueue.main)
                .sink { [weak self] records in
                    guard let self else { return }
                    var updatedItems = records.allRecords.map {
                        notificationListItem(fromInfo: $0)
                    }
                    if !records.allRecords.isEmpty && records.canLoadOlder {
                        updatedItems.append(.bottomLoader)
                    }
                    updatedItems = self.notificationPolicyBannerRow + updatedItems
                    self.notificationItems = updatedItems
                }
            errorSubscription = groupedFeedLoader!.$currentError
                .receive(on: DispatchQueue.main)
                .sink { [weak self] error in
                    if error?.isServiceNotAvailable == true {
                        self?.groupedFeedUnavailable = true
                    }
                }
            groupedFeedLoader!.doFirstLoad()
        } else {
            guard ungroupedFeedLoader == nil else { return }
            groupedFeedLoader = nil
            errorSubscription?.cancel()
            errorSubscription = nil
            ungroupedFeedLoader = UngroupedNotificationsFeedLoader(displayedNotifications.feedKind, forUser: authBox.userIdentifier())
            feedSubscription = ungroupedFeedLoader!.$records
                .receive(on: DispatchQueue.main)
                .sink { [weak self] records in
                    guard let self else { return }
                    var updatedItems = records.allRecords.map {
                        notificationListItem(fromInfo: $0)
                    }
                    if !records.allRecords.isEmpty && records.canLoadOlder {
                        updatedItems.append(.bottomLoader)
                    }
                    updatedItems = self.notificationPolicyBannerRow + updatedItems
                    self.notificationItems = updatedItems
                }
            ungroupedFeedLoader!.doFirstLoad()
        }
    }

    public func refreshFeedFromTop() async {
        if let feedLoader = groupedFeedLoader {
            if feedLoader.permissionToLoadImmediately {
                await feedLoader.loadImmediately(.newer)
            }
        } else if let feedLoader = ungroupedFeedLoader {
            if feedLoader.permissionToLoadImmediately {
                await feedLoader.loadImmediately(.newer)
            }
        }
    }
    
    public func requestLoad(_ loadRequest: MastodonFeedLoaderRequest) {
        groupedFeedLoader?.requestLoad(loadRequest)
        ungroupedFeedLoader?.requestLoad(loadRequest)
    }
    
    public func commitToCache() async {
        await groupedFeedLoader?.commitToCache()
        await ungroupedFeedLoader?.commitToCache()
    }
}

extension NotificationRowViewModel.NotificationNavigation {
    var a11yTitle: String? {
        switch self {
        case .link(let description, _):
            return description
        case .myFollowers:
            return L10n.Scene.Profile.Dashboard.myFollowers // TODO: improve string
        case .profile(let account):
            return  L10n.Common.Controls.Status.MetaEntity.mention(account.displayNameWithFallback)
        }
    }
}

fileprivate class ScrollManager {
    
    enum ScrollRequest {
        case middle(Mastodon.Entity.NotificationGroup.ID)
        case top(Mastodon.Entity.NotificationGroup.ID)
    }
    
    public var isAppeared: Bool = false
    
    private var visibleItems = Set<NotificationRowViewModel>()
    
    private var newestVisibleItem: NotificationRowViewModel? {
        var newest: NotificationRowViewModel? = nil
        for item in visibleItems {
            if let thisNewestID = item.notification.newestID {
                if let currentNewestID = newest?.notification.newestID {
                    if currentNewestID < thisNewestID {
                        newest = item
                    }
                } else {
                    newest = item
                    continue
                }
            }
        }
        return newest
    }
    
    
    
    func stableScroll(withNewestOfAll newestOfAll: NotificationRowViewModel, newestRead: NotificationRowViewModel?) -> ScrollRequest? {
        guard let newestVisibleItem else {
            if let newestRead {
                return .middle(newestRead.id)
            } else {
                return nil
            }
        }
       
        if let newestRead, newestRead.matchesIdentifier(newestVisibleItem) {
            // The most recent notification that has already been read is also the most recent visible item.
            // We ask to scroll it down to the middle to reveal newer, unread items.
            return .middle(newestRead.id)
        } else {
            let topID = newestVisibleItem.id
            return .top(topID)
        }
    }
    
    func reset() {
        visibleItems.removeAll()
    }
    
    func viewDidAppear() {
        assert(!isAppeared)
        isAppeared = true
    }
    
    func viewDidDisappear() {
        assert(isAppeared)
        isAppeared = false
    }
    
    func didAppear(_ item: NotificationListItem) {
        switch item {
        case .bottomLoader, .filteredNotificationsInfo, .notification:
            break
        case .groupedNotification(let viewModel):
            visibleItems.insert(viewModel)
        }
    }
    
    func didDisappear(_ item: NotificationListItem) {
        switch item {
        case .bottomLoader, .filteredNotificationsInfo, .notification:
            break
        case .groupedNotification(let viewModel):
            visibleItems.remove(viewModel)
        }
    }
}

extension NotificationRowViewModel {
    func matchesIdentifier(_ other: NotificationRowViewModel?) -> Bool {
        guard let other else { return false }
        return notification.identifier.id == other.notification.identifier.id
    }
}

extension NotificationRowViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(notification.identifier)
    }
}

extension Error {
    var isServiceNotAvailable: Bool {
        if let error = self as? Mastodon.API.Error {
            if [.badRequest, .unauthorized, .forbidden, .notFound, .methodNotAllowed, .gone].contains(error.httpResponseStatus) {
                return true
            }
        }
        return false
    }
}

class TimestampUpdater: ObservableObject {
    @Published var timestamp: Date = .now
    private var timer: Timer?
    
    private init(_ interval: TimeInterval) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [weak self] _ in
            Task { @MainActor in
                self?.timestamp = .now
            }
        })
    }
    
    private static var instances = [TimeInterval : TimestampUpdater]()

    public static func timestamper(withInterval interval: TimeInterval) -> TimestampUpdater {
        if let existing = instances[interval] {
            return existing
        } else {
            let fresh = TimestampUpdater(interval)
            instances[interval] = fresh
            return fresh
        }
    }
}
