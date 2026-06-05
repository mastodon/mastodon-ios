// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import Combine
import MastodonSDK
import MastodonCore
import PhotosUI
import SwiftUI
import MastodonLocalization

@MainActor
@Observable class ProfileViewModel {
    let uuid = UUID() // helpful for debugging
    let relationshipViewModel = RelationshipViewModel()
    
    let editingViewModel = {
        ProfileEditingViewModel()
    }()
    
    var featuredHashtagsModel = FeaturedHashtagsModel()
    
    var editingStatus: EditingStatus = .cannotEdit
    var contentDisplayStatus: ProfileContentStatus = .showAlways
    
    struct HandleDetails {
        let username: String
        let domain: String
        let isMyDomain: Bool
    }
    var navigator: MastodonNavigationRouter?
    var account: MastodonAccount?
    var relationship: MastodonAccount.Relationship?
    var familiarFollowersViewModel: TimelineListViewModel?
    var pagesToShow: [ProfilePage] = []
    var postsViewModel: TimelineListViewModel? {
        didSet {
            Task {
                switch await postsViewModel?.timeline {
                case .userPosts(_, let queryFilter):
                    activityFilter = queryFilter
                default:
                    activityFilter = nil
                }
            }
        }
    }
    private var activityFilter: TimelineQueryFilter?
    
    var mediaViewModel: TimelineListViewModel?
    {
        didSet {
            Task {
                switch await mediaViewModel?.timeline {
                case .userPosts(_, let queryFilter):
                    mediaFilter = queryFilter
                default:
                    mediaFilter = nil
                }
            }
        }
    }
    private var mediaFilter: TimelineQueryFilter?
    var mediaViewAsyncRefresh: AsyncRefreshViewModel?
    
    var featuredItemsViewModel: TimelineListViewModel?
    var featuredItemsAsyncRefresh: AsyncRefreshViewModel?
    var selectedPage: ProfilePage = .activity
    var focusedCustomField: Mastodon.Entity.Field?
    var handleDetails: HandleDetails?
    
    var navigationButtons: [UIBarButtonItem] {
        guard account != nil, let relationship else { return [] }
        switch relationship {
        case .isMe:
            let settings = UIBarButtonItem(image: .init(systemName: "gearshape"), style: .plain, target: self, action: nil)
            let hashtags = UIBarButtonItem(image: .init(systemName: "number"), style: .plain, target: self, action: nil)
            let bookmarks = UIBarButtonItem(image: .init(systemName: "bookmark"), style: .plain, target: self, action: nil)
            let favourites = UIBarButtonItem(image: .init(systemName: "star"), style: .plain, target: self, action: nil)
            let share = UIBarButtonItem(image: .init(systemName: "square.and.arrow.up"), style: .plain, target: self, action: nil)
            return [hashtags, bookmarks, favourites, share, settings]
        case .isNotMe:
            let menu = UIBarButtonItem(image: .init(systemName: "ellipsis.circle"), style: .plain, target: self, action: nil)
            let reply = UIBarButtonItem(image: .init(systemName: "arrow.turn.up.left"), style: .plain, target: self, action: nil)
            return [menu, reply]
        }
    }
    
    private var updateSubscription: AnyCancellable?
    init() {
        self.updateSubscription = FeedCoordinator.shared.$mostRecentUpdate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self, let update else { return }
                self.incorporateUpdate(update)
            }
    }
    
    public func set(account: MastodonAccount, relationship: MastodonAccount.Relationship, navigator: MastodonNavigationRouter) {
        self.navigator = navigator
        self.account = account
        self.contentDisplayStatus = {
            if account.displayInfo.isSuspended {
                return .hideAlways
            } else if account.displayInfo.isLimitedByModerators {
                return .hideUntilRequestedToShow
            } else {
                return .showAlways
            }
        }()
        self.editingViewModel.setAccount(account, textContentDidChange: { self.checkForEditingChanges() } )
        self.relationship = relationship
        self.postsViewModel = TimelineListViewModel(timeline: .userPosts(userID: account.id, queryFilter: .init(.userPosts(featuredHashtagsModel))), navigator: navigator, asyncRefreshViewModel: AsyncRefreshViewModel())
        
        Task {
            do {
                try await featuredHashtagsModel.fetchFeaturedTags(account: account)
                editingViewModel.updateFeaturedHashtags(featuredHashtagsModel.featuredHashtags)
            } catch {
                navigator.didReceiveError(error)
            }
        }
        
        if account.metadata.showsMediaTab {
            if mediaViewModel == nil {
                mediaViewAsyncRefresh = AsyncRefreshViewModel()
                let mediaQueryFilter = TimelineQueryFilter(.mediaOnly)
                mediaQueryFilter.excludeReplies = !account.metadata.mediaTabIncludesReplies
                self.mediaViewModel = TimelineListViewModel(timeline: .userPosts(userID: account.id, queryFilter: mediaQueryFilter), navigator: navigator, asyncRefreshViewModel: mediaViewAsyncRefresh!)
            } else {
                self.updateMediaFilter()
            }
        } else {
            self.mediaViewModel = nil
        }
        
        if account.metadata.showsFeaturedTab {
            if self.featuredItemsViewModel == nil {
                featuredItemsAsyncRefresh = AsyncRefreshViewModel()
                self.featuredItemsViewModel = TimelineListViewModel(timeline: .featuredItems(userID: account.id), navigator: navigator, asyncRefreshViewModel: featuredItemsAsyncRefresh!)
            }
        } else {
            self.featuredItemsViewModel = nil
        }
        
        self.relationshipViewModel.prepareForDisplay(relationship: relationship, theirAccountIsLocked: account.locked)
        
        self.relationshipViewModel.actionHandler = self.postsViewModel
        
        switch relationship {
        case .isMe:
            self.editingStatus = .notEditing
        case .isNotMe:
            self.editingStatus = .cannotEdit
        }
        
        pagesToShow = pagesToShow(forAccount: account)
        
        Task {
            let handle = account.handle
            let handleComponents = handle.split(separator: "@").map { String($0) }
            if handleComponents.count > 1 {
                // server is included
                self.handleDetails = .init(username: handleComponents.first ?? "", domain: handleComponents.last ?? "", isMyDomain: false)
            } else {
                // this account is on my server
                if let myDomain = AuthenticationServiceProvider.shared.currentActiveUser.value?.domain {
                    self.handleDetails = .init(username: handleComponents.first ?? "", domain: myDomain, isMyDomain: true)
                }
            }
        }
    }
    
    public func resetEditingViewModel() {
        guard let account else { return }
        editingViewModel.setAccount(account, textContentDidChange: { self.checkForEditingChanges() })
    }
    
    public func updateMediaFilter() {
        guard let mediaFilter, let account else { return }
        let accountIsExcludingRepliesInMediaTab = !account.metadata.mediaTabIncludesReplies
        guard mediaFilter.excludeReplies != accountIsExcludingRepliesInMediaTab else { return }
        mediaFilter.excludeReplies = accountIsExcludingRepliesInMediaTab
        Task {
            await mediaViewModel?.forceReload(.mediaFilterUpdated)
        }
    }
    
    public func checkForEditingChanges() {
        switch editingStatus {
        case .cannotEdit, .notEditing:
            return
        case .editing:
            break
        case .pushingChanges(let success):
            guard success != nil else { return }
            break
        }
        let editingViewModelHasChanges = editingViewModel.checkForChanges()
        editingStatus = .editing(hasChanges: editingViewModelHasChanges)
    }
}

extension Mastodon.Entity.V2.Instance.Configuration.AccountsLimits {
    static var defaultMaxDisplayNameLength: Int = 30
    static var defaultMaxBioLength: Int = 500
    static var defaultMaxFeaturedTagCount: Int = 10
    static var defaultMaxPinnedStatusCount: Int = 5
    static var defaultMaxProfileCustomFieldsCount: Int = 4
    static var defaultMaxProfileFieldNameLength: Int = 255
    static var defaultMaxProfileFieldValueLength: Int = 255
}

@MainActor
@Observable
class ProfileEditingViewModel {
    typealias AccountsLimits = Mastodon.Entity.V2.Instance.Configuration.AccountsLimits
    var editingStatus: EditingStatus?
    var showVerifiedLinkTip = true
    var showTabDisplayPreferences = false
    var instanceLimits: AccountsLimits?
    
    let displayNameFieldEditingViewModel: MetaTextInputFieldViewModel
    let bioFieldEditingViewModel: MetaTextInputFieldViewModel
    
    var fieldEditingState: ProfileEditingViewModel.FieldEditingState?
    var isReorderingCustomFields: Bool = false
    
    var selectedBannerImage: Binding<[PhotosPickerItem]>
    var bannerImagePhotosPickerItem: PhotosPickerItem?
    var confirmedBannerImage: UIImage?
    
    var selectedAvatar: Binding<[PhotosPickerItem]>
    var avatarPhotosPickerItem: PhotosPickerItem?
    var avatarImageToCrop: UIImage?
    var avatarConfirmedCroppedImage: UIImage?
    
    var showCroppingView: Binding<Bool>
    var presentingAlert: ProfileEditingAlert?
    
    private(set) var mediaTabVisibilitySetting: MediaTabVisibilitySetting = .showMediaTab
    private(set) var mediaTabRepliesSetting: MediaTabRepliesSetting = .showDirectPostsOnly
    private(set) var featuredTabVisibilitySetting: FeaturedTabVisibilitySetting = .showFeaturedTab
    
    var customFields: [Mastodon.Entity.Field]? = nil
    var reorderingCustomFields: [Mastodon.Entity.Field] = []
    var emojis: [Mastodon.Entity.Emoji] = []
    
    var originalFeaturedTags: [Mastodon.Entity.FeaturedTag] = []
    var editedFeaturedTags: [Mastodon.Entity.FeaturedTag] = []
    
    var isAutomatedAccount: Bool = false
    
    private(set) var initialInfo: MastodonAccount? = nil
    
    init() {
        displayNameFieldEditingViewModel = MetaTextInputFieldViewModel(stringContent: "", placeholder: "", characterLimit: .init(initialMessage: nil, softLimit: AccountsLimits.defaultMaxDisplayNameLength, hardLimit: nil /*will be set when the instance is known*/), autocompleteMastodonItems: false)
        bioFieldEditingViewModel = MetaTextInputFieldViewModel(stringContent: "", placeholder: L10nLookup.Scene.EditProfile.SubpageTitle.bioPlaceholder, characterLimit: .init(initialMessage: nil, softLimit: 220, hardLimit: nil /*will be set when the instance is known*/), autocompleteMastodonItems: true)
        
        selectedBannerImage = Binding<[PhotosPickerItem]>(get: {[]}, set: {_ in})
        selectedAvatar = Binding<[PhotosPickerItem]>(get: {[]}, set: {_ in})
        showCroppingView = Binding<Bool>(get: {false}, set: {_ in})
        
        showCroppingView = Binding<Bool>(
            get: { return self.avatarImageToCrop != nil },
            set: { newValue in }
        )
        
        selectedBannerImage = Binding<[PhotosPickerItem]>(
            get: { [self.bannerImagePhotosPickerItem].compactMap { $0 } },
            set: { newValue in
                self.bannerImagePhotosPickerItem = newValue.first
                if let item = self.bannerImagePhotosPickerItem {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            self.confirmedBannerImage = image
                        } else {
                        }
                    }
                }
            }
        )
        
        selectedAvatar = Binding<[PhotosPickerItem]>(
            get: { [self.avatarPhotosPickerItem].compactMap { $0 } },
            set: { newValue in
                self.avatarPhotosPickerItem = newValue.first
                if let item = self.avatarPhotosPickerItem {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            self.avatarImageToCrop = image
                        } else {
                        }
                    }
                }
            }
        )
    }
    
    fileprivate func checkForChanges() -> Bool {
        let bannerImageChanged = confirmedBannerImage != nil
        let avatarImageChanged = avatarConfirmedCroppedImage != nil
        let displayNameChanged = displayNameFieldEditingViewModel.stringContent != displayNameFieldEditingViewModel.originalStringContent
        let bioChanged = bioFieldEditingViewModel.stringContent != bioFieldEditingViewModel.originalStringContent
        let customFieldsChanged = {
            if isReorderingCustomFields {
                return reorderingCustomFields != customFields
            } else {
                return customFields != initialInfo?.metadata.customFieldsForEdit
            }
        }()
        let customFieldEditChanged = {
            guard let fieldEditingState else { return false }
            let labelHasChanges = fieldEditingState.labelEditingModel.stringContent != fieldEditingState.labelEditingModel.originalStringContent
            let valueHasChanges = fieldEditingState.valueEditingModel.stringContent != fieldEditingState.labelEditingModel.originalStringContent
            return labelHasChanges || valueHasChanges
        }()
        
        let hasChanges = bannerImageChanged || avatarImageChanged || displayNameChanged || bioChanged || customFieldsChanged || customFieldEditChanged
        
#if DEBUG
        if hasChanges {
            print("HAS CHANGES - \(bannerImageChanged ? "banner " : "")\(avatarImageChanged ? "avatar " : "")\(displayNameChanged ? "displayName was \(displayNameFieldEditingViewModel.originalStringContent) is now \(displayNameFieldEditingViewModel.stringContent) " : "")\(bioChanged ? "bio was \(bioFieldEditingViewModel.originalStringContent) is now \(bioFieldEditingViewModel.stringContent)" : "")\(customFieldsChanged ? "customFields " : "")\(customFieldEditChanged ? "customFieldEdit " : "")")
        } else {
            print("NO CHANGES")
        }
#endif
        
        switch editingStatus {
        case .cannotEdit, .notEditing:
            assertionFailure("did not expect to check for hasChanges while in \(String(describing: editingStatus)) state")
            break
        case .none:
            break
        case .editing(let oldHasChanges):
            guard hasChanges != oldHasChanges else { return hasChanges }
        case .pushingChanges(let success):
            guard success != nil else { return false }
        }
       
        withAnimation { editingStatus = .editing(hasChanges: hasChanges) }
        
        return hasChanges
    }
    
    fileprivate func setAccount(_ account: MastodonAccount, textContentDidChange: @escaping ()->()) {
        initialInfo = account
        updateAccountTextFields(account: account)
        updateCustomFields(account: account)
        updateMetaData(account: account)
        if customFields?.first(where: { $0.verifiedAt != nil }) != nil {
            showVerifiedLinkTip = false
        }
        avatarConfirmedCroppedImage = nil
        avatarPhotosPickerItem = nil
        avatarImageToCrop = nil
        confirmedBannerImage = nil
        bannerImagePhotosPickerItem = nil
        presentingAlert = nil
        
        let instanceConfig = AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication.instanceConfiguration
        showTabDisplayPreferences = instanceConfig?.isAvailable(.profileSettings) ?? false
        instanceLimits = instanceConfig?.instanceConfigLimitingProperties?.accounts
        
        displayNameFieldEditingViewModel.setHardLimit(instanceLimits?.maxDisplayNameLength)
        bioFieldEditingViewModel.setHardLimit(instanceLimits?.maxBioLength ?? AccountsLimits.defaultMaxBioLength)
        
        displayNameFieldEditingViewModel.contentDidChange = { withAnimation { textContentDidChange() } }
        bioFieldEditingViewModel.contentDidChange = { withAnimation { textContentDidChange() } }
    }
    
    func updateFeaturedHashtags(_ featuredTags: [Mastodon.Entity.FeaturedTag]) {
        originalFeaturedTags = featuredTags
        editedFeaturedTags = featuredTags
    }
    
    func updateAccountTextFields(account: MastodonAccount) {
        let displayNameContent = account.displayInfo.displayName
        displayNameFieldEditingViewModel.updateStringContent(displayNameContent, resetHasChanges: true)
        
        let bioContent = normalize(htmlString: account.bioForEdit)
        bioFieldEditingViewModel.updateStringContent(bioContent ?? "", resetHasChanges: true)
    }
    
    func updateCustomFields(account: MastodonAccount) {
        customFields = account.metadata.customFieldsForEdit
        reorderingCustomFields = customFields ?? []
        emojis = account._legacyEntity.emojis
    }
    
    func updateMetaData(account: MastodonAccount) {
        mediaTabVisibilitySetting = account.metadata.showsMediaTab ? .showMediaTab : .hideMediaTab
        mediaTabRepliesSetting = account.metadata.mediaTabIncludesReplies ? .includeMyRepliesToOthers : .showDirectPostsOnly
        featuredTabVisibilitySetting = account.metadata.showsFeaturedTab ? .showFeaturedTab : .hideFeaturedTab
        isAutomatedAccount = account.metadata.isBot
    }
    
    func beginEditingField(_ fieldType: ProfileEditingViewModel.FieldEditType, profileViewModel: ProfileViewModel, navigator: MastodonNavigationRouter) {
        switch fieldType {
        case .create:
            fieldEditingState = .init(editingField: fieldType,
                                      labelEditingModel: MetaTextInputFieldViewModel(stringContent: "", placeholder: L10nLookup.Scene.EditProfile.CustomFields.labelPlaceholder, characterLimit: .init(initialMessage: "", softLimit: 25, hardLimit: instanceLimits?.maxProfileFieldNameLength ?? AccountsLimits.defaultMaxProfileFieldNameLength), autocompleteMastodonItems: false),
                                      valueEditingModel: MetaTextInputFieldViewModel(stringContent: "", placeholder: L10nLookup.Scene.EditProfile.CustomFields.valuePlaceholder, characterLimit: .init(initialMessage: nil, softLimit: 25, hardLimit: instanceLimits?.maxProfileFieldValueLength ?? AccountsLimits.defaultMaxProfileFieldValueLength), autocompleteMastodonItems: true))
        case .edit(let field):
            fieldEditingState = .init(editingField: fieldType,
                                      labelEditingModel: MetaTextInputFieldViewModel(stringContent: field.name, placeholder: L10nLookup.Scene.EditProfile.CustomFields.labelPlaceholder, characterLimit: .init(initialMessage: "", softLimit: 25, hardLimit: instanceLimits?.maxProfileFieldNameLength ?? AccountsLimits.defaultMaxProfileFieldNameLength), autocompleteMastodonItems: false),
                                      valueEditingModel: MetaTextInputFieldViewModel(stringContent: field.value, placeholder: L10nLookup.Scene.EditProfile.CustomFields.valuePlaceholder, characterLimit: .init(initialMessage: nil, softLimit: 25, hardLimit: instanceLimits?.maxProfileFieldValueLength ?? AccountsLimits.defaultMaxProfileFieldValueLength), autocompleteMastodonItems: true))
        }
        navigator.presentModal(.editProfileNavigation(destination: .editCustomField(profileViewModel: profileViewModel)))
    }
    
    func beginReorderingFields(profileViewModel: ProfileViewModel, navigator: MastodonNavigationRouter) {
        isReorderingCustomFields = true
        reorderingCustomFields = customFields ?? []
        navigator.presentModal(.editProfileNavigation(destination: .reorderCustomFields(profileViewModel: profileViewModel)))
    }
    
    func deleteCurrentEditingField() {
        guard let fieldEditingState else { return }
        switch fieldEditingState.editingField {
        case .create:
            return
        case .edit(let field):
            self.fieldEditingState = nil
            guard let index = customFields?.firstIndex(of: field) else { return }
            customFields?.remove(at: index)
        }
    }
    
    fileprivate func commitEditingField() {
        guard let fieldEditingState else { return }
        let labelText = fieldEditingState.labelEditingModel.stringContent
        let valueText = fieldEditingState.valueEditingModel.stringContent
        guard !labelText.isEmpty, !valueText.isEmpty else { return }
        
        let newField = Mastodon.Entity.Field(name: labelText, value: valueText)
        
        switch fieldEditingState.editingField {
        case .create:
            customFields?.append(newField)
        case .edit(let field):
            if let replaceIndex = customFields?.firstIndex(of: field) {
                customFields?[replaceIndex] = newField
            } else {
                customFields?.append(newField)
            }
        }
        self.fieldEditingState = nil
    }
    
    fileprivate func commitCustomFieldsReordering() {
        guard isReorderingCustomFields else { return }
        customFields = reorderingCustomFields
        isReorderingCustomFields = false
    }
    
    func requestDeleteCustomField(_ field: Mastodon.Entity.Field) {
        presentingAlert = .deleteCustomField(field)
    }
    
    fileprivate func confirmDeleteCustomField() {
        let deletingField: Mastodon.Entity.Field? = {
            switch presentingAlert {
            case .deleteCustomField(let field):
                return field
            case nil:
                return nil
            }
        }()
        guard let field = deletingField, let index = customFields?.firstIndex(of: field) else { return }
        customFields?.remove(at: index)
        presentingAlert = nil
    }
    
    func cancelDeleteCustomField() {
        presentingAlert = nil
    }
}

extension ProfileEditingViewModel {
    enum FieldEditType {
        case create
        case edit(Mastodon.Entity.Field)
    }
    
    struct FieldEditingState {
        let editingField: FieldEditType
        let labelEditingModel: MetaTextInputFieldViewModel
        let valueEditingModel: MetaTextInputFieldViewModel
    }
}

extension ProfileViewModel {
    private func pagesToShow(forAccount account: MastodonAccount?) -> [ProfilePage] {
        var pages = [ProfilePage.activity]
        if account?.metadata.showsMediaTab == true {
            pages.append(.mediaOnly)
        }
        let canShowFeaturedTab = AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication.instanceConfiguration?.isAvailable(.featuredAccounts) ?? false
        if canShowFeaturedTab && account?.metadata.showsFeaturedTab == true {
            pages.append(.featured)
        }
        return pages
    }
}

extension ProfileViewModel {
    func commitEdits() async throws {
        guard let authentication = AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication else { throw APIService.APIError.explicit(.authenticationMissing) }
        
        let authenticationBox = MastodonAuthenticationBox(authentication: authentication)
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        func sizeLimitedImage(_ image: UIImage?, noLargerThan targetPixelSize: CGSize) -> UIImage? {
            guard let image else { return nil }
            if image.size.width <= targetPixelSize.width && image.size.height <= targetPixelSize.height {
                return image
            } else {
                let resized = image.af.imageScaled(to: targetPixelSize)
                return resized
            }
        }
        
        let updatedAvatarImage = sizeLimitedImage(editingViewModel.avatarConfirmedCroppedImage, noLargerThan: avatarImageMaxSizeInPixels)
        let updatedBannerImage = sizeLimitedImage(editingViewModel.confirmedBannerImage, noLargerThan: bannerImageMaxSizeInPixels)
        
        editingViewModel.commitEditingField()
        editingViewModel.commitCustomFieldsReordering()
        let customFieldsData = editingViewModel.customFields?.map { Mastodon.Entity.Field(name: $0.name, value: $0.value) }
        
        let query = Mastodon.API.Account.UpdateCredentialQuery(
            discoverable: nil,
            bot: editingViewModel.isAutomatedAccount,
            displayName: String(editingViewModel.displayNameFieldEditingViewModel.stringContent.prefix(30)),
            note: editingViewModel.bioFieldEditingViewModel.stringContent,
            avatar: updatedAvatarImage.flatMap { Mastodon.Query.MediaAttachment.png($0.pngData()) },
            header: updatedBannerImage.flatMap { Mastodon.Query.MediaAttachment.png($0.pngData()) },
            locked: nil,
            source: nil,
            fieldsAttributes: customFieldsData
        )
        
        editingStatus = .pushingChanges(success: nil)
        
        do {
            let response = try await APIService.shared.accountUpdateCredentials(
                domain: domain,
                query: query,
                authorization: authorization
            )
            let updatedAccount = MastodonAccount.fromEntity(response.value, authenticatedDomain: domain)
            account = updatedAccount
            editingViewModel.setAccount(updatedAccount, textContentDidChange: { self.checkForEditingChanges() })
            editingStatus = .pushingChanges(success: true)
            checkForEditingChanges()
        } catch {
            editingStatus = .pushingChanges(success: false)
            throw error
        }
    }
    
    func commitTabSettingsChanges() async throws {
        guard editingViewModel.showTabDisplayPreferences else { return }  // older servers don't know about these settings
        guard let navigator, let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value else { throw APIService.APIError.explicit(.authenticationMissing) }

        let updatedProfile = try await APIService.shared.updateTabDisplaySettings(showFeaturedTab: editingViewModel.featuredTabVisibilitySetting == .showFeaturedTab, showMediaTab: editingViewModel.mediaTabVisibilitySetting == .showMediaTab, showMediaReplies: editingViewModel.mediaTabRepliesSetting == .includeMyRepliesToOthers, authenticationBox: authBox)
        guard let updatedAccount = account?.byUpdatingProfileSettings(updatedProfile) else { return }
        PersistenceManager.shared.cacheAccount(updatedAccount._legacyEntity, forUserID: authBox.authentication.userIdentifier())
        set(account: updatedAccount, relationship: .isMe, navigator: navigator)
        editingViewModel.setAccount(updatedAccount, textContentDidChange: { self.checkForEditingChanges() })
    }
}

extension ProfileEditingViewModel {
    func setMediaTabVisibilitySetting(_ newSetting: MediaTabVisibilitySetting) {
        guard newSetting != mediaTabVisibilitySetting else { return }
        mediaTabVisibilitySetting = newSetting
    }
    
    func setMediaTabRepliesSetting(_ newSetting: MediaTabRepliesSetting) {
        guard newSetting != mediaTabRepliesSetting else { return }
        mediaTabRepliesSetting = newSetting
    }
    
    func setFeaturedTabVisibilitySetting(_ newSetting: FeaturedTabVisibilitySetting) {
        guard newSetting != featuredTabVisibilitySetting else { return }
        featuredTabVisibilitySetting = newSetting
    }
}

extension ProfileEditingViewModel {
    var canAddAnotherProfileField: Bool {
        if let limit = instanceLimits?.maxProfileCustomFieldsCount {
            return customFields?.count ?? 0 < limit
        } else {
            return customFields?.count ?? 0 < AccountsLimits.defaultMaxProfileCustomFieldsCount
        }
    }
    
    var customFieldLimitReachedMessage: String? {
        guard let limit = instanceLimits?.maxProfileCustomFieldsCount else { return nil }
        guard let fieldsCount = customFields?.count else { return nil }
        guard fieldsCount >= limit else { return nil }
        if let domainName = initialInfo?.domain {
            return L10nLookup.Scene.EditProfile.CustomFields.reachedMaxFields(max: limit, domain: domainName)
        } else {
            return L10nLookup.Scene.EditProfile.CustomFields.reachedMaxFields(max: limit)
        }
    }
}
