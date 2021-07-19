//
//  ComposeView.swift
//
//
//  Created by MainasuK Cirno on 2021-7-16.
//

import UIKit
import SwiftUI

public struct ComposeView: View {

    @EnvironmentObject var viewModel: ComposeViewModel
    @State var statusEditorViewWidth: CGFloat = .zero

    let horizontalMargin: CGFloat = 20

    public init() { }

    public var body: some View {
        GeometryReader { proxy in
            List {
                // Content Warning
                if viewModel.isContentWarningComposing {
                    ContentWarningEditorView(
                        contentWarningContent: $viewModel.contentWarningContent,
                        placeholder: viewModel.contentWarningPlaceholder
                    )
                    .padding(EdgeInsets(top: 6, leading: horizontalMargin, bottom: 6, trailing: horizontalMargin))
                    .background(viewModel.contentWarningBackgroundColor)
                    .transition(.opacity)
                    .listRow()
                }

                // Author
                StatusAuthorView(
                    avatarImageURL: viewModel.avatarImageURL,
                    name: viewModel.authorName,
                    username: viewModel.authorUsername
                )
                .padding(EdgeInsets(top: 20, leading: horizontalMargin, bottom: 16, trailing: horizontalMargin))
                .listRow()

                // Editor
                StatusEditorView(
                    string: $viewModel.statusContent,
                    placeholder: viewModel.statusPlaceholder,
                    width: statusEditorViewWidth,
                    attributedString: viewModel.statusContentAttributedString,
                    keyboardType: .twitter
                )
                .frame(width: statusEditorViewWidth)
                .frame(minHeight: 100)
                .padding(EdgeInsets(top: 0, leading: horizontalMargin, bottom: 0, trailing: horizontalMargin))
                .listRow()

                // Attachments
                ForEach(viewModel.attachmentViewModels) { viewModel in
                    StatusAttachmentView(
                        image: viewModel.thumbnailImage,
                        removeButtonAction: {
                            self.viewModel.removeAttachmentViewModel(viewModel)
                        }
                    )
                }
                .padding(EdgeInsets(top: 16, leading: horizontalMargin, bottom: 0, trailing: horizontalMargin))
                .fixedSize(horizontal: false, vertical: true)
                .listRow()

                // bottom padding
                Color.clear
                    .frame(height: viewModel.toolbarHeight + 20)
                    .listRow()
            }   // end List
            .introspectTableView(customize: { tableView in
                tableView.keyboardDismissMode = .onDrag
                tableView.verticalScrollIndicatorInsets.bottom = viewModel.toolbarHeight
            })
            .preference(
                key: ComposeListViewFramePreferenceKey.self,
                value: proxy.frame(in: .local)
            )
            .onPreferenceChange(ComposeListViewFramePreferenceKey.self) { frame in
                var frame = frame
                frame.size.width = frame.width - 2 * horizontalMargin
                statusEditorViewWidth = frame.width
            }
        }
    }
}

struct ComposeListViewFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { }
}

extension View {
    func listRow() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .listRowInsets(EdgeInsets(top: -1, leading: -1, bottom: -1, trailing: -1))
            .background(Color(.systemBackground))
    }
}


struct ComposeView_Previews: PreviewProvider {

    static let viewModel: ComposeViewModel = {
        let viewModel = ComposeViewModel()
        return viewModel
    }()

    static var previews: some View {
        ComposeView().environmentObject(viewModel)
    }
    
}
