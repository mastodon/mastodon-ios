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
    @Environment(PostInteractionSettingsViewModel.self) private var interactionSettingsViewModel
    
    init(viewModel: ComposeContentViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: .zero) {
            Group {
                Spacer()
                    .frame(height: 13)
                
                // visibility and quotability
                HStack {
                    if AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication.instanceConfiguration?.isAvailable(.quotePosts) == true {
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
                // quoted post
                if let quotedPostViewBuilder = viewModel.composeContext.quotingViewBuilder {
                    quotedPostViewBuilder()
                        .padding()
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel(L10n.Common.Controls.Status.Quote.a11yLabel)
                }
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
        }
        
    }   // end body
    
    @ViewBuilder
    var interactionSettingsButton: some View {
        Button() {
            isPresentingInteractionSettings = true
        } label: {
            HStack {
                Text(Image(uiImage: interactionSettingsViewModel.interactionSettings.visibility.image))
                    .accessibilityHidden(true)
                Text(viewModel.interactionSettingsButtonText(interactionSettingsViewModel.interactionSettings))
            }
            .font(.subheadline)
            .foregroundStyle(Asset.Colors.accent.swiftUIColor)
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
        Picker(selection: Binding<Mastodon.Entity.Status.Visibility>(
            get: {
                interactionSettingsViewModel.interactionSettings.visibility
            },
            set: { newValue in
                interactionSettingsViewModel.setInteractionSettings(visibility: newValue, quotability: nil)
            }
        )) {
            ForEach([Mastodon.Entity.Status.Visibility.public, .unlisted, .private, .direct], id: \.self) { visibility in
                Label {
                    Text(visibility.title)
                } icon: {
                    Image(uiImage: visibility.image)
                }
            }
        } label: {
            Text(interactionSettingsViewModel.interactionSettings.visibility.title)
        }.disabled(!interactionSettingsViewModel.canEditVisibility)
    }
    
    @ViewBuilder
    var interactionSettingsView: some View {
        PostInteractionSettingsView(closeAndSave: { shouldSave in
            if shouldSave {
                // already set, nothing to do until posting
            } else {
                if let restoreSettings = viewModel.previousInteractionSettings {
                    interactionSettingsViewModel.setInteractionSettings(visibility: restoreSettings.visibility, quotability: restoreSettings.quotability)
                }
            }
            viewModel.previousInteractionSettings = nil
            isPresentingInteractionSettings = false
        })
        .onAppear() {
            viewModel.previousInteractionSettings = interactionSettingsViewModel.interactionSettings
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
