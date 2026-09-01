// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonSDK
import SwiftUI

struct AuthorHeaderView: View {
    
    @Environment(MastodonPostViewModel.self) private var postViewModel
    let threadedContext: ThreadedConversationModel.ThreadContext?
    let isPinned: Bool
    let getAccount: (Mastodon.Entity.Account.ID)->(MastodonAccount?)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack (alignment: .top) {
                authorDisplayName
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .alignmentGuide(.gutterAlign) { d in
                        return d[HorizontalAlignment.leading]
                    }
                if isPinned {
                    ProfileBadge.pinned
                }
            }
            switch postViewModel.displayType {
            case .editHistory:
                VisibilityAndTimestampWithUserHandle(referenceDate: nil, visibility: postViewModel.actionablePostVisibility, handle: authorHandle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            case .standard:
                VisibilityAndTimestampWithUserHandle(referenceDate: postViewModel.actionableCreatedAt, visibility: postViewModel.actionablePostVisibility, handle: authorHandle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(postViewModel.a11yHeaderLabel(inThreadedContext: threadedContext, getAccount: getAccount))
    }
    
    @ViewBuilder var authorDisplayName: some View {
        if let actionablePost = postViewModel.fullPost?.actionablePost {
            let author = actionablePost.metaData.author
            MastodonContentView.header(html: author.displayInfo.displayName, emojis: author.displayInfo.emojis, style: .author(isInlinePreview: false))
        } else {
            Text(postViewModel.initialDisplayInfo.actionableAuthorDisplayName)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
    
    var authorHandle: String {
        if let actionablePost = postViewModel.fullPost?.actionablePost {
            let author = actionablePost.metaData.author
            return author.displayInfo.fullHandle
        } else {
            return postViewModel.initialDisplayInfo.actionableAuthorHandle
        }
    }
}

extension MastodonAccount: AccountInfo {
    public var handle: String {
        return displayInfo.fullHandle
    }
    
    public var avatarURL: URL? {
        return displayInfo.avatarUrl
    }
    
    public var locked: Bool {
        return metadata.manuallyApprovesNewFollows
    }
    
    public var fullAccount: Mastodon.Entity.Account? {
        return nil
    }
}

struct VisibilityAndTimestamp: View {
    @ScaledMetric private var actionSuperheaderHeight = baseActionSuperheaderHeight
    @Environment(TimestampUpdater.self) var timestamper
    let referenceDate: Date
    let visibility: GenericMastodonPost.PrivacyLevel?
    
    var body: some View {
        HStack(spacing: tinySpacing) {
            if let visibilityIconName {
                Image(systemName: visibilityIconName)
            }
            Text(referenceDate.localizedExtremelyAbbreviatedTimeElapsedUntil(now: timestamper.timestamp))
                .fixedSize(horizontal: true, vertical: false)
        }
        .font(.footnote)
        .frame(height: actionSuperheaderHeight)
        .foregroundColor(.secondary)
        .accessibilityLabel(referenceDate.localizedAbbreviatedSlowedTimeAgoSinceNow)
    }
    
    var visibilityIconName: String? {
        switch visibility {
        case .loudPublic:
            return nil // we consider this one the default, so we don't want to show the icon for it
        case nil:
            return nil
        default:
            return visibility!.iconName
        }
    }
}

struct VisibilityAndTimestampWithUserHandle: View {
    @ScaledMetric private var actionSuperheaderHeight = baseActionSuperheaderHeight
    @Environment(TimestampUpdater.self) var timestamper
    let referenceDate: Date?
    let visibility: GenericMastodonPost.PrivacyLevel?
    let handle: String
    
    var body: some View {
        HStack(spacing: tinySpacing) {
            if let visibilityIconName {
                Image(systemName: visibilityIconName)
            }
            if let dateText {
                (Text(dateText) + Text(" · @\(handle)"))
                    .lineLimit(1)
            } else {
                Text("@\(handle)")
                    .lineLimit(1)
            }
        }
        .font(.subheadline)
        .frame(height: actionSuperheaderHeight)
        .foregroundColor(.secondary)
        .accessibilityLabel(dateText == nil ? handle : dateText! + ", \(handle)")
    }
    
    var dateText: String? {
        guard let referenceDate else { return nil }
        if abs(referenceDate.timeIntervalSinceNow) > 7/*days*/ * 24/*hours*/ * 60/*minutes*/ * 60/*seconds*/ {
            let dateYear = Calendar.current.component(.year, from: referenceDate)
            let currentYear = Calendar.current.component(.year, from: .now)
            return referenceDate.formatted(.dateTime.year( dateYear == currentYear ? .omitted : .defaultDigits).month(.abbreviated).day(.defaultDigits).hour(.omitted).minute(.omitted))
        } else {
            return referenceDate.localizedExtremelyAbbreviatedTimeElapsedUntil(now: timestamper.timestamp)
        }
    }
    
    var visibilityIconName: String? {
        switch visibility {
        case .loudPublic:
            return nil // we consider this one the default, so we don't want to show the icon for it
        case nil:
            return nil
        default:
            return visibility!.iconName
        }
    }
}

extension GenericMastodonPost.PrivacyLevel {
    var iconName: String {
        switch self {
        case .loudPublic:
            "globe.europe.africa"
        case .quietPublic:
            "moon"
        case .followersOnly:
            "lock"
        case .mentionedOnly:
            "at"
        }
    }
}
