//
//  MastodonStatusContent.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/1.
//

import UIKit
import Combine
import ActiveLabel
import Fuzi

enum MastodonStatusContent {
    
    typealias EmojiShortcode = String
    typealias EmojiDict = [EmojiShortcode: URL]
    
    static let workingQueue = DispatchQueue(label: "org.joinmastodon.app.ActiveLabel.working-queue", qos: .userInteractive)
    
    static func parseResult(content: String, emojiDict: MastodonStatusContent.EmojiDict) -> AnyPublisher<MastodonStatusContent.ParseResult?, Never> {
        return Future { promise in
            self.workingQueue.async {
                let parseResult = try? MastodonStatusContent.parse(content: content, emojiDict: emojiDict)
                promise(.success(parseResult))
            }
        }
        .eraseToAnyPublisher()
    }
    
    static func parse(content: String, emojiDict: EmojiDict) throws -> MastodonStatusContent.ParseResult {
        let document: String = {
            var content = content
            for (shortcode, url) in emojiDict {
                let emojiNode = "<span class=\"emoji\" href=\"\(url.absoluteString)\">\(shortcode)</span>"
                let pattern = ":\(shortcode):"
                content = content.replacingOccurrences(of: pattern, with: emojiNode)
            }
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }()
        let rootNode = try Node.parse(document: document)
        let text = String(rootNode.text)
        
        var activeEntities: [ActiveEntity] = []
        let entities = MastodonStatusContent.Node.entities(in: rootNode)
        for entity in entities {
            let range = NSRange(entity.text.startIndex..<entity.text.endIndex, in: text)
            
            switch entity.type {
            case .url:
                guard let href = entity.href else { continue }
                let text = String(entity.text)
                activeEntities.append(ActiveEntity(range: range, type: .url(text, trimmed: entity.hrefEllipsis ?? text, url: href, userInfo: nil)))
            case .hashtag:
                var userInfo: [AnyHashable: Any] = [:]
                entity.href.flatMap { href in
                    userInfo["href"] = href
                }
                let hashtag = String(entity.text).deletingPrefix("#")
                activeEntities.append(ActiveEntity(range: range, type: .hashtag(hashtag, userInfo: userInfo)))
            case .mention:
                var userInfo: [AnyHashable: Any] = [:]
                entity.href.flatMap { href in
                    userInfo["href"] = href
                }
                let mention = String(entity.text).deletingPrefix("@")
                activeEntities.append(ActiveEntity(range: range, type: .mention(mention, userInfo: userInfo)))
            case .emoji:
                var userInfo: [AnyHashable: Any] = [:]
                guard let href = entity.href else { continue }
                userInfo["href"] = href
                let emoji = String(entity.text)
                activeEntities.append(ActiveEntity(range: range, type: .emoji(emoji, url: href, userInfo: userInfo)))
            case .none:
                continue
            }
        }
        
        var trimmed = text
        for activeEntity in activeEntities {
            MastodonStatusContent.trimEntity(status: &trimmed, activeEntity: activeEntity, activeEntities: activeEntities)
        }

        return ParseResult(
            document: document,
            original: text,
            trimmed: trimmed,
            activeEntities: activeEntities
        )
    }
    
    static func trimEntity(status: inout String, activeEntity: ActiveEntity, activeEntities: [ActiveEntity]) {
        let text: String
        let trimmed: String
        switch activeEntity.type {
        case .url(let _text, let _trimmed, _, _):
            text = _text
            trimmed = _trimmed
        case .emoji(let _text, _, _):
            text = _text
            trimmed = " "
        default:
            return
        }

        guard let index = activeEntities.firstIndex(where: { $0.range == activeEntity.range }) else { return }
        guard let range = Range(activeEntity.range, in: status) else { return }
        status.replaceSubrange(range, with: trimmed)
        
        let offset = trimmed.count - text.count
        activeEntity.range.length += offset
        
        let moveActiveEntities = Array(activeEntities[index...].dropFirst())
        for moveActiveEntity in moveActiveEntities {
            moveActiveEntity.range.location += offset
        }
    }
        
}

extension String {
    // ref: https://www.hackingwithswift.com/example-code/strings/how-to-remove-a-prefix-from-a-string
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}

extension MastodonStatusContent {
    
    class Node {
        
        let level: Int
        let type: Type?
        
        // substring text
        let text: Substring
        
        // range in parent String
        var range: Range<String.Index> {
            return text.startIndex..<text.endIndex
        }
        
        let tagName: String?
        let attributes: [String : String]
        let href: String?
        let hrefEllipsis: String?
        
        let children: [Node]
        
        init(
            level: Int,
            text: Substring,
            tagName: String?,
            attributes: [String : String],
            href: String?,
            hrefEllipsis: String?,
            children: [Node]
        ) {
            let _classNames: Set<String> = {
                guard let className = attributes["class"] else { return Set() }
                return Set(className.components(separatedBy: " "))
            }()
            let _type: Type? = {
                if tagName == "a" {
                    if _classNames.contains("u-url") {
                        return .mention
                    }
                    if _classNames.contains("hashtag") {
                        return .hashtag
                    }
                    return .url
                } else {
                    if _classNames.contains("emoji") {
                        return .emoji
                    }
                    return nil
                }
            }()
            self.level = level
            self.type = _type
            self.text = text
            self.tagName = tagName
            self.attributes = attributes
            self.href = href
            self.hrefEllipsis = hrefEllipsis
            self.children = children
        }
        
        static func parse(document: String) throws -> MastodonStatusContent.Node {
            let document = document.replacingOccurrences(of: "<br>|<br />", with: "\r\n", options: .regularExpression, range: nil)
            let html = try HTMLDocument(string: document)
            
            let body = html.body ?? nil
            let text = body?.stringValue ?? ""
            let level = 0
            let children: [MastodonStatusContent.Node] = body.flatMap { body in
                return Node.parse(element: body, parentText: text[...], parentLevel: level + 1)
            } ?? []
            let node = Node(
                level: level,
                text: text[...],
                tagName: body?.tag,
                attributes: body?.attributes ?? [:],
                href: nil,
                hrefEllipsis: nil,
                children: children
            )
            
            return node
        }
        
        static func parse(element: XMLElement, parentText: Substring, parentLevel: Int) -> [Node] {
            let parent = element
            let scanner = Scanner(string: String(parentText))
            scanner.charactersToBeSkipped = .none

            var children: [Node] = []
            for _element in parent.children {
                let _text = _element.stringValue

                // scan element text
                _ = scanner.scanUpToString(_text)
                let startIndexOffset = scanner.currentIndex.utf16Offset(in: scanner.string)
                guard scanner.scanString(_text) != nil else {
                    assertionFailure()
                    continue
                }
                let endIndexOffset = scanner.currentIndex.utf16Offset(in: scanner.string)

                // locate substring
                let startIndex = parentText.utf16.index(parentText.utf16.startIndex, offsetBy: startIndexOffset)
                let endIndex = parentText.utf16.index(parentText.utf16.startIndex, offsetBy: endIndexOffset)
                let text = Substring(parentText.utf16[startIndex..<endIndex])

                let href = _element["href"]
                let hrefEllipsis = href.flatMap { _ in _element.firstChild(css: ".ellipsis")?.stringValue }

                let level = parentLevel + 1
                let node = Node(
                    level: level,
                    text: text,
                    tagName: _element.tag,
                    attributes: _element.attributes,
                    href: href,
                    hrefEllipsis: hrefEllipsis,
                    children: Node.parse(element: _element, parentText: text, parentLevel: level + 1)
                )
                children.append(node)
            }
            
            return children
        }
        
        static func collect(
            node: Node,
            where predicate: (Node) -> Bool
        ) -> [Node] {
            var nodes: [Node] = []
            
            if predicate(node) {
                nodes.append(node)
            }
            
            for child in node.children {
                nodes.append(contentsOf: Node.collect(node: child, where: predicate))
            }
            return nodes
        }
        
    }
    
}

extension MastodonStatusContent.Node {
    enum `Type` {
        case url
        case mention
        case hashtag
        case emoji
    }
    
    static func entities(in node: MastodonStatusContent.Node) -> [MastodonStatusContent.Node] {
        return MastodonStatusContent.Node.collect(node: node) { node in node.type != nil }
    }
    
    static func hashtags(in node: MastodonStatusContent.Node) -> [MastodonStatusContent.Node] {
        return MastodonStatusContent.Node.collect(node: node) { node in node.type == .hashtag }
    }
    
    static func mentions(in node: MastodonStatusContent.Node) -> [MastodonStatusContent.Node] {
        return MastodonStatusContent.Node.collect(node: node) { node in node.type == .mention }
    }
    
    static func urls(in node: MastodonStatusContent.Node) -> [MastodonStatusContent.Node] {
        return MastodonStatusContent.Node.collect(node: node) { node in node.type == .url }
    }
    
}

extension MastodonStatusContent.Node: CustomDebugStringConvertible {
    var debugDescription: String {
        let linkInfo: String = {
            switch (href, hrefEllipsis) {
            case (nil, nil):
                return ""
            case (let href, let hrefEllipsis):
                return "(\(href ?? "nil") - \(hrefEllipsis ?? "nil"))"
            }
        }()
        let classNamesInfo: String = {
            guard let className = attributes["class"] else { return "" }
            return "@[\(className)]"
        }()
        let nodeDescription = String(
            format: "<%@>%@%@: %@",
            tagName ?? "",
            classNamesInfo,
            linkInfo,
            String(text)
        )
        guard !children.isEmpty else {
            return nodeDescription
        }
        
        let indent = Array(repeating: "  ", count: level).joined()
        let childrenDescription = children
            .map { indent + $0.debugDescription }
            .joined(separator: "\n")
        
        return nodeDescription + "\n" + childrenDescription
    }
}
