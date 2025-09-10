//
//  ComposeContentView.swift
//  
//
//  Created by MainasuK on 22/9/30.
//

import SwiftUI
import MastodonAsset
import MastodonSDK
import MastodonCore
import MastodonLocalization
import Stripes

public struct ComposeContentView: View {
    
    static let contentViewCoordinateSpace = "ComposeContentView.Content"
    static var margin: CGFloat = 16
    
    @ObservedObject var viewModel: ComposeContentViewModel
    @State private var isPresentingInteractionSettings = false
    @State private var visibilitySelection: Mastodon.Entity.Status.Visibility
    @State private var quotabilitySelection: Mastodon.Entity.Source.QuotePolicy
    private func updateVisibilitySelection(_ newValue: Mastodon.Entity.Status.Visibility) {
        viewModel.setInteractionSettings(visibility: visibilitySelection, quotability: nil)
        if quotabilitySelection != viewModel.interactionSettings.quotability {
            quotabilitySelection = viewModel.interactionSettings.quotability
        }
    }
    private func updateQuotabilitySelection(_ newValue: Mastodon.Entity.Source.QuotePolicy) {
        viewModel.setInteractionSettings(visibility: nil, quotability: quotabilitySelection)
    }
    
    init(viewModel: ComposeContentViewModel) {
        self.viewModel = viewModel
        self.visibilitySelection = viewModel.interactionSettings.visibility
        self.quotabilitySelection = viewModel.interactionSettings.quotability
    }

    public var body: some View {
        VStack(spacing: .zero) {
            Group {
                Spacer()
                    .frame(height: 13)
                
                // visibility and quotability
                HStack {
                    if AuthenticationServiceProvider.shared.currentInstanceConfiguration?.isAvailable(.quotePosts) == true {
                        interactionSettingsButton
                            .fixedSize(horizontal: true, vertical: false)
                        Spacer().frame(maxWidth: .infinity)
                    } else {
                        Spacer().frame(maxWidth: .infinity)
                        visibilityPicker()
                    }
                }
                .padding(.horizontal, ComposeContentView.margin)
                
                Spacer()
                    .frame(height: ComposeContentView.margin)
                
                // content warning
                if viewModel.isContentWarningActive {
                    MetaTextViewRepresentable(
                        string: $viewModel.contentWarning,
                        width: viewModel.viewLayoutFrame.layoutFrame.width - ComposeContentView.margin * 2,
                        configurationHandler: { metaText in
                            viewModel.contentWarningMetaText = metaText
                            metaText.textView.attributedPlaceholder = {
                                var attributes = metaText.textAttributes
                                attributes[.foregroundColor] = UIColor.secondaryLabel
                                return NSAttributedString(
                                    string: L10n.Scene.Compose.contentInputPlaceholder,
                                    attributes: attributes
                                )
                            }()
                            metaText.textView.returnKeyType = .next
                            metaText.textView.tag = ComposeContentViewModel.MetaTextViewKind.contentWarning.rawValue
                            metaText.textView.delegate = viewModel
                            metaText.delegate = viewModel
                        }
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, ComposeContentView.margin)
                    .background(
                        Color(UIColor.systemBackground)
                            .overlay(
                                HStack {
                                    Stripes(config: StripesConfig(
                                        background: Color.yellow,
                                        foreground: Color.black,
                                        degrees: 45,
                                        barWidth: 2.5,
                                        barSpacing: 3.5
                                    ))
                                    .frame(width: ComposeContentView.margin * 0.5)
                                    .frame(maxHeight: .infinity)
                                    .id(UUID())
                                    Spacer()
                                    Stripes(config: StripesConfig(
                                        background: Color.yellow,
                                        foreground: Color.black,
                                        degrees: 45,
                                        barWidth: 2.5,
                                        barSpacing: 3.5
                                    ))
                                    .frame(width: ComposeContentView.margin * 0.5)
                                    .frame(maxHeight: .infinity)
                                    .scaleEffect(x: -1, y: 1, anchor: .center)
                                    .id(UUID())
                                }
                            )
                    )
                } // end if viewModel.isContentWarningActive
                // author
                authorView
                    .padding(.horizontal, ComposeContentView.margin)
                // content editor
                MetaTextViewRepresentable(
                    string: $viewModel.content,
                    width: viewModel.viewLayoutFrame.layoutFrame.width - ComposeContentView.margin * 2,
                    configurationHandler: { metaText in
                        viewModel.contentMetaText = metaText
                        metaText.textView.attributedPlaceholder = {
                            var attributes = metaText.textAttributes
                            attributes[.foregroundColor] = UIColor.secondaryLabel
                            return NSAttributedString(
                                string: L10n.Scene.Compose.contentInputPlaceholder,
                                attributes: attributes
                            )
                        }()
                        metaText.textView.tag = ComposeContentViewModel.MetaTextViewKind.content.rawValue
                        metaText.textView.delegate = viewModel
                        metaText.delegate = viewModel
                        metaText.textView.becomeFirstResponder()
                    }
                )
                .frame(minHeight: 100)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, ComposeContentView.margin)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: ViewFramePreferenceKey.self, value: proxy.frame(in: .named(ComposeContentView.contentViewCoordinateSpace)))
                    }
                    .onPreferenceChange(ViewFramePreferenceKey.self) { frame in
                        let rect = frame.standardized
                        viewModel.contentTextViewFrame = CGRect(
                            origin: frame.origin,
                            size: CGSize(width: floor(rect.width), height: floor(rect.height))
                        )
                    }
                )
                // poll
                pollView
                    .padding(.horizontal, ComposeContentView.margin)
                // media
                mediaView
                    .padding(.horizontal, ComposeContentView.margin)
            }
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: ViewFramePreferenceKey.self, value: proxy.frame(in: .local))
                }
                .onPreferenceChange(ViewFramePreferenceKey.self) { frame in
                    let rect = frame.standardized
                    viewModel.contentCellFrame = CGRect(
                        origin: frame.origin,
                        size: CGSize(width: floor(rect.width), height: floor(rect.height))
                    )
                }
            )
            Spacer()
        }   // end VStack
        .coordinateSpace(name: ComposeContentView.contentViewCoordinateSpace)
        .sheet(isPresented: $isPresentingInteractionSettings) {
            interactionSettingsView
                .presentationDetents([.fraction(0.3), .medium, .large])
                .presentationDragIndicator(.visible)
                .onAppear() {
                    viewModel.previousInteractionSettings = viewModel.interactionSettings
                }
                .onDisappear() {
                    viewModel.previousInteractionSettings = nil
                }
        }
        
    }   // end body
    
    @ViewBuilder
    var interactionSettingsButton: some View {
        Button() {
            isPresentingInteractionSettings = true
        } label: {
            HStack {
                Text(Image(uiImage: viewModel.interactionSettings.visibility.image))
                Text(viewModel.interactionSettingsButtonText)
            }
            .font(.subheadline)
            .foregroundStyle(Asset.Colors.Brand.darkBlurple.swiftUIColor)
            .padding(EdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14))
            .background() {
                Capsule()
                    .fill(Asset.Colors.Brand.lightBlurple.swiftUIColor).opacity(0.15)
                // intended: #007AFF26
            }
        }
    }
    
    @ViewBuilder
    func visibilityPicker() -> some View {
        Picker(selection: $viewModel.interactionSettings.visibility) {
            ForEach([Mastodon.Entity.Status.Visibility.public, .unlisted, .private, .direct], id: \.self) { visibility in
                Label {
                    Text(visibility.title)
                } icon: {
                    Image(uiImage: visibility.image)
                }
            }
        } label: {
            Text(viewModel.interactionSettings.visibility.title)
        }.disabled(!viewModel.canEditVisibility)
    }
    
    @ViewBuilder
    func validatingVisibilityPicker() -> some View {
        Picker(selection: $visibilitySelection) {
            ForEach([Mastodon.Entity.Status.Visibility.public, .unlisted, .private, .direct], id: \.self) { visibility in
                Text(visibility.title)
            }
        } label: {
            Text(viewModel.interactionSettings.visibility.title)
        }
        .disabled(!viewModel.canEditVisibility)
        .tint(.secondary)
        .onChange(of: visibilitySelection) { newValue in
            updateVisibilitySelection(newValue)
        }
    }
    
    @ViewBuilder
    func quotabilityPicker(_ options: [Mastodon.Entity.Source.QuotePolicy]) -> some View {
        Picker(selection: $quotabilitySelection) {
            ForEach(options, id: \.self) { quotability in
                Label {
                    Text(quotability.title)
                } icon: {
                    EmptyView()
                }
            }
        } label: {
            Text(viewModel.interactionSettings.quotability.title)
        }
        .disabled(options.count < 2)
        .tint(.secondary)
        .onChange(of: quotabilitySelection) { newValue in
            updateQuotabilitySelection(newValue)
        }
    }
    
    @ViewBuilder
    var interactionSettingsView: some View {
        ScrollView {
            VStack {
                
                // header and buttons
                HStack {
                    Button(L10n.Common.Controls.Actions.cancel, role: .cancel) {
                        if let restoreSettings = viewModel.previousInteractionSettings {
                            viewModel.interactionSettings = restoreSettings
                        }
                        isPresentingInteractionSettings = false
                    }
                    .tint(.blue)
                    Spacer()
                    Text(L10n.Scene.Compose.VisibilityAndQuotability.title)
                        .fontWeight(.semibold)
                    Spacer()
                    Button(L10n.Common.Controls.Actions.save, role: .none) {
                        isPresentingInteractionSettings = false
                    }
                    .fontWeight(.semibold)
                    .tint(.blue)
                }
                Spacer()
                    .frame(height: 4)
                Text(L10n.Scene.Compose.VisibilityAndQuotability.subtitle)
                    .font(.caption)
                
                Spacer()
                
                // visibility
                HStack {
                    Text(L10n.Scene.Compose.Visibility.title)
                    Spacer()
                    validatingVisibilityPicker()
                }
                .padding(19)
                .background {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white)
                }
                
                Spacer()
                
                // quotability
                HStack {
                    Text(L10n.Scene.Compose.QuotePermissionPolicy.title)
                    Spacer()
                    quotabilityPicker(visibilitySelection.allowableQuotePolicies)
                }
                .padding(19)
                .background {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white)
                }
            }
        }
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
        .background(Color(.secondarySystemBackground))
        .ignoresSafeArea(edges: .bottom)
        .onAppear() {
            visibilitySelection = viewModel.interactionSettings.visibility
            quotabilitySelection = viewModel.interactionSettings.quotability
        }
    }
}

extension Mastodon.Entity.Source.QuotePolicy {
    var title: String {
        switch self {
        case .anyone:
            L10n.Scene.Compose.QuotePermissionPolicy.anyone
        case .followers:
            L10n.Scene.Compose.QuotePermissionPolicy.followers
        case .nobody:
            L10n.Scene.Compose.QuotePermissionPolicy.onlyMe
        case ._other(let string):
            string
        }
    }
}

extension ComposeContentView {
    var authorView: some View {
        HStack(alignment: .top, spacing: 8) {
            AnimatedImage(imageURL: viewModel.avatarURL)
                .frame(width: 46, height: 46)
                .background(Color(UIColor.systemFill))
                .cornerRadius(12)
            VStack(alignment: .leading, spacing: 0) {
                MetaLabelRepresentable(
                    textStyle: .statusName,
                    metaContent: viewModel.name
                )
                Text(viewModel.username)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                Spacer()
            }
            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.Scene.Compose.Accessibility.postingAs([viewModel.name.string, viewModel.username].joined(separator: ", ")))
    }
}

extension ComposeContentView {
    // MARK: - poll
    var pollView: some View {
        VStack {
            if viewModel.isPollActive {
                // poll option TextField
                ReorderableForEach(
                    items: $viewModel.pollOptions
                ) { $pollOption in
                    if let _index = viewModel.pollOptions.firstIndex(of: pollOption) {
                        PollOptionRow(
                            viewModel: pollOption,
                            index: _index,
                            moveUp: _index == 0 ? nil : {
                                viewModel.pollOptions.swapAt(_index, _index - 1)
                            },
                            moveDown: _index == viewModel.pollOptions.count - 1 ? nil : {
                                viewModel.pollOptions.swapAt(_index, _index + 1)
                            },
                            removeOption: viewModel.pollOptions.count <= 2 ? nil : {
                                viewModel.pollOptions.remove(at: _index)
                            },
                            deleteBackwardResponseTextFieldRelayDelegate: viewModel
                        ) { textField in
                            viewModel.customEmojiPickerInputViewModel.configure(textInput: textField)
                        }
                    }
                }
                if viewModel.maxPollOptionLimit != viewModel.pollOptions.count {
                    Button(action: viewModel.createNewPollOptionIfCould) {
                        PollAddOptionRow()
                            .accessibilityLabel(L10n.Scene.Compose.Poll.addOption)
                    }
                }
                Menu {
                    Picker(selection: $viewModel.pollExpireConfigurationOption) {
                        ForEach(PollComposeItem.ExpireConfiguration.Option.allCases, id: \.self) { option in
                            Text(option.title)
                        }
                    } label: {
                        Text(L10n.Scene.Compose.Poll.durationTime(viewModel.pollExpireConfigurationOption.title))
                    }
                } label: {
                    HStack {
                        Text(L10n.Scene.Compose.Poll.durationTime(viewModel.pollExpireConfigurationOption.title))
                            .foregroundColor(Color(UIColor.label.withAlphaComponent(0.8)))  // Gray/800
                            .font(Font(UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 13, weight: .semibold))))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }   // end VStack
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.Scene.Compose.Poll.title)
    }
    
    // MARK: - media
    var mediaView: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.attachmentViewModels, id: \.self) { attachmentViewModel in
                AttachmentView(viewModel: attachmentViewModel)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .badgeView(
                        Button {
                            viewModel.attachmentViewModels.removeAll(where: { $0 === attachmentViewModel })
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.red)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    )
            }   // end ForEach
        }   // end VStack
    }
}

//private struct ScrollOffsetPreferenceKey: PreferenceKey {
//    static var defaultValue: CGPoint = .zero
//
//    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
//}

private struct ViewFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { }
}

// MARK: - TypeIdentifiedItemProvider
extension PollComposeItem.Option: TypeIdentifiedItemProvider {
    public static var typeIdentifier: String {
        return Bundle(for: PollComposeItem.Option.self).bundleIdentifier! + String(describing: type(of: PollComposeItem.Option.self))
    }
}

// MARK: - NSItemProviderWriting
extension PollComposeItem.Option: NSItemProviderWriting {
    public func loadData(
        withTypeIdentifier typeIdentifier: String,
        forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void
    ) -> Progress? {
        completionHandler(nil, nil)
        return nil
    }
    
    public static var writableTypeIdentifiersForItemProvider: [String] {
        return [Self.typeIdentifier]
    }
}
