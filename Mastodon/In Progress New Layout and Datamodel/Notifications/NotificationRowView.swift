// Copyright © 2025 Mastodon gGmbH. All rights reserved.
import Combine
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonMeta
import MastodonSDK
import MetaTextKit
import SwiftUI

enum AuthorName {
    case me
    case other(named: String, emojis: [MastodonContent.Shortcode : String ])

    var plainString: String {
        switch self {
        case .me:
            return "You"  // TODO: localize (for voice over users)
        case .other(let name, _):
            return name
        }
    }
}

extension GroupedNotificationType {
    
    enum MainIconStyle {
        case icon(name: String, color: Color)
        case avatar
    }
    
    var mainIconStyle: MainIconStyle? {
        switch self {
        case .mention, .status, .quote:
            return .avatar
        default:
            if let iconName = iconSystemName {
                return .icon(name: iconName, color: iconColor)
            }
        }
        return nil
    }

    var iconSystemName: String? {
        switch self {
        case .favourite:
            return PostAction.favourite.systemIconName(filled: true)
        case .reblog:
            return PostAction.boost.systemIconName(filled: false)
        case .quote:
            return "quote.opening"
        case .follow:
            return "person.fill.badge.plus"
        case .poll:
            return "chart.bar.yaxis"
        case .adminReport:
            return "flag.fill"
        case .severedRelationships:
            return "person.badge.minus"
        case .moderationWarning:
            return "exclamationmark.shield.fill"
        case ._other:
            return "questionmark.square.dashed"
        case .mention:
            return nil  // should show avatar
        case .status:
            return nil  // should show avatar
        case .followRequest:
            return "person.fill.badge.plus"
        case .update, .quotedUpdate:
            return "pencil"
        case .adminSignUp:
            return "person.fill.badge.plus"
        }
    }

    var iconColor: Color {
        switch self {
        case .favourite:
            return .orange
        case .reblog:
            return .green
        case .quote:
            return Asset.Colors.accent.swiftUIColor
        case .follow, .followRequest, .status, .mention, .update, .quotedUpdate:
            return Color(asset: Asset.Colors.accent)
        case .poll, .severedRelationships, .moderationWarning, .adminReport,
            .adminSignUp:
            return .secondary
        case ._other:
            return .gray
        }
    }
    
    var wantsFullStatusLayout: Bool {
        switch self {
        case .status, .mention, .quote:
            return true
        default:
            return false
        }
    }

    func actionSummaryLabel(_ sourceAccounts: NotificationSourceAccounts)
        -> AttributedString?
    {
        guard let authorName = sourceAccounts.authorName else { return nil }
        let totalAuthorCount = sourceAccounts.totalActorCount
        switch authorName {
        case .me:
            assert(totalAuthorCount == 1)
            //assert(self == .poll)
            return AttributedString(L10n.Scene.Notification.GroupedNotificationDescription.yourPollHasEnded)
        case .other(let firstAuthorName, let emojis):
            var plainString: String
            if totalAuthorCount == 1 {
                switch self {
                case .favourite:
                    plainString =  L10n.Scene.Notification.GroupedNotificationDescription.singleNameFavourited(firstAuthorName)
                case .follow:
                    plainString = L10n.Scene.Notification.GroupedNotificationDescription.singleNameFollowedYou(firstAuthorName)
                case .followRequest:
                    plainString = L10n.Scene.Notification.GroupedNotificationDescription.singleNameRequestedToFollowYou(firstAuthorName)
                case .reblog:
                    plainString = L10n.Scene.Notification.GroupedNotificationDescription.singleNameBoosted(firstAuthorName)
                case .mention, .quote:
                    plainString = firstAuthorName
                case .poll(let status):
                    let votersCount = status?.poll?.votersCount ?? 0
                    let pollDescription = L10n.Plural.Count.pollThatYouAndOthersVotedIn(votersCount - 1)
                    plainString = L10n.Scene.Notification.GroupedNotificationDescription.singleNameRanPoll(firstAuthorName, pollDescription)
                case .status:
                    plainString = firstAuthorName
                case .adminSignUp:
                    plainString = L10n.Scene.Notification.GroupedNotificationDescription.singleNameSignedUp(firstAuthorName)
                case .update:
                    plainString = L10n.Scene.Notification.GroupedNotificationDescription.singleNameEditedAPost(firstAuthorName)
                case .quotedUpdate:
                    plainString = L10n.Scene.Notification.GroupedNotificationDescription.singleNameEditedAPostYouQuoted(firstAuthorName)
                case .adminReport, .severedRelationships, .moderationWarning, ._other:
                    plainString = firstAuthorName
                }
            } else {
                switch self {
                case .favourite:
                    plainString = L10n.Plural.Count.peopleFavourited(totalAuthorCount)
                case .follow:
                    plainString = L10n.Plural.Count.peopleFollowedYou(totalAuthorCount)
                case .reblog:
                    plainString = L10n.Plural.Count.peopleBoosted(totalAuthorCount)
                case .adminSignUp:
                    plainString = L10n.Plural.Count.newSignups(totalAuthorCount)
                default:
                    plainString = L10n.Plural.Count.others(totalAuthorCount)
                }
            }
            
            var composedString = AttributedString(plainString)
            if let range = composedString.range(of: firstAuthorName) {
                let nameStyling = AttributeContainer.font(
                    .system(.body, weight: .bold))
                let authorNameComponent = styledNameComponent(firstAuthorName, style: nameStyling, emojis: emojis)
                composedString.replaceSubrange(range, with: authorNameComponent)
            }
            return composedString
        }
    }
}

extension Mastodon.Entity.Report {
    // "Someone reported X posts from someone else for rule violation"
    // "Someone reported X posts from someone else for spam"
    // "Someone reported X posts from someone else"
    var summary: AttributedString {
        if let targetedAccountName = targetAccount?.displayNameWithFallback {
            
            let postCountString: String? = {
                if let postCount = flaggedStatusIDs?.count {
                    return L10n.Plural.Count.post(postCount)
                } else {
                    return nil
                }
            }()
            
            let summaryPlainstring: String = {
                switch category {
                case .spam:
                    if let postCountString {
                        return L10n.Scene.Notification.GroupedNotificationDescription.someoneReportedPostsFromAccountForSpam(postCountString, targetedAccountName)
                    } else {
                        return L10n.Scene.Notification.GroupedNotificationDescription.someoneReportedAccountForSpam(targetedAccountName)
                    }
                case .violation:
                    if let postCountString {
                        return L10n.Scene.Notification.GroupedNotificationDescription.someoneReportedPostsFromAccountForRuleViolation(postCountString, targetedAccountName)
                    } else {
                        return L10n.Scene.Notification.GroupedNotificationDescription.someoneReportedAccountForRuleViolation(targetedAccountName)
                    }
                case ._other, nil:
                    if let postCountString {
                        return L10n.Scene.Notification.GroupedNotificationDescription.someoneReportedPostsFromAccount(postCountString, targetedAccountName)
                    } else {
                        return L10n.Scene.Notification.GroupedNotificationDescription.someoneReportedAccount(targetedAccountName)
                    }
                }
            }()
            
            var attributedString = AttributedString(summaryPlainstring)
            let boldedName = styledNameComponent(targetedAccountName, style: AttributeContainer.font(
                .system(.body, weight: .bold)), emojis: targetAccount?.emojiMeta)
            if let nameRange = attributedString.range(of: targetedAccountName) {
                attributedString.replaceSubrange(nameRange, with: boldedName)
            }
            return attributedString
        } else {
            return AttributedString("RULE VIOLATION REPORT")
        }
    }
    var displayableComment: AttributedString? {
        if let comment {
            return AttributedString(comment)
        } else {
            return nil
        }
    }
}

var listFormatter = ListFormatter()

extension Mastodon.Entity.RelationshipSeveranceEvent {
    // "An admin from <your.domain> has blocked <some other domain>, including x of your followers and y accounts you follow."

    func summary(myDomain: String) -> AttributedString? {
        let lostFollowersString =
            followersCount > 0
            ? L10n.Plural.Count.ofYourFollowers(followersCount) : nil
        let lostFollowingString =
            followingCount > 0
            ? L10n.Plural.Count.accountsThatYouFollow(followingCount) : nil

        guard
            let followersAndFollowingString = listFormatter.string(
                from: [lostFollowersString, lostFollowingString].compactMap {
                    $0
                })
        else {
            return nil
        }

        let string = L10n.Scene.Notification.NotificationDescription
            .relationshipSeverance(
                myDomain, targetName, followersAndFollowingString)

        var attributed = AttributedString(string)
        attributed.bold([myDomain, targetName])
        return attributed
    }
}

struct NotificationIconView: View {
    let systemName: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: systemName)
                .foregroundStyle(color)
        }
        .font(.system(size: 25))
        .frame(width: AvatarSize.large, alignment: .center)
        .fontWeight(.semibold)
    }
}


enum RelationshipElement: Equatable {
    case noneNeeded
    case unfetched(GroupedNotificationType)
    case fetching
    case relationshipIsChanging
    case error(Error?)
    case iDoNotFollowThem(theirAccountIsLocked: Bool)
    case iFollowThem(theyFollowMe: Bool)
    case iHaveRequestedToFollowThem
    case theyHaveRequestedToFollowMe(iFollowThem: Bool)
    case iHaveAnsweredTheirRequestToFollowMe(didAccept: Bool)

    enum FollowAction {
        case follow
        case unfollow
        case noAction
    }

    var description: String {
        switch self {
        case .noneNeeded:
            return "noneNeeded"
        case .unfetched:
            return "unfetched"
        case .fetching:
            return "fetching"
        case .relationshipIsChanging:
            return "relationshipIsChanging"
        case .error:
            return "error"
        case .iDoNotFollowThem(let theirAccountIsLocked):
            if theirAccountIsLocked {
                return "iDoNotFollowThem+canRequestToFollow"
            } else {
                return "iDoNotFollowThem+canFollow"
            }
        case .theyHaveRequestedToFollowMe(let iFollowThem):
            if iFollowThem {
                return "theyHaveRequestedToFollowMe+iFollowThem"
            } else {
                return "theyHaveRequestedToFollowMe+iDoNotFollowThem"
            }
        case .iHaveAnsweredTheirRequestToFollowMe(let didAccept):
            if didAccept {
                return "iAcceptedTheirFollowRequest"
            } else {
                return "iRejectedTheirFollowRequest"
            }
        case .iFollowThem(let theyFollowMe):
            if theyFollowMe {
                return "iFollowThem+theyFollowMe"
            } else {
                return "iFollowThem+theyDoNotFollowMe"
            }
        case .iHaveRequestedToFollowThem:
            return "iHaveRequestedToFollowThem"
        }
    }

    static func == (lhs: RelationshipElement, rhs: RelationshipElement) -> Bool
    {
        return lhs.description == rhs.description
    }

    var followAction: FollowAction {
        switch self {
        case .iDoNotFollowThem:
            return .follow
        case .iFollowThem, .iHaveRequestedToFollowThem:
            return .unfollow
        default:
            return .noAction
        }
    }

    var buttonText: String? {
        switch self {
        case .iDoNotFollowThem(let theirAccountIsLocked):
            if theirAccountIsLocked {
                return L10n.Common.Controls.Friendship.request
            } else {
                return L10n.Common.Controls.Friendship.followBack
            }
        case .iFollowThem(let theyFollowMe):
            if theyFollowMe {
                return L10n.Common.Controls.Friendship.mutual
            } else {
                return L10n.Common.Controls.Friendship.following
            }
        case .iHaveRequestedToFollowThem:
            return L10n.Common.Controls.Friendship.pending
        default:
            return nil
        }
    }
    
    func a11yActionTitle(forAccept accept: Bool = true) -> String? {
        switch self {
        case .iFollowThem, .iHaveRequestedToFollowThem:
            return L10n.Common.Alerts.UnfollowUser.unfollow
        case .theyHaveRequestedToFollowMe:
            if accept {
                return L10n.Scene.Notification.FollowRequest.accept
            } else {
                return L10n.Scene.Notification.FollowRequest.reject
            }
        case .iHaveAnsweredTheirRequestToFollowMe(let accepted):
            if accepted {
                return L10n.Scene.Notification.FollowRequest.accepted
            } else {
                return L10n.Scene.Notification.FollowRequest.rejected
            }
        default:
            return buttonText
        }
    }
}

extension Mastodon.Entity.Relationship {
    @MainActor
    var relationshipElement: RelationshipElement? {
        switch (following, followedBy) {
        case (true, _):
            return .iFollowThem(theyFollowMe: followedBy)
        case (false, true):
            if let account: AccountInfo = MastodonFeedItemCacheManager
                .shared.fullAccount(id)
                ?? MastodonFeedItemCacheManager.shared.partialAccount(id),
                account.locked
            {
                if requested {
                    return .iHaveRequestedToFollowThem
                } else {
                    return .iDoNotFollowThem(theirAccountIsLocked: true)
                }
            }
            return .iDoNotFollowThem(theirAccountIsLocked: false)
        case (false, false):
            return nil
        }
    }
}


struct NotificationSourceAccounts {
    let accounts: [AccountInfo]
    let totalActorCount: Int
    let myAccountID: String
    
    var primaryAuthorAccount: Mastodon.Entity.Account? {
        return accounts.first?.fullAccount
    }
    var authorName: AuthorName? {
        guard let firstAuthor = accounts.first else { return nil }
        return firstAuthor.displayName(whenViewedBy: myAccountID)
    }
    var firstAccountID: String? {
        return primaryAuthorAccount?.id
    }
    var avatarUrls: [URL] {
        return accounts.compactMap({ $0.avatarURL }).removingDuplicates()
    }

    init(
        myAccountID: String,
        accounts: [AccountInfo],
        totalActorCount: Int
    ) {
        self.accounts = accounts
        self.totalActorCount = totalActorCount
        self.myAccountID = myAccountID
    }
    
    func displayName(forAccount account: AccountInfo) -> String {
        return account.displayName(whenViewedBy: myAccountID)?.plainString ?? L10n.Plural.Count.others(1)
    }
}

fileprivate let avatarSpacing: CGFloat = 8

struct FilteredNotificationsRowView: View {
    
    let disclosureIndicatorSize = AvatarSize.large
    
    let contentWidth: CGFloat
    
    @Observable class ViewModel {
        var policy: Mastodon.Entity.NotificationPolicy? = nil {
            didSet {
                update(policy: policy)
            }
        }
        var isPreparingToNavigate: Bool = false
        var shouldShow: Bool = false
        
        init(policy: Mastodon.Entity.NotificationPolicy?) {
            if let policy {
                self.policy = policy
            }
        }
        
        private func update(policy: Mastodon.Entity.NotificationPolicy?) {
            guard let policy else {
                shouldShow = false
                return
            }
            shouldShow = policy.summary.pendingRequestsCount > 0
        }
    }
    
    @Environment(ViewModel.self) var viewModel
    
    var body: some View {
        if viewModel.shouldShow {
            VStack(alignment: .gutterAlign, spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    // ICON
                    NotificationIconView(systemName: "archivebox", color: .secondary)
                    
                    Spacer()
                        .frame(width: spacingBetweenGutterAndContent)
                    
                    HStack(spacing: 0) {
                        // CONTENT
                        VStack(spacing: 0) {
                            Text(L10n.Scene.Notification.FilteredNotification.title)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if let policy = viewModel.policy {
                                Text(L10n.Plural.FilteredNotificationBanner.subtitle(policy.summary.pendingRequestsCount))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .font(.subheadline)
                        
                        // DISCLOSURE INDICATOR (OR SPINNER)
                        VStack {
                            Spacer()
                            if viewModel.isPreparingToNavigate {
                                ProgressView().progressViewStyle(.circular)
                            } else {
                                Image(systemName: "chevron.forward")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 20))
                                    .fontWeight(.light)
                            }
                            Spacer()
                        }
                    }
                    .frame(width: contentWidth)
                }
            }
        } else {
            EmptyView()
        }
    }
}

struct NotificationRowView: View {

    @Environment(NotificationRowViewModel.self) var viewModel
    var contentWidth: CGFloat
    
    var body: some View {
        VStack(alignment: .gutterAlign, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                // ICON
                NotificationIconView(systemName: viewModel.iconName, color: viewModel.iconColor)
                
                Spacer()
                    .frame(width: spacingBetweenGutterAndContent)
                
                // CONTENT
                contentView
                    .font(.subheadline)
                    .frame(width: contentWidth)
            }
        }
        .onTapGesture {
            viewModel.doPrimaryNavigation()
        }
    }
    
    @ViewBuilder
    var contentView: some View {
        VStack {
            // AVATAR ROW
            if let sourceAccounts = viewModel.avatarRowSourceAccounts {
                avatarRow(accountInfo: sourceAccounts, trailingElement: viewModel.avatarRowAdditionalElement)
            }
            
            // HEADLINE AND TIMESTAMP
            HStack(spacing: 0) {
                headlineView
                if let timestamp = viewModel.notification.timestamp {
                    Spacer(minLength: standardPadding)
                    VisibilityAndTimestamp(referenceDate: timestamp, visibility: nil)
                }
            }
            
            // ADDITIONAL CONTENT
            switch viewModel.notification.type {
            case .adminReport(let report, _):
                if let comment = report?.displayableComment
                {
                    Text(comment)
                }
            case .severedRelationships:
                let label = L10n.Scene.Notification.learnMoreAboutServerBlocks
                Text(label)
                    .bold()
                    .foregroundStyle(Color(asset: Asset.Colors.accent))
            case .moderationWarning(let accountWarning, _):
                if let accountWarningText = accountWarning?.text {
                    Text(accountWarningText)
                }
                let label = L10n.Scene.Notification.Warning.learnMore
                Text(label)
                    .bold()
                    .foregroundStyle(Color(asset: Asset.Colors.accent))
            default:
                EmptyView()
            }
            
            // OPTIONAL INLINE POST VIEW
            if let postViewModel = viewModel.inlinePostViewModel {
                EmbeddedPostView(layoutWidth: contentWidth, isSummary: true)
                    .environment(postViewModel)
                    .environment(viewModel.contentConcealViewModel ?? .alwaysShow)
                    .onTapGesture {
                        postViewModel.openThreadView()
                    }
            }
        }
    }
    
    @ViewBuilder var headlineView: some View {
        switch viewModel.notification.type {
        case .follow, .followRequest, .reblog, .favourite, .poll, .update, .quotedUpdate, .adminSignUp:
            if let sourceAccounts = viewModel.avatarRowSourceAccounts,
               sourceAccounts.primaryAuthorAccount?.displayNameWithFallback != nil,
               let actionLabel = viewModel.notification.type.actionSummaryLabel(sourceAccounts) {
                Text(actionLabel)  // TODO: use RowView with emoji parsing, bold the name using html
            }
        case .mention, .status, .quote:
            Text("This notification type expects to be presented as a MastodonPostRowView, not a NotificationRowView")
        case .adminReport(let report, _):
            if let summary = report?.summary {
                Text(summary)
            }
        case .severedRelationships(let severanceEvent, _):
            if let summary = severanceEvent?.summary(myDomain: viewModel.myAccountDomain ?? "")
            {
                Text(summary)
            }
        case .moderationWarning(let accountWarning, _):
            if let actionDescription = accountWarning?.action.actionDescription {
                Text(actionDescription)
            }

        case ._other(let typeString):
                Text("UNEXPECTED NOTIFICATION TYPE: \(typeString)")
        }
    }

    @ViewBuilder
    func avatarRow(
        accountInfo: NotificationSourceAccounts,
        trailingElement: RelationshipElement
    ) -> some View {
        GeometryReader { geom in
            let maxAvatarCount = displayableAvatarCount(
                fittingWidth: geom.size.width,
                totalAvatarCount: accountInfo.avatarUrls.count,
                totalActorCount: accountInfo.totalActorCount)
            HStack(spacing: 0) {
                HStack(alignment: .center, spacing: avatarSpacing) {
                    ForEach(
                        accountInfo.accounts.prefix(maxAvatarCount), id: \.self.id
                    ) { account in
                        AvatarView(size: .small, authorAvatarUrl: account.avatarURL, goToProfile: { try await viewModel.navigateToProfile(account) })
                            .onTapGesture {
                                Task {
                                    try await viewModel.navigateToProfile(account)
                                }
                            }
                    }
                }
                if maxAvatarCount < accountInfo.totalActorCount {
                    VStack {
                        Spacer().frame(maxHeight: .infinity)
                        Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .fontWeight(.light)
                    }
                    .frame(width: 0.75 * AvatarSize.small)
                }
                Spacer().frame(minWidth: 0, maxWidth: .infinity)
                avatarRowTrailingElement(
                    trailingElement, grouped: accountInfo.totalActorCount > 1)
                .accessibilityHidden(true)
            }
        }
        .frame(height: AvatarSize.small)  // this keeps GeometryReader from causing inconsistent visual spacing in the VStack
    }

    @ViewBuilder
    func avatarRowTrailingElement(
        _ elementType: RelationshipElement, grouped: Bool
    ) -> some View {
        switch (elementType, grouped) {
        case (.fetching, false), (.relationshipIsChanging, false):
            ProgressView().progressViewStyle(.circular)
        case (.iDoNotFollowThem, false), (.iFollowThem, false),
            (.iHaveRequestedToFollowThem, false):
            if let buttonText = elementType.buttonText {
                Button(buttonText) {
                    viewModel.doAvatarRowButtonAction()
                }
                .buttonStyle(FollowButton(elementType))
            }
        case (.theyHaveRequestedToFollowMe(let iFollowThem), false):
            HStack {

                if iFollowThem {
                    Button(L10n.Common.Controls.Friendship.following) {
                        // TODO: allow unfollow here?
                    }
                    .buttonStyle(
                        FollowButton(.iFollowThem(theyFollowMe: false))
                    )
                    .fixedSize()
                    .accessibilityLabel(L10n.Common.Controls.Friendship.following)
                }

                Button(action: {
                    viewModel.doAvatarRowButtonAction(false)
                }) {
                    lightwieghtImageView("xmark.circle", size: AvatarSize.small)
                }
                .buttonStyle(
                    ImageButton(
                        foregroundColor: .secondary, backgroundColor: .clear))

                Button(action: {
                    viewModel.doAvatarRowButtonAction(true)
                }) {
                    lightwieghtImageView(
                        "checkmark.circle", size: AvatarSize.small)
                }
                .buttonStyle(
                    ImageButton(
                        foregroundColor: .secondary, backgroundColor: .clear))
            }
        case (.iHaveAnsweredTheirRequestToFollowMe(let didAccept), false):
            if didAccept {
                lightwieghtImageView("checkmark", size: AvatarSize.small)
                    .accessibilityLabel(L10n.Scene.Notification.FollowRequest.accepted)
            } else {
                lightwieghtImageView("xmark", size: AvatarSize.small)
                    .accessibilityLabel(L10n.Scene.Notification.FollowRequest.rejected)
            }
        case (.error(_), _):
            lightwieghtImageView(
                "exclamationmark.triangle", size: AvatarSize.small)
        default:
            Spacer().frame(width: 0)
        }
    }
}

let baseActionSuperheaderHeight: CGFloat = 20
    func displayableAvatarCount(
        fittingWidth: CGFloat, totalAvatarCount: Int, totalActorCount: Int
    ) -> Int {
        let maxAvatarCount = Int(
            floor(fittingWidth / (AvatarSize.small + avatarSpacing)))
        if maxAvatarCount < totalActorCount {
            return max(0, maxAvatarCount - 1)
        } else {
            return max(0, maxAvatarCount)
        }
    }
@ViewBuilder
func textComponent(_ string: String, fontWeight: SwiftUICore.Font.Weight?)
    -> some View
{
    Text(string)
        .fontWeight(fontWeight)
        .frame(maxWidth: .infinity, alignment: .leading)
}

func styledNameComponent(_ name: String, style: AttributeContainer, emojis: [MastodonContent.Shortcode: String]?) -> AttributedString {
    var nameComponent = attributedString(fromHtml: name, emojis: emojis ?? [:])
    nameComponent.setAttributes(style)
    return nameComponent
}

extension Mastodon.Entity.Status {
    public enum AttachmentSummaryInfo {
        case image(Int)
        case gifv(Int)
        case video(Int)
        case audio(Int)
        case generic(Int)
        case poll

        var count: Int {
            switch self {
            case .image(let count), .gifv(let count), .video(let count),
                .audio(let count), .generic(let count):
                return count
            case .poll:
                return 1
            }
        }

        var iconName: String {
            switch self {
            case .image(1):
                return "photo"
            case .image(2):
                return "photo.on.rectangle"
            case .image:
                return "photo.stack"
            case .gifv, .video:
                return "play.tv"
            case .audio:
                return "speaker.wave.2"
            case .generic(1):
                return "rectangle"
            case .generic(2):
                return "rectangle.on.rectangle"
            case .generic:
                return "rectangle.stack"
            case .poll:
                return "chart.bar.yaxis"
            }
        }

        var labelText: String {
            switch self {
            case .image(let count):
                return L10n.Plural.Count.image(count)
            case .gifv(let count):
                return L10n.Plural.Count.gif(count)
            case .video(let count):
                return L10n.Plural.Count.video(count)
            case .audio(let count):
                return L10n.Plural.Count.audio(count)
            case .generic(let count):
                return L10n.Plural.Count.attachment(count)
            case .poll:
                return L10n.Plural.Count.poll(1)
            }
        }

        private func withUpdatedCount(_ newCount: Int) -> AttachmentSummaryInfo
        {
            switch self {
            case .image:
                return .image(newCount)
            case .gifv:
                return .gifv(newCount)
            case .video:
                return .video(newCount)
            case .audio:
                return .audio(newCount)
            case .generic:
                return .generic(newCount)
            case .poll:
                return .poll
            }
        }

        private func _adding(_ otherAttachmentInfo: AttachmentSummaryInfo)
            -> AttachmentSummaryInfo
        {
            switch (self, otherAttachmentInfo) {
            case (.poll, _), (_, .poll):
                assertionFailure(
                    "did not expect poll to co-occur with another attachment type"
                )
                return .poll
            case (.gifv, .gifv), (.image, .image), (.video, .video),
                (.audio, .audio):
                return withUpdatedCount(count + otherAttachmentInfo.count)
            default:
                return .generic(count + otherAttachmentInfo.count)
            }
        }

        func adding(attachment: Mastodon.Entity.Attachment)
            -> AttachmentSummaryInfo
        {
            return _adding(AttachmentSummaryInfo(attachment))
        }

        init(_ attachment: Mastodon.Entity.Attachment) {
            switch attachment.type {
            case .image:
                self = .image(1)
            case .gifv:
                self = .gifv(1)
            case .video:
                self = .video(1)
            case .audio:
                self = .audio(1)
            case .unknown, ._other:
                self = .generic(1)
            }
        }
    }
}

extension Mastodon.Entity.Status {
    public struct ViewModel {
        public let content: GenericMastodonPost.PostContent?
        public let createdAt: Date
        public let visibility: Mastodon.Entity.Status.Visibility?
        public let isReplyToMe: Bool
        public let isPinned: Bool
        public let accountDisplayName: String?
        public let accountFullName: String?
        public let accountAvatarUrl: URL?
        public var needsUserAttribution: Bool {
            return accountDisplayName != nil || accountFullName != nil
        }
        public let attachmentInfo: AttachmentSummaryInfo?
        public let navigateToStatus: () -> Void
    }

    public func viewModel(
        myAccountID: String, myDomain: String, navigateToStatus: @escaping () -> Void
    ) -> ViewModel {
        let content: GenericMastodonPost.PostContent?
        if let post = GenericMastodonPost.fromStatus(self) as? MastodonContentPost {
            content = post.content
        } else {
            content = nil
        }
        
        let createdAt = self.createdAt
        let accountFullName =
            account.domain == myDomain ? account.acct : account.acctWithDomain
        let attachmentInfo = mediaAttachments?.reduce(
            nil,
            {
                (
                    partialResult: AttachmentSummaryInfo?,
                    attachment: Mastodon.Entity.Attachment
                ) in
                if let partialResult = partialResult {
                    return partialResult.adding(attachment: attachment)
                } else {
                    return AttachmentSummaryInfo(attachment)
                }
            })

        let pollInfo: AttachmentSummaryInfo? = poll != nil ? .poll : nil

        return ViewModel(
            content: content,
            createdAt: createdAt,
            visibility: visibility,
            isReplyToMe: inReplyToAccountID == myAccountID,
            isPinned: false,
            accountDisplayName: account.displayName,
            accountFullName: accountFullName,
            accountAvatarUrl: account.avatarImageURL(),
            attachmentInfo: attachmentInfo ?? pollInfo,
            navigateToStatus: navigateToStatus)
    }
}

struct FollowButton: ButtonStyle {
    private let followAction: RelationshipElement.FollowAction

    init(_ relationshipElement: RelationshipElement) {
        followAction = relationshipElement.followAction
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding([.horizontal], 12)
            .padding([.vertical], 4)
            .background(backgroundColor)
            .foregroundStyle(textColor)
            .controlSize(.small)
            .fontWeight(fontWeight)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch followAction {
        case .follow:
            return Color(uiColor: Asset.Colors.Button.userFollow.color)
        case .unfollow:
            return Color(uiColor: Asset.Colors.Button.userFollowing.color)
        case .noAction:
            assertionFailure()
            return .clear
        }
    }

    private var textColor: Color {
        switch followAction {
        case .follow:
            return .white
        case .unfollow:
            return Color(uiColor: Asset.Colors.Button.userFollowingTitle.color)
        case .noAction:
            assertionFailure()
            return .clear
        }
    }

    private var fontWeight: SwiftUICore.Font.Weight {
        switch followAction {
        case .follow:
            return .regular
        case .unfollow:
            return .light
        case .noAction:
            assertionFailure()
            return .regular
        }
    }
}

struct ImageButton: ButtonStyle {

    let foregroundColor: Color
    let backgroundColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
}

@ViewBuilder func lightwieghtImageView(_ systemName: String, size: CGFloat)
    -> some View
{
    Image(systemName: systemName)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .fontWeight(.light)
        .frame(width: size, height: size)
}

extension AttributedString {
    mutating func bold(_ substrings: [String]) {
        let boldedRanges = substrings.map {
            self.range(of: $0)
        }.compactMap { $0 }
        for range in boldedRanges {
            self[range].font = .system(.body).bold()
        }
    }
}
