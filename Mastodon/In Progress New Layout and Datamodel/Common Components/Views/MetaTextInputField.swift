// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonUI
import MastodonLocalization
import MastodonSDK
import MastodonCore
import MetaTextKit
import MastodonMeta
import SDWebImageSwiftUI
import MastodonAsset

@MainActor
@Observable public class MetaTextInputFieldViewModel: NSObject /* for conformance to UITextViewDelegate */ {
    
    var authenticationBox: MastodonAuthenticationBox? // required for custom emojis
    public var autoCompleteInfo: AutoCompleteInfo?
    
    public var stringContent: String {
        didSet {
            guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
                characterCount = stringContent.count
                return
            }
            let matches = detector.matches(in: stringContent, options: [], range: NSRange(location: 0, length: stringContent.count))
            let lengthWithoutLinks = stringContent.count - matches.map({ match in
                guard let range = Range(match.range, in: stringContent) else {
                    return 0
                }
                let url = stringContent[range]
                return url.count
            }).reduce(0, +)
            let charactersReservedPerURL = authenticationBox?
                .authentication
                .instanceConfiguration?
                .charactersReservedPerURL ?? MastodonAuthentication.fallbackCharactersReservedPerURL
            characterCount = lengthWithoutLinks + (matches.count * charactersReservedPerURL)
        }
    }
    
    var placeholder: String
    weak var contentMetaText: MetaText? {
        didSet {
            guard let textView = contentMetaText?.textView else { return }
            customEmojiPickerInputViewModel.configure(textInput: textView)
        }
    }
    let characterLimit: CharacterLimit
    public private(set) var characterCount: Int = 0
    
    // emoji
    var isEmojiActive = false
    let customEmojiPickerInputViewModel: CustomEmojiPickerInputViewModel
    let autoCompleteViewModel: AutoCompleteViewModel?
    var isLoadingCustomEmoji = false
    
    public init(stringContent: String?, placeholder: String, characterLimit: CharacterLimit) {
        self.stringContent = stringContent ?? ""
        self.placeholder = placeholder
        self.characterLimit = characterLimit
        customEmojiPickerInputViewModel = CustomEmojiPickerInputViewModel()
        
        if let authentication = AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication {
            let authBox = MastodonAuthenticationBox(authentication: authentication)
            self.authenticationBox = authBox
            autoCompleteViewModel = AutoCompleteViewModel(authenticationBox: authBox)
        } else {
            autoCompleteViewModel = nil
        }
    }
    
    @ViewBuilder public var autoCompleteSuggestionView: some View {
        if let autoCompleteItems = autoCompleteViewModel?.autoCompleteItems.value, !autoCompleteItems.isEmpty {
            VStack {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(autoCompleteItems, id: \.self) { item in
                            AutoCompleteCard(item: item)
                        }
                    }
                    .padding()
                }
            }
            
        }
    }
}

extension MetaTextInputFieldViewModel: UITextViewDelegate {
    
    public func textViewDidChange(_ textView: UITextView) {
        // update model
        guard self.contentMetaText != nil else {
            assertionFailure()
            return
        }
        // configure auto completion
        setupAutoComplete(for: textView)
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == " ", let autoCompleteInfo = self.autoCompleteInfo {
            let isHandled = handleAutoComplete(autoCompleteInfo)
            return !isHandled
        }
        
        return true
    }
    
}

extension MetaTextInputFieldViewModel: MetaTextDelegate {
    public func metaText(
        _ metaText: MetaText,
        processEditing textStorage: MetaTextStorage
    ) -> MetaContent? {
        
        let textInput = textStorage.string
        Task {
            self.stringContent = textInput
        }
        
        let content = MastodonContent(
            content: textInput,
            emojis: autoCompleteViewModel?.customEmojiViewModel?.emojis.value?.asDictionary ?? [:]
        )
        let metaContent = MastodonMetaContent.convert(text: content)
        return metaContent
    }
}

extension MetaTextInputFieldViewModel {
    private func setupAutoComplete(for textView: UITextView) {
        guard var autoCompletion = MetaTextInputFieldViewModel.scanAutoCompleteInfo(textView: textView) else {
            self.autoCompleteInfo = nil
            return
        }
        
        autoCompleteViewModel?.inputText.send(String(autoCompletion.inputText))
        
        autoCompleteInfo = autoCompletion
    }
    
    private static func scanAutoCompleteInfo(textView: UITextView) -> AutoCompleteInfo? {
        guard let text = textView.text,
              textView.selectedRange.location > 0, !text.isEmpty,
              let selectedRange = Range(textView.selectedRange, in: text) else {
            return nil
        }
        let cursorIndex = selectedRange.upperBound
        let _highlightStartIndex: String.Index? = {
            var index = text.index(before: cursorIndex)
            while index > text.startIndex {
                let char = text[index]
                if char == "@" || char == "#" || char == ":" {
                    return index
                }
                index = text.index(before: index)
            }
            assert(index == text.startIndex)
            let char = text[index]
            if char == "@" || char == "#" || char == ":" {
                return index
            } else {
                return nil
            }
        }()
        
        guard let highlightStartIndex = _highlightStartIndex else { return nil }
        let scanRange = NSRange(highlightStartIndex..<text.endIndex, in: text)
        
        guard let match = text.firstMatch(pattern: MastodonRegex.autoCompletePattern, options: [], range: scanRange) else { return nil }
        guard let matchRange = Range(match.range(at: 0), in: text) else { return nil }
        let matchStartIndex = matchRange.lowerBound
        let matchEndIndex = matchRange.upperBound
        
        guard matchStartIndex == highlightStartIndex, matchEndIndex >= cursorIndex else { return nil }
        let symbolRange = highlightStartIndex..<text.index(after: highlightStartIndex)
        let symbolString = text[symbolRange]
        let toCursorRange = highlightStartIndex..<cursorIndex
        let toCursorString = text[toCursorRange]
        let toHighlightEndRange = matchStartIndex..<matchEndIndex
        let toHighlightEndString = text[toHighlightEndRange]
        
        let inputText = toHighlightEndString
        let autoCompleteInfo = AutoCompleteInfo(
            inputText: inputText,
            symbolRange: symbolRange,
            symbolString: symbolString,
            toCursorRange: toCursorRange,
            toCursorString: toCursorString,
            toHighlightEndRange: toHighlightEndRange,
            toHighlightEndString: toHighlightEndString
        )
        return autoCompleteInfo
    }
    
    func handleAutoComplete(_ info: AutoCompleteInfo) -> Bool {
        guard let item = autoCompleteViewModel?.autoCompleteItems.value.first else { return false }
        
        // FIXME: redundant code
        guard let metaText = contentMetaText else { return false }
        guard let text = metaText.textView.text else { return false }
        let _replacedText: String? = {
            var text: String
            switch item {
            case .hashtag, .hashtagV1:
                // do no fill the hashtag
                // allow user delete suffix and post they want
                return nil
            case .account(let account):
                text = "@" + account.acct
            case .emoji(let emoji):
                text = ":" + emoji.shortcode + ":"
            case .bottomLoader:
                return nil
            }
            return text
        }()
        guard let replacedText = _replacedText else { return false }
        
        let range = NSRange(info.toHighlightEndRange, in: text)
        metaText.textStorage.replaceCharacters(in: range, with: replacedText)
        autoCompleteInfo = nil
        
        // set selected range
        let newRange = NSRange(location: range.location + (replacedText as NSString).length, length: 0)
        guard metaText.textStorage.length >= newRange.location else { return true }
        metaText.textView.selectedRange = newRange
        
        // append a space and trigger textView delegate update
        DispatchQueue.main.async {
            metaText.textView.insertText(" ")
        }
        
        return true
    }
}

extension MetaTextInputFieldViewModel {
    public struct AutoCompleteInfo {
        // model
        let inputText: Substring
        // range
        let symbolRange: Range<String.Index>
        let symbolString: Substring
        let toCursorRange: Range<String.Index>
        let toCursorString: Substring
        let toHighlightEndRange: Range<String.Index>
        let toHighlightEndString: Substring
        // geometry
        var textBoundingRect: CGRect = .zero
        var symbolBoundingRect: CGRect = .zero
    }
}

public struct MetaTextInputField: View {
    @Environment(MetaTextInputFieldViewModel.self) var viewModel
    let margin: CGFloat = 8
    let autoCompleteHeight: CGFloat = 60
    
    public init() {
    }
    
    public var body: some View {
        GeometryReader { geo in
            VStack {
                MetaTextViewRepresentable(
                    string: Binding<String>(
                        get: { viewModel.stringContent },
                        set: { newValue in viewModel.stringContent = newValue }
                    ),
                    width: geo.size.width - margin - margin,
                    configurationHandler: { metaText in
                        viewModel.contentMetaText = metaText
                        metaText.textView.attributedPlaceholder = {
                            var attributes = metaText.textAttributes
                            attributes[.foregroundColor] = UIColor.secondaryLabel
                            return NSAttributedString(
                                string: viewModel.placeholder,
                                attributes: attributes
                            )
                        }()
                        metaText.textView.returnKeyType = .next
                        metaText.textView.delegate = viewModel
                        metaText.delegate = viewModel
                    }
                )
                .frame(width: geo.size.width - margin - margin)
                .padding(.horizontal, margin)
                .background(
                    MastodonSecondaryBackground(fillInDarkModeOnly: true)
                )
            }
        }
    }
}

public enum CharacterLimit {
    case hardLimit(Int)
    case softLimit(Int)
}

struct AutoCompleteCard: View {
    let item: AutoCompleteItem
    
    var body: some View {
        HStack {
            switch item {
            case .account(let account):
                AvatarView(size: .small, authorAvatarUrl: account.avatarImageURL(), goToProfile: nil)
                Text("@\(account.acct)")
                    .foregroundColor(Asset.Colors.accent.swiftUIColor)
                    .padding(.trailing, tinySpacing)
            case .hashtag(let tag):
                Text("#\(tag.name)")
                    .foregroundColor(Asset.Colors.accent.swiftUIColor)
            case .hashtagV1(let tag):
                Text("#\(tag)")
                    .foregroundColor(Asset.Colors.accent.swiftUIColor)
            case .emoji(let emoji):
                SDWebImageSwiftUI.WebImage(
                    url: URL(string: emoji.staticURL),
                    content: { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                    },
                    placeholder: {
                        EmptyView()
                    }
                )
                .frame(width: AvatarSize.small, height: AvatarSize.small)
                Text(":\(emoji.shortcode):")
                    .foregroundStyle(.secondary)
                    .padding(.trailing, tinySpacing)
            case .bottomLoader:
                EmptyView()
            }
        }
        .padding(tinySpacing)
        .font(.footnote)
        .background() {
            MastodonSecondaryBackground(fillInDarkModeOnly: true)
        }
    }
}
