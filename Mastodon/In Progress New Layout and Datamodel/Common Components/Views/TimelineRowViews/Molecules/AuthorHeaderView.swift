// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonSDK
import SwiftUI

struct AuthorHeaderView: View {
    
    @Environment(MastodonPostViewModel.self) private var postViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack (alignment: .top) {
                authorDisplayName
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .alignmentGuide(.gutterAlign) { d in
                        return d[HorizontalAlignment.leading]
                    }
                //                VisibilityAndTimestamp(timestamper: timestamper, referenceDate: postedDate, visibility: postViewModel.fullPost?.actionablePost?.metaData.privacyLevel ?? postViewModel.initialDisplayInfo.actionableVisibility)
                //            }
                //            Text("@\(authorHandle)")
                //                .lineLimit(1)
                //                .font(.footnote)
                //                .foregroundStyle(.secondary)
                //                .frame(maxWidth: .infinity, alignment: .leading)
            }
            VisibilityAndTimestampWithUserHandle(referenceDate: postedDate, visibility: postViewModel.fullPost?.actionablePost?.metaData.privacyLevel ?? postViewModel.initialDisplayInfo.actionableVisibility, handle: authorHandle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(postViewModel.a11yHeaderLabel)
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
            return author.displayInfo.handle
        } else {
            return postViewModel.initialDisplayInfo.actionableAuthorHandle
        }
    }
    
    var visibility: GenericMastodonPost.PrivacyLevel? {
        return postViewModel.fullPost?.actionablePost?.metaData.privacyLevel ?? postViewModel.initialDisplayInfo.actionableVisibility
    }
    
    var postedDate: Date {
        return postViewModel.fullPost?.actionablePost?.metaData.createdAt ?? postViewModel.initialDisplayInfo.actionableCreatedAt
    }
}

extension MastodonAccount: AccountInfo {
    var handle: String {
        return displayInfo.handle
    }
    
    var avatarURL: URL? {
        return displayInfo.avatarUrl
    }
    
    var locked: Bool {
        return metadata.manuallyApprovesNewFollows
    }
    
    var fullAccount: Mastodon.Entity.Account? {
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
    let referenceDate: Date
    let visibility: GenericMastodonPost.PrivacyLevel?
    let handle: String
    
    var body: some View {
        HStack(spacing: tinySpacing) {
            if let visibilityIconName {
                Image(systemName: visibilityIconName)
            }
            (Text(referenceDate.localizedExtremelyAbbreviatedTimeElapsedUntil(now: timestamper.timestamp)) + Text(" · @\(handle)"))
                .lineLimit(1)
        }
        .font(.subheadline)
        .frame(height: actionSuperheaderHeight)
        .foregroundColor(.secondary)
        .accessibilityLabel(referenceDate.localizedAbbreviatedSlowedTimeAgoSinceNow + ", \(handle)")
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
