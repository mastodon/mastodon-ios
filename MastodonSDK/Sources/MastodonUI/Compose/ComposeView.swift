//
//  ComposeView.swift
//
//
//  Created by MainasuK Cirno on 2021-7-16.
//

import SwiftUI

public struct ComposeView: View {

    @EnvironmentObject public var viewModel: ComposeViewModel

    public init() { }

    public var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical) {
                StatusAuthorView(
                    avatarImageURL: viewModel.avatarImageURL,
                    name: viewModel.authorName,
                    username: viewModel.authorUsername
                )
                TextEditorView(
                    string: $viewModel.statusContent,
                    width: viewModel.frame.width,
                    attributedString: viewModel.statusContentAttributedString
                )
                .frame(width: viewModel.frame.width)
                .frame(minHeight: 100)
                ForEach(viewModel.attachments, id: \.self) { image in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(16.0/9.0, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .cornerRadius(4)
                }
            }   // end ScrollView
            .preference(
                key: ComposeViewFramePreferenceKey.self,
                value: proxy.frame(in: .local)
            )
            .onPreferenceChange(ComposeViewFramePreferenceKey.self) { frame in
                viewModel.frame = frame
                print(frame)
            }
        }
    }
}

struct ComposeViewFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { }
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
