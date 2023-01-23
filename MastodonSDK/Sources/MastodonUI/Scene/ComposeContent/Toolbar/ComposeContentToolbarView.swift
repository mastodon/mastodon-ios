//
//  ComposeContentToolbarView.swift
//  
//
//  Created by MainasuK on 22/10/18.
//

import os.log
import SwiftUI
import MastodonAsset
import MastodonLocalization
import MastodonSDK

protocol ComposeContentToolbarViewDelegate: AnyObject {
    func composeContentToolbarView(_ viewModel: ComposeContentToolbarView.ViewModel, toolbarItemDidPressed action: ComposeContentToolbarView.ViewModel.Action)
    func composeContentToolbarView(_ viewModel: ComposeContentToolbarView.ViewModel, attachmentMenuDidPressed action: ComposeContentToolbarView.ViewModel.AttachmentAction)
}

struct ComposeContentToolbarView: View {
    
    let logger = Logger(subsystem: "ComposeContentToolbarView", category: "View")
    
    static var toolbarHeight: CGFloat { 48 }
    
    @ObservedObject var viewModel: ViewModel
    
    @State private var showingLanguagePicker = false
    @State private var didChangeLanguage = false
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        HStack(spacing: .zero) {
            ForEach(ComposeContentToolbarView.ViewModel.Action.allCases, id: \.self) { action in
                let basicHandler = {
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(String(describing: action))")
                    viewModel.delegate?.composeContentToolbarView(viewModel, toolbarItemDidPressed: action)
                }

                switch action {
                case .attachment:
                    Menu {
                        ForEach(ComposeContentToolbarView.ViewModel.AttachmentAction.allCases, id: \.self) { attachmentAction in
                            Button {
                                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public), \(attachmentAction.title)")
                                viewModel.delegate?.composeContentToolbarView(viewModel, attachmentMenuDidPressed: attachmentAction)
                            } label: {
                                Label {
                                    Text(attachmentAction.title)
                                } icon: {
                                    Image(uiImage: attachmentAction.image)
                                }
                            }
                        }
                    } label: {
                        ComposeContentToolbarAction(
                            label: L10n.Scene.Compose.Accessibility.appendAttachment,
                            image: Asset.Scene.Compose.media
                        )
                    }
                    .disabled(!viewModel.isAttachmentButtonEnabled)
                case .visibility:
                    Menu {
                        Picker(selection: $viewModel.visibility) {
                            ForEach(viewModel.allVisibilities, id: \.self) { visibility in
                                Label {
                                    Text(visibility.title)
                                } icon: {
                                    visibility.image.swiftUIImage
                                }
                            }
                        } label: {
                            Text(viewModel.visibility.title)
                        }
                    } label: {
                        ComposeContentToolbarAction(
                            label: L10n.Scene.Compose.Keyboard.selectVisibilityEntry(viewModel.visibility.title),
                            image: viewModel.visibility.image
                        )
                    }
                    .disabled(!viewModel.isVisibilityButtonEnabled)
                case .poll:
                    Button(action: basicHandler) {
                        ComposeContentToolbarAction(
                            label: viewModel.isPollActive
                                ? L10n.Scene.Compose.Accessibility.removePoll
                                : L10n.Scene.Compose.Accessibility.appendPoll,
                            image: viewModel.isPollActive
                                ? Asset.Scene.Compose.pollFill
                                : Asset.Scene.Compose.poll
                        )
                    }
                    .disabled(!viewModel.isPollButtonEnabled)
                case .language:
                    Menu {
                        Section {} // workaround a bug where the “Suggested” section doesn’t appear
                        if !viewModel.suggestedLanguages.isEmpty {
                            Section(L10n.Scene.Compose.Language.suggested) {
                                ForEach(viewModel.suggestedLanguages.compactMap(Language.init(id:))) { lang in
                                    Toggle(isOn: languageBinding(for: lang.id)) {
                                        Text(lang.label)
                                    }
                                }
                            }
                        }
                        let recent = viewModel.recentLanguages.filter { !viewModel.suggestedLanguages.contains($0) }
                        if !recent.isEmpty {
                            Section(L10n.Scene.Compose.Language.recent) {
                                ForEach(recent.compactMap(Language.init(id:))) { lang in
                                    Toggle(isOn: languageBinding(for: lang.id)) {
                                        Text(lang.label)
                                    }
                                }
                            }
                        }
                        if !(recent + viewModel.suggestedLanguages).contains(viewModel.language) {
                            Toggle(isOn: languageBinding(for: viewModel.language)) {
                                Text(Language(id: viewModel.language)?.label ?? AttributedString("\(viewModel.language)"))
                            }
                        }
                        Button(L10n.Scene.Compose.Language.other) {
                            showingLanguagePicker = true
                        }
                    } label: {
                        ComposeContentToolbarAction(
                            label: L10n.Scene.Compose.Language.title,
                            icon: LanguagePickerIcon(language: viewModel.language, showBadge: {
                                if let suggested = viewModel.highConfidenceSuggestedLanguage {
                                    return !didChangeLanguage && suggested != viewModel.language
                                }
                                return false
                            }())
                        ).accessibilityValue(Text(Language(id: viewModel.language)?.label ?? AttributedString("\(viewModel.language)")))
                    }
                    .popover(isPresented: $showingLanguagePicker) {
                        let picker = LanguagePicker { newLanguage in
                            viewModel.language = newLanguage
                            didChangeLanguage = true
                            showingLanguagePicker = false
                        }
                        if verticalSizeClass == .regular && horizontalSizeClass == .regular {
                            // explicitly size picker when it’s a popover
                            picker.frame(width: 400, height: 500)
                        } else {
                            picker
                        }
                    }
                
                case .emoji:
                    Button(action: basicHandler) {
                        ComposeContentToolbarAction(
                            label: L10n.Scene.Compose.Accessibility.customEmojiPicker,
                            image: viewModel.isEmojiActive ? Asset.Scene.Compose.emojiFill : Asset.Scene.Compose.emoji
                        )
                    }
                case .contentWarning:
                    Button(action: basicHandler) {
                        ComposeContentToolbarAction(
                            label: viewModel.isContentWarningActive
                                ? L10n.Scene.Compose.Accessibility.disableContentWarning
                                : L10n.Scene.Compose.Accessibility.enableContentWarning,
                            image: viewModel.isContentWarningActive
                                ? Asset.Scene.Compose.chatWarningFill
                                : Asset.Scene.Compose.chatWarning
                        )
                    }
                }
            }.frame(width: 48, height: 48)
            Spacer()
            let count: Int = {
                if viewModel.isContentWarningActive {
                    return viewModel.contentWeightedLength + viewModel.contentWarningWeightedLength
                } else {
                    return viewModel.contentWeightedLength
                }
            }()
            let remains = viewModel.maxTextInputLimit - count
            let isOverflow = remains < 0
            Text("\(remains)")
                .foregroundColor(Color(isOverflow ? UIColor.systemRed : UIColor.secondaryLabel))
                .font(.system(size: isOverflow ? 18 : 16, weight: isOverflow ? .medium : .regular))
                .accessibilityLabel(L10n.A11y.Plural.Count.charactersLeft(remains))
        }
        .padding(.leading, 4)       // 4 + 12 = 16
        .padding(.trailing, 16)
        .frame(height: ComposeContentToolbarView.toolbarHeight)
        .background(Color(viewModel.backgroundColor))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.Scene.Compose.Accessibility.postOptions)
    }
}

extension ComposeContentToolbarView {
    struct LanguagePickerIcon: View {
        let language: String
        let showBadge: Bool

        var body: some View {
            let font: SwiftUI.Font = {
                if #available(iOS 16, *) {
                    return .system(size: 11, weight: .semibold).width(language.count == 3 ? .compressed : .standard)
                } else {
                    return .system(size: 11, weight: .semibold)
                }
            }()
            
            Text(language)
                .font(font)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
                .minimumScaleFactor(0.5)
                .frame(width: 24, height: 24, alignment: .center)
                .overlay { RoundedRectangle(cornerRadius: 7).inset(by: 3).stroke(lineWidth: 1.5) }
                .overlay(alignment: .topTrailing) {
                    Group {
                        if showBadge {
                            Circle().fill(.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .transition(.opacity)
                    .animation(.default, value: showBadge)
                }
                // fixes weird appearance when drawing at low opacity (eg when pressed)
                .drawingGroup()
        }
    }

    private func languageBinding(for code: String) -> Binding<Bool> {
        Binding {
            code == viewModel.language
        } set: { newValue in
            if newValue {
                viewModel.language = code
            }
            didChangeLanguage = true
        }
    }
}

struct ComposeContentToolbarAction<Icon: View>: View {
    let label: String
    let icon: Icon
    
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        icon.foregroundColor(Color(Asset.Scene.Compose.buttonTint.color))
            .frame(width: 24, height: 24, alignment: .center)
            .opacity(isEnabled ? 1 : 0.5)
            .accessibilityLabel(label)
    }
}

extension ComposeContentToolbarAction<Image> {
    init(label: String, image: ImageAsset) {
        self.init(label: label, icon: image.swiftUIImage.renderingMode(.template))
    }
}

extension Mastodon.Entity.Status.Visibility {
    fileprivate var title: String {
        switch self {
        case .public:               return L10n.Scene.Compose.Visibility.public
        case .unlisted:             return L10n.Scene.Compose.Visibility.unlisted
        case .private:              return L10n.Scene.Compose.Visibility.private
        case .direct:               return L10n.Scene.Compose.Visibility.direct
        case ._other(let value):    return value
        }
    }
    
    fileprivate var image: ImageAsset {
        switch self {
        case .public:       return Asset.Scene.Compose.earth
        case .unlisted:     return Asset.Scene.Compose.people
        case .private:      return Asset.Scene.Compose.peopleAdd
        case .direct:       return Asset.Scene.Compose.mention
        case ._other:       return Asset.Scene.Compose.more
        }
    }
}
