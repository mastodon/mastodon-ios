//
//  AttachmentView.swift
//  
//
//  Created by MainasuK on 2022-5-20.
//

import os.log
import UIKit
import SwiftUI
import Introspect
import AVKit

public struct AttachmentView: View {
    
    @ObservedObject var viewModel: AttachmentViewModel
    
    let action: (Action) -> Void

    public var body: some View {
        ZStack {
            let image = viewModel.thumbnail ?? .placeholder(color: .secondarySystemFill)
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
//        Menu {
//            menu
//        } label: {
//            let image = viewModel.thumbnail ?? .placeholder(color: .systemGray3)
//            Image(uiImage: image)
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .frame(width: AttachmentView.size.width, height: AttachmentView.size.height)
//                .overlay {
//                    ZStack {
//                        // spinner
//                        if viewModel.output == nil {
//                            Color.clear
//                                .background(.ultraThinMaterial)
//                            ProgressView()
//                                .progressViewStyle(CircularProgressViewStyle())
//                                .foregroundStyle(.regularMaterial)
//                        }
//                        // border
//                        RoundedRectangle(cornerRadius: AttachmentView.cornerRadius)
//                            .stroke(Color.black.opacity(0.05))
//                    }
//                    .transition(.opacity)
//                }
//                .overlay(alignment: .bottom) {
//                    HStack(alignment: .bottom) {
//                        // alt
//                        VStack(spacing: 2) {
//                            switch viewModel.output {
//                            case .video:
//                                Image(uiImage: Asset.Media.playerRectangle.image)
//                                    .resizable()
//                                    .frame(width: 16, height: 12)
//                            default:
//                                EmptyView()
//                            }
//                            if !viewModel.caption.isEmpty {
//                                Image(uiImage: Asset.Media.altRectangle.image)
//                                    .resizable()
//                                    .frame(width: 16, height: 12)
//                            }
//                        }
//                        Spacer()
//                        // option
//                        Image(systemName: "ellipsis")
//                            .resizable()
//                            .frame(width: 12, height: 12)
//                            .symbolVariant(.circle)
//                            .symbolVariant(.fill)
//                            .symbolRenderingMode(.palette)
//                            .foregroundStyle(.white, .black)
//                    }
//                    .padding(6)
//                }
//                .cornerRadius(AttachmentView.cornerRadius)
//        }   // end Menu
//        .sheet(isPresented: $isCaptionEditorPresented) {
//            captionSheet
//        }   // end caption sheet
//        .sheet(isPresented: $viewModel.isPreviewPresented) {
//            previewSheet
//        }   // end preview sheet

    }   // end body
    
//    var menu: some View {
//        Group {
//            Button(
//                action: {
//                    action(.preview)
//                },
//                label: {
//                    Label(L10n.Scene.Compose.Media.preview, systemImage: "photo")
//                }
//            )
//            // caption
//            let canAddCaption: Bool = {
//                switch viewModel.output {
//                case .image:        return true
//                case .video:        return false
//                case .none:         return false
//                }
//            }()
//            if canAddCaption {
//                Button(
//                    action: {
//                        action(.caption)
//                        caption = viewModel.caption
//                        isCaptionEditorPresented.toggle()
//                    },
//                    label: {
//                        let title = viewModel.caption.isEmpty ? L10n.Scene.Compose.Media.Caption.add : L10n.Scene.Compose.Media.Caption.update
//                        Label(title, systemImage: "text.bubble")
//                        // FIXME: https://stackoverflow.com/questions/72318730/how-to-customize-swiftui-menu
//                        // add caption subtitle
//                    }
//                )
//            }
//            Divider()
//            // remove
//            Button(
//                role: .destructive,
//                action: {
//                    action(.remove)
//                },
//                label: {
//                    Label(L10n.Scene.Compose.Media.remove, systemImage: "minus.circle")
//                }
//            )
//        }
//    }
    
//    var captionSheet: some View {
//        NavigationView {
//            ScrollView(.vertical) {
//                VStack {
//                    // preview
//                    switch viewModel.output {
//                    case .image:
//                        let image = viewModel.thumbnail ?? .placeholder(color: .systemGray3)
//                        Image(uiImage: image)
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                    case .video(let url, _):
//                        let player = AVPlayer(url: url)
//                        VideoPlayer(player: player)
//                            .frame(height: 300)
//                    case .none:
//                        EmptyView()
//                    }
//                    // caption textField
//                    TextField(
//                        text: $caption,
//                        prompt: Text(L10n.Scene.Compose.Media.Caption.addADescriptionForThisImage)
//                    ) {
//                        Text(L10n.Scene.Compose.Media.Caption.update)
//                    }
//                    .padding()
//                    .introspectTextField { textField in
//                        textField.becomeFirstResponder()
//                    }
//                }
//            }
//            .navigationTitle(L10n.Scene.Compose.Media.Caption.update)
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button {
//                        isCaptionEditorPresented.toggle()
//                    } label: {
//                        Image(systemName: "xmark.circle.fill")
//                            .resizable()
//                            .frame(width: 30, height: 30, alignment: .center)
//                            .symbolRenderingMode(.hierarchical)
//                            .foregroundStyle(Color(uiColor: .secondaryLabel), Color(uiColor: .tertiaryLabel))
//                    }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button {
//                        viewModel.caption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
//                        isCaptionEditorPresented.toggle()
//                    } label: {
//                        Text(L10n.Common.Controls.Actions.save)
//                    }
//                }
//            }
//        }   // end NavigationView
//    }
    
    // design for share extension
    // preferred UIKit preview in app
//    var previewSheet: some View {
//        NavigationView {
//            ScrollView(.vertical) {
//                VStack {
//                    // preview
//                    switch viewModel.output {
//                    case .image:
//                        let image = viewModel.thumbnail ?? .placeholder(color: .systemGray3)
//                        Image(uiImage: image)
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                    case .video(let url, _):
//                        let player = AVPlayer(url: url)
//                        VideoPlayer(player: player)
//                            .frame(height: 300)
//                    case .none:
//                        EmptyView()
//                    }
//                    Spacer()
//                }
//            }
//            .navigationTitle(L10n.Scene.Compose.Media.preview)
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button {
//                        viewModel.isPreviewPresented.toggle()
//                    } label: {
//                        Image(systemName: "xmark.circle.fill")
//                            .resizable()
//                            .frame(width: 30, height: 30, alignment: .center)
//                            .symbolRenderingMode(.hierarchical)
//                            .foregroundStyle(Color(uiColor: .secondaryLabel), Color(uiColor: .tertiaryLabel))
//                    }
//                }
//            }
//        }   // end NavigationView
//    }
    
}

extension AttachmentView {
    public enum Action: Hashable {
        case preview
        case caption
        case remove
    }
}
