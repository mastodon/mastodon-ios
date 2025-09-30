// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonLocalization

enum SocialContextHeader {
    case mention(isPrivate: Bool)
    case reply(to: String, isPrivate: Bool, isNotification: Bool, emojis: MastodonContentView.Emojis)
    case boosted(by: String, emojis: MastodonContentView.Emojis)
    case quoted(by: String, emojis: MastodonContentView.Emojis)
    //case pinned
    
    var isPrivate: Bool {
        switch self {
        case .mention(let isPrivate), .reply(_, let isPrivate, _, _):
            return isPrivate
        default:
            return false
        }
    }
    
    var iconName: String {
        switch self {
        case .mention:
            return "at"
        case .reply:
            return PostAction.reply.systemIconName(filled: false)
        case .boosted:
            return PostAction.boost.systemIconName(filled: false)
        case .quoted:
            return "quote.opening"
        }
    }
    
    var text: String {
        switch self {
        case .mention(let isPrivate):
            return isPrivate ? L10n.Common.Controls.Status.privateMention : L10n.Common.Controls.Status.mention
        case .reply(let originalPoster, let isPrivate, let isNotification, _):
            switch (isPrivate, isNotification) {
            case (true, _):
                return L10n.Common.Controls.Status.privateReply
            case (false, true):
                return L10n.Common.Controls.Status.reply
            case (false, false):
                return L10n.Common.Controls.Status.userRepliedTo(originalPoster)
            }
        case .boosted(let booster, _):
            return L10n.Common.Controls.Status.userReblogged(booster)
        case .quoted(let quoter, _):
                   return L10n.Scene.Notification.GroupedNotificationDescription.singleNameQuoted(quoter)
        }
    }
    
    var emojis: MastodonContentView.Emojis {
        switch self {
        case .boosted(_, let emojis):
            return emojis
        case .mention:
            return MastodonContentView.Emojis()
        case .reply(_, _, _, let emojis):
            return emojis
        case .quoted(_, let emojis):
             return emojis

        }
    }
    
    var color: Color {
        switch self {
        case .mention(true), .reply(_, true, _, _):  // isPrivate
            return Asset.Colors.accent.swiftUIColor
        default:
            return .secondary
        }
    }
    
    var uiColor: UIColor {
        switch self {
        case .mention(true), .reply(_, true, _, _):  // isPrivate
            return Asset.Colors.accent.color
        default:
            return .secondaryLabel
        }
    }
}

let socialContextHeaderHeight: CGFloat = 20

extension SocialContextHeader: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: spacingBetweenGutterAndContent) {
            Image(systemName: iconName)
                .font(.footnote)
                .bold()
                .foregroundStyle(color)
                .frame(height: socialContextHeaderHeight)
            
            MastodonContentView.header(html: text, emojis: emojis, style: .socialContext(isPrivate: isPrivate))
                .frame(height: socialContextHeaderHeight)
                .lineLimit(1)
                .alignmentGuide(.gutterAlign) { d in
                    return d[HorizontalAlignment.leading]
                }
        }
    }
}

