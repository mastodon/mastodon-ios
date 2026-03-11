// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonSDK
import MastodonMeta
import SwiftUI
import MastoParse
import SDWebImage
import UIKit
import MastodonAsset

func pointSize(for textStyle: SwiftUI.Font.TextStyle, traitCollection: UITraitCollection? = nil) -> CGFloat {
    let uiTextStyle = textStyle.uiFontTextStyle
    let font = UIFont.preferredFont(forTextStyle: uiTextStyle, compatibleWith: traitCollection)
    return font.pointSize
}

extension SwiftUI.Font.TextStyle {
    var uiFontTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }
}

public enum MastodonContentView {
    public typealias Emojis = [Mastodon.Entity.Emoji]
    
    case timelinePost(html: String, emojis: Emojis, isInlinePreview: Bool)
    case customProfileField(html: String, emojis: Emojis, bold: Bool, lineLimit: Int?)
    case header(html: String, emojis: Emojis, style: PostViewHeaderStyle)
    case verifiedLink(html: String)
    case notificationActionLabel(html: String, emojis: Emojis)
}

public enum PostViewHeaderStyle {
    case profileDisplayName
    case author(isInlinePreview: Bool)
    case socialContext(isPrivate: Bool)
    case linkPreviewCardAuthorButton
    case pollOption
    
    var font: SwiftUI.Font.TextStyle {
        switch self {
        case .profileDisplayName:
                .title2
        case .author(let isInlinePreview):
            isInlinePreview ? .caption : .subheadline
        case .socialContext:
                .footnote
        case .linkPreviewCardAuthorButton:
                .callout
        case .pollOption:
                .body
        }
    }
    
    var fontWeight: SwiftUI.Font.Weight {
        switch self {
        case .profileDisplayName:
                .semibold
        case .author:
                .semibold
        case .linkPreviewCardAuthorButton:
                .semibold
        case .pollOption:
                .semibold
        case .socialContext:
                .bold
        }
    }
    
    var color: Color {
        switch self {
        case .profileDisplayName:
                .primary
        case .author:
                .primary
        case .socialContext(let isPrivate):
            isPrivate ? Asset.Colors.accent.swiftUIColor : Color.secondary
        case .linkPreviewCardAuthorButton:
                .primary
        case .pollOption:
                .primary
        }
    }
    
}

extension MastodonContentView: View {
    public var body: some View {
            switch self {
            case .verifiedLink(let html):
                if let blocks = try? getParseBlocks(from: html) {
                    TimelinePostContentView(lineLimit: 1, contentBlocks: blocks, emojis: [])
                        .font(.subheadline)
                }
            case .customProfileField(let html, let emojis, let bold, let lineLimit):
                if let blocks = try? getParseBlocks(from: html) {
                    TimelinePostContentView(lineLimit: lineLimit, contentBlocks: blocks, emojis: emojis)
                        .font(lineLimit == nil ? .body : .footnote)
                        .fontWeight(bold ? .semibold : .regular)
                }
            case .notificationActionLabel(let html, let emojis):
                if let blocks = try? getParseBlocks(from: html) {
                    TimelinePostContentView(lineLimit: 1, contentBlocks: blocks, emojis: emojis)
                        .font(.subheadline)
                }
            case .timelinePost(let html, let emojis, let isInlinePreview):
                if let blocks = try? getParseBlocks(from: html) {
                    TimelinePostContentView(lineLimit: isInlinePreview ? 4 : nil, contentBlocks: blocks, emojis: emojis)
                        .font(isInlinePreview ? Font.subheadline : .body)
                }
            case .header(let html, let emojis, let style):
                let block = MastoParseInlineElement(type: .text, contents: html)
                let row = MastoParseContentRow(contents: [block], style: .paragraph, listItemPrefix: nil, nestedFormatting: [])
                RowView(row: row, emojis: emojis, font: style.font, lineLimit: Int.max)
                    .font(Font.system(style.font))
                    .fontWeight(style.fontWeight)
                    .foregroundStyle(style.color)
            }
    }
}

func mapEmojiShortcodeToEmojis(_ emojis: MastodonContentView.Emojis) -> [MastodonContent.Shortcode: String] {
    return emojis.reduce(into: [:]) { partialResult, emoji in
        partialResult[emoji.shortcode] = emoji.staticURL
    }
}

struct TimelinePostContentView: View {
    let lineLimit: Int?
    let contentBlocks: [MastoParseContentBlock]
    let emojis: MastodonContentView.Emojis
    
    var body: some View {
        VStack(alignment: .leading, spacing: doublePadding) { // the large spacing creates the expected separation between paragraphs
            ForEach(contentBlocks.prefix(lineLimit == nil ? Int.max : 1)) { block in
                if let blockquote = block as? MastoParseBlockquote {
                    BlockquoteView(block: blockquote, emojis: emojis, lineLimit: lineLimit)
                } else if let row = block as? MastoParseContentRow {
                    RowView(row: row, emojis: emojis, lineLimit: lineLimit)
                } else {
                    Text("CASE NOT HANDLED")
                }
            }
        }
    }
}

let indent: CGFloat = 16
let nestedBlockQuoteIndicatorWidth: CGFloat = 2
let indicatorToBlockQuoteSpacing: CGFloat = 4

let blockquoteColor = Color.purple.opacity(0.5)
struct BlockquoteView: View {
    let block: MastoParseBlockquote
    let emojis: MastodonContentView.Emojis
    let lineLimit: Int?
    
    var body: some View {
        HStack {
            VStack {
                Image(systemName: "quote.opening")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(blockquoteColor)
                
                Spacer()
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(block.contents.enumerated().prefix(lineLimit == nil ? Int.max : 1)), id: \.offset) { idx, element in
                    RowView(row: element, emojis: emojis, lineLimit: lineLimit)
                }
            }
        }
    }
}

enum TextElement {
    case image(Image)
    case emojiShortcode(String)
    case text(LocalizedStringKey)
    case code(String)
}

@MainActor
class CustomEmojiTextModel: ObservableObject {
    @Published public var textElements: [TextElement] = []
    private var emojis: MastodonContentView.Emojis = []
    
    func prepareWith(elements: [MastoParseInlineElement], emojis: MastodonContentView.Emojis, font: SwiftUI.Font.TextStyle) async {
        self.emojis = emojis
        self.textElements = elements.reduce(into: [TextElement](), { partialResult, inline in
            switch inline.type {
            case .text:
                // 1. Separate on ":" and look for shortcode matches.
                // 2. Join stretches of non-matches with ":" as the separator.
                let substrings = inline.contents.split(separator: ":")
                var textAndEmojiShortcodes = [TextElement]()
                var accumulatingNonEmoji: String? = nil
                for substring in substrings {
                    if let matchingEmoji = emojis.first(where: { emoji in
                        emoji.matchesShortcode(String(substring))
                    }) {
                        if let accumulatingNonEmoji {
                            textAndEmojiShortcodes.append(.text(LocalizedStringKey(accumulatingNonEmoji)))
                        }
                        textAndEmojiShortcodes.append(.emojiShortcode(matchingEmoji.shortcode))
                        accumulatingNonEmoji = nil
                    } else {
                        if let accumulating = accumulatingNonEmoji {
                            accumulatingNonEmoji = [accumulating, String(substring)].joined(separator: ":")
                        } else {
                            accumulatingNonEmoji = String(substring)
                        }
                    }
                }
                if let accumulatingNonEmoji {
                    textAndEmojiShortcodes.append(.text(LocalizedStringKey(accumulatingNonEmoji)))
                }
                partialResult.append(contentsOf: textAndEmojiShortcodes)
            case .code:
                partialResult.append(.code(inline.contents))
            }
        })
        
        let emojiImages = await loadEmojis(font: font)
        
        guard !Task.isCancelled else { return }
        updateWithEmojis(emojiImages)
    }
    
    private func loadEmojis(font: SwiftUI.Font.TextStyle) async -> [String : Image] {
        var urls = [URL]()
        var urlsToShortcodes = [URL : String]()
        
        for emoji in emojis {
            guard let url = URL(string: emoji.staticURL) else { continue }
            urlsToShortcodes[url] = emoji.shortcode
            urls.append(url)
        }

        let result = await withCheckedContinuation { continuation in
            CustomEmojiTextModel.loadEmojiImages(urls: urls, forFont: font) { images in
                let emojiImages: [String : Image] = images.enumerated().reduce(into:  [String : Image]()) { partialResult, enumeration in
                    let (index, image) = enumeration
                    let url = urls[index]
                    if let shortcode = urlsToShortcodes[url], let image {
                        partialResult[shortcode] = Image(uiImage: image)
                    }
                }
                continuation.resume(returning: emojiImages)
            }
        }
        return result
    }
    
    private func updateWithEmojis(_ emojis: [String : Image]) {
        textElements = textElements.map({ element in
            switch element {
            case .code, .text, .image:
                element
            case .emojiShortcode(let shortcode):
                if let image = emojis[shortcode] {
                    .image(image)
                } else {
                    element
                }
            }
        })
    }
    
    private static func loadEmojiImages(
        urls: [URL],
        forFont font: SwiftUI.Font.TextStyle,
        completion: @escaping ([UIImage?]) -> Void)
    {
        let group = DispatchGroup()
        var results = Array<UIImage?>(repeating: nil, count: urls.count)
        
        let screenScale = UIScreen.main.scale
        let emojiSize = pointSize(for: font)
        let pixelSize = CGSize(width: emojiSize, height: emojiSize)
        
        let transformer = SDImageResizingTransformer(size: pixelSize, scaleMode: .aspectFill)
        
        for (index, url) in urls.enumerated() {
            group.enter()
            SDWebImageManager.shared.loadImage(
                with: url,
                options: [],
                context: [.imageTransformer: transformer, .imageScaleFactor: screenScale],
                progress: nil
            ) { image, _, error, _, _, _ in
                results[index] = image          // keep nil if failed
                group.leave()
            }
        }
        
        group.notify(queue: .main) { completion(results) }
    }
}

struct RowView: View {
    let font: SwiftUI.Font.TextStyle
    private var imgBaseline: CGFloat {
        let percent: CGFloat = -0.25
        return pointSize(for: font) * percent
    }
    
    
    let row: MastoParseContentRow
    let emojis: MastodonContentView.Emojis
    let lineLimit: Int?
    
    @StateObject private var textModel = CustomEmojiTextModel()
    
    init(row: MastoParseContentRow, emojis: MastodonContentView.Emojis, font: SwiftUI.Font.TextStyle = .body, lineLimit: Int?) {
        self.row = row
        self.emojis = emojis
        self.font = font
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        let totalFormattingSpaceRequired = row.nestedFormatting.reduce(into: CGFloat.zero) { partialResult, format in
            switch format {
            case .listLevel:
                partialResult += indent
            case .subordinateBlockquote:
                partialResult += nestedBlockQuoteIndicatorWidth + indicatorToBlockQuoteSpacing
            case .topLevelBlockquote:
                break
            }
        }
        
        combineElements(textModel.textElements)
            .lineLimit(lineLimit)
            .tint(.blue) // this controls the color of links
            .padding(EdgeInsets(top: 0, leading: totalFormattingSpaceRequired, bottom: 0, trailing: 0))
            .background() {
                // Putting the nested blockquote bar in a background correctly expands its height to match the contents of the row. Trying to include it in the same HStack as the content leaves the bar too short.
            HStack(spacing: 0) {
                ForEach(Array(row.nestedFormatting.enumerated()), id: \.offset) { idx, indicator in
                    switch indicator {
                    case .topLevelBlockquote:
                        EmptyView()
                    case .subordinateBlockquote:
                        blockquoteColor
                            .frame(width: nestedBlockQuoteIndicatorWidth)
                        Spacer()
                            .frame(maxWidth: indicatorToBlockQuoteSpacing)
                    case .listLevel:
                        ZStack(alignment: .topLeading) {
                            Spacer()
                                .frame(width: indent)
                                .frame(maxHeight: .infinity)
                            if let prefix = row.listItemPrefix, idx == row.nestedFormatting.count - 1 {
                                Text(prefix)
                                    .font(Font.system(font))
                            }
                        }
                    }
                }
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
        .task(id: row.contents) {
            await textModel.prepareWith(elements: row.contents, emojis: emojis, font: font)
        }
    }
    
    @ViewBuilder func combineElements(_ elements: [TextElement]) -> some View {
        let pieces = elements.map { element in
            switch element {
            case .image(let image):
                return Text("\(image)").baselineOffset(imgBaseline) // without the baseline adjustment, the custom emoji sit too high amidst the surrounding text
            case .emojiShortcode(let shortcode):
                return Text(":\(shortcode):")
            case .text(let text):
                return Text(text)
            case .code(let text):
                var attributed = AttributedString(text)
                attributed.backgroundColor = blockquoteColor
                attributed.font = .system(.body, design: .monospaced)
                return Text(attributed)
            }
        }
        buildBalancedTextTree(pieces)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    func buildBalancedTextTree(_ elements: [Text]) -> Text {
        // After seeing crash reports caused by too many levels of recursion in ConcatenatedTextStorage.resolve, some research suggested that it is fairly easy to overwhelm the Text concatenation system by simply concatenating one element after the other. Hoping to avoid this by combining the Text elements in a balanced tree instead.
        guard !elements.isEmpty else { return Text("") }
        
        var currentLevel = elements // we will combine these in pairs one level of the tree at a time until only one node remains
        while currentLevel.count > 1 {
            var nextLevel: [Text] = []
            
            var i = 0
            while i < currentLevel.count {
                if i + 1 < currentLevel.count {
                    nextLevel.append(currentLevel[i] + currentLevel[i + 1]) // combine a pair, using Text concatenation (Text + Text => Text)
                    i += 2
                } else {
                    // Odd node, carry it forward
                    nextLevel.append(currentLevel[i])
                    i += 1
                }
            }
            
            currentLevel = nextLevel
        }
        
        return currentLevel[0]
    }
}

extension Mastodon.Entity.Emoji {
    func matchesShortcode(_ codeToMatch: String) -> Bool {
        return shortcode == codeToMatch || escapeMarkdown(shortcode) == codeToMatch
    }
    
    private func escapeMarkdown(_ text: String) -> String {
        // Escape Markdown characters unless inside code blocks
        let specialChars = ["\\", "`", "*", "_", "{", "}", "[", "]", "(", ")", "#", "+", "-", ".", "!"]
        var escaped = text
        for char in specialChars {
            escaped = escaped.replacingOccurrences(of: char, with: "\\" + char)
        }
        return escaped
    }
}
