//
//  MastodonStatusContent+ParseResult.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-6-20.
//

import Foundation
import ActiveLabel

extension MastodonStatusContent {
    public struct ParseResult: Hashable {
        public let document: String
        public let original: String
        public let trimmed: String
        public let activeEntities: [ActiveEntity]

        public static func == (lhs: MastodonStatusContent.ParseResult, rhs: MastodonStatusContent.ParseResult) -> Bool {
            return lhs.document == rhs.document
                && lhs.original == rhs.original
                && lhs.trimmed == rhs.trimmed
                && lhs.activeEntities.count == rhs.activeEntities.count     // FIXME:
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(document)
            hasher.combine(original)
            hasher.combine(trimmed)
            hasher.combine(activeEntities.count)        // FIXME:
        }

        func trimmedAttributedString(appearance: MastodonStatusContent.Appearance) -> NSAttributedString {
            let attributedString = NSMutableAttributedString(string: trimmed, attributes: appearance.attributes)
            for entity in activeEntities {
                switch entity.type {
                case .url:
                    attributedString.addAttributes(appearance.urlAttributes, range: entity.range)
                case .hashtag:
                    attributedString.addAttributes(appearance.hashtagAttributes, range: entity.range)
                case .mention:
                    attributedString.addAttributes(appearance.mentionAttributes, range: entity.range)
                default:
                    break
                }
                if let uri = entity.type.uri {
                    attributedString.addAttributes([
                        .link: uri
                    ], range: entity.range)
                }
            }
            return attributedString
        }
    }
}

extension ActiveEntityType {

    static let appScheme = "mastodon"

    public init?(url: URL) {
        guard let scheme = url.scheme?.lowercased() else { return nil }
        guard scheme == ActiveEntityType.appScheme else {
            self = .url("", trimmed: "", url: url.absoluteString, userInfo: nil)
            return
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let parameters = components.queryItems else { return nil }

        if let hashtag = parameters.first(where: { $0.name == "hashtag" }), let encoded = hashtag.value, let value = String(base64Encoded: encoded) {
            self = .hashtag(value, userInfo: nil)
            return
        }
        if let mention = parameters.first(where: { $0.name == "mention" }), let encoded = mention.value, let value = String(base64Encoded: encoded) {
            self = .mention(value, userInfo: nil)
            return
        }
        return nil
    }

    public var uri: URL? {
        switch self {
        case .url(_, _, let url, _):
            return URL(string: url)
        case .hashtag(let hashtag, _):
            return URL(string: "\(ActiveEntityType.appScheme)://meta?hashtag=\(hashtag.base64Encoded)")
        case .mention(let mention, _):
            return URL(string: "\(ActiveEntityType.appScheme)://meta?mention=\(mention.base64Encoded)")
        default:
            return nil
        }
    }

}

extension String {
    fileprivate var base64Encoded: String {
        return Data(self.utf8).base64EncodedString()
    }

    init?(base64Encoded: String) {
        guard let data = Data(base64Encoded: base64Encoded),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        self = string
    }
}
