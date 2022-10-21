//
//  ComposeContentView.swift
//  
//
//  Created by MainasuK on 22/9/30.
//

import os.log
import SwiftUI
import MastodonCore
import MastodonLocalization

public struct ComposeContentView: View {
    
    static let logger = Logger(subsystem: "ComposeContentView", category: "View")
    var logger: Logger { ComposeContentView.logger }
    
    static var margin: CGFloat = 16
    
    @ObservedObject var viewModel: ComposeContentViewModel

    public var body: some View {
        VStack(spacing: .zero) {
            Group {
                // author
                authorView
                    .padding(.top, 14)
                // content editor
                MetaTextViewRepresentable(
                    string: $viewModel.content,
                    width: viewModel.viewLayoutFrame.layoutFrame.width - ComposeContentView.margin * 2,
                    configurationHandler: { metaText in
                        metaText.textView.attributedPlaceholder = {
                            var attributes = metaText.textAttributes
                            attributes[.foregroundColor] = UIColor.secondaryLabel
                            return NSAttributedString(
                                string: L10n.Scene.Compose.contentInputPlaceholder,
                                attributes: attributes
                            )
                        }()
                        metaText.textView.keyboardType = .twitter
                        // metaText.textView.tag = ComposeContentViewModel.MetaTextViewKind.content.rawValue
                        // metaText.textView.delegate = viewModel
                        // metaText.delegate = viewModel
                        metaText.textView.becomeFirstResponder()
                    }
                )
                .frame(minHeight: 100)
                .fixedSize(horizontal: false, vertical: true)
                // poll
                pollView
            }
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: ViewFramePreferenceKey.self, value: proxy.frame(in: .local))
                }
                .onPreferenceChange(ViewFramePreferenceKey.self) { frame in
                    logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): content frame: \(frame.debugDescription)")
                    viewModel.contentCellFrame = frame
                }
            )
            Spacer()
        }   // end VStack
        .padding(.horizontal, ComposeContentView.margin)
//        .frame(alignment: .top)
    }   // end body
}

extension ComposeContentView {
    var authorView: some View {
        HStack(spacing: 8) {
            AnimatedImage(imageURL: viewModel.avatarURL)
                .frame(width: 46, height: 46)
                .background(Color(UIColor.systemFill))
                .cornerRadius(12)
            VStack(alignment: .leading, spacing: 4) {
                Spacer()
                MetaLabelRepresentable(
                    textStyle: .statusName,
                    metaContent: viewModel.name
                )
                Text(viewModel.username)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            Spacer()
        }
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
                    let _index = viewModel.pollOptions.firstIndex(of: pollOption)
                    PollOptionRow(
                        viewModel: pollOption,
                        index: _index,
                        deleteBackwardResponseTextFieldRelayDelegate: viewModel
                    ) { textField in
                        // viewModel.customEmojiPickerInputViewModel.configure(textInput: textField)
                    }
                }
            }
            VStack(spacing: .zero) {
                // expire configuration
                Menu {
                    ForEach(PollComposeItem.ExpireConfiguration.Option.allCases, id: \.self) { option in
                        Button {
                            // viewModel.pollExpireConfiguration.option = option
                            // viewModel.pollExpireConfiguration = viewModel.pollExpireConfiguration
                        } label: {
                            Text(option.title)
                        }
                    }
                } label: {
                    HStack {
//                        VectorImageView(
//                            image: Asset.ObjectTools.clock.image.withRenderingMode(.alwaysTemplate),
//                            tintColor: .secondaryLabel
//                        )
//                        .frame(width: 24, height: 24)
//                        .padding(.vertical, 12)
//                        let text = viewModel.pollExpireConfigurationFormatter.string(from: TimeInterval(viewModel.pollExpireConfiguration.option.seconds)) ?? "-"
//                        Text(text)
//                            .font(.callout)
//                            .foregroundColor(.primary)
//                        Spacer()
//                        VectorImageView(
//                            image: Asset.Arrows.tablerChevronDown.image.withRenderingMode(.alwaysTemplate),
//                            tintColor: .secondaryLabel
//                        )
//                        .frame(width: 24, height: 24)
//                        .padding(.vertical, 12)
                    }
                }
                // multi-selection configuration
//                Button {
//                    viewModel.pollMultipleConfiguration.isMultiple.toggle()
//                    viewModel.pollMultipleConfiguration = viewModel.pollMultipleConfiguration
//                } label: {
//                    HStack {
//                        let selectionImage = viewModel.pollMultipleConfiguration.isMultiple ? Asset.Indices.checkmarkSquare.image.withRenderingMode(.alwaysTemplate) : Asset.Indices.square.image.withRenderingMode(.alwaysTemplate)
//                        VectorImageView(
//                            image: selectionImage,
//                            tintColor: .secondaryLabel
//                        )
//                        .frame(width: 24, height: 24)
//                        .padding(.vertical, 12)
//                        Text(L10n.Scene.Compose.Vote.multiple)
//                            .font(.callout)
//                            .foregroundColor(.primary)
//                        Spacer()
//                    }
//                }
            }
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
