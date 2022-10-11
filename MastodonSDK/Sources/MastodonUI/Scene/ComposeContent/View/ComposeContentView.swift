//
//  ComposeContentView.swift
//  
//
//  Created by MainasuK on 22/9/30.
//

import os.log
import SwiftUI
import MastodonLocalization

public struct ComposeContentView: View {
    
    static let logger = Logger(subsystem: "ComposeContentView", category: "View")
    var logger: Logger { ComposeContentView.logger }
    
    static var margin: CGFloat = 16
    
    @ObservedObject var viewModel: ComposeContentViewModel

    public var body: some View {
        VStack(spacing: .zero) {
            Group {
                authorView
                    .padding(.top, 14)
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

//private struct ScrollOffsetPreferenceKey: PreferenceKey {
//    static var defaultValue: CGPoint = .zero
//
//    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
//}

private struct ViewFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { }
}
