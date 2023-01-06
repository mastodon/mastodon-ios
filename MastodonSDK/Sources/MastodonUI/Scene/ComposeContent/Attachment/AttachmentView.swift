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
import MastodonAsset
import MastodonLocalization
import Introspect

public struct AttachmentView: View {
    
    @ObservedObject var viewModel: AttachmentViewModel
    
    @State private var isEditingDescription = false

    var blurEffect: UIBlurEffect {
        UIBlurEffect(style: .systemUltraThinMaterialDark)
    }

    public var body: some View {
        let thumbnail = viewModel.thumbnail ?? .placeholder(color: .secondarySystemFill)
        Color.clear.aspectRatio(358.0/232.0, contentMode: .fill)
            .overlay(
                ZStack {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                }
            )
            .overlay(
                ZStack {
                    Color.clear
                        .overlay(
                            VStack(alignment: .leading) {
                                let placeholder: String = {
                                    switch viewModel.output {
                                    case .image: return L10n.Scene.Compose.Attachment.descriptionPhoto
                                    case .video: return L10n.Scene.Compose.Attachment.descriptionVideo
                                    case nil:    return ""
                                    }
                                }()
                                Spacer()
                                ZStack(alignment: .bottomLeading) {
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.black.opacity(0.0), .black.opacity(1.0)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(height: 80)
                                    
                                    Button {
                                        isEditingDescription = true
                                    } label: {
                                        Label(viewModel.caption.isEmpty ? placeholder : viewModel.caption, systemImage: "pencil")
                                            .lineLimit(1)
                                            .font(.footnote)
                                            .foregroundColor(.white.opacity(0.8))
                                            .padding(EdgeInsets(top: 6, leading: 8, bottom: 10, trailing: 4))
                                    }
                                }.sheet(isPresented: $isEditingDescription) {
                                    AttachmentDescriptionComposerView(
                                        prompt: placeholder,
                                        thumbnail: thumbnail,
                                        description: $viewModel.caption
                                    )
                                }
                            }
                        )
                    
                    // loading…
                    if viewModel.output == nil, viewModel.error == nil {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    
                    // load failed
                    // cannot re-entry
                    if viewModel.output == nil, let error = viewModel.error {
                        VisualEffectView(effect: blurEffect)
                        VStack {
                            Text(L10n.Scene.Compose.Attachment.loadFailed)
                                .font(.system(size: 13, weight: .semibold))
                            Text(error.localizedDescription)
                                .font(.system(size: 12, weight: .regular))
                        }
                    }
                    
                    // loaded
                    // uploading… or upload failed
                    // could retry upload when error emit
                    if viewModel.output != nil, viewModel.uploadState != .finish {
                        VisualEffectView(effect: blurEffect)
                        VStack {
                            let action: AttachmentViewModel.Action = {
                                if let _ = viewModel.error {
                                    return .retry
                                } else {
                                    return .remove
                                }
                            }()
                            Button {
                                viewModel.delegate?.attachmentViewModel(viewModel, actionButtonDidPressed: action)
                            } label: {
                                let image: UIImage = {
                                    switch action {
                                    case .remove:
                                        return Asset.Scene.Compose.Attachment.stop.image.withRenderingMode(.alwaysTemplate)
                                    case .retry:
                                        return Asset.Scene.Compose.Attachment.retry.image.withRenderingMode(.alwaysTemplate)
                                    }
                                }()
                                Image(uiImage: image)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color(Asset.Scene.Compose.Attachment.indicatorButtonBackground.color))
                                    .overlay(
                                        Group {
                                            switch viewModel.uploadState {
                                            case .compressing:
                                                CircleProgressView(progress: viewModel.videoCompressProgress)
                                                    .animation(.default, value: viewModel.videoCompressProgress)
                                            case .uploading:
                                                CircleProgressView(progress: viewModel.fractionCompleted)
                                                    .animation(.default, value: viewModel.fractionCompleted)
                                            default:
                                                EmptyView()
                                            }
                                        }
                                    )
                                    .clipShape(Circle())
                                    .padding()
                            }
                            
                            let title: String = {
                                switch action {
                                case .remove:
                                    switch viewModel.uploadState {
                                    case .compressing:
                                        return L10n.Scene.Compose.Attachment.compressingState
                                    default:
                                        if viewModel.fractionCompleted < 0.9 {
                                            let totalSizeInByte = viewModel.outputSizeInByte
                                            let uploadSizeInByte = Double(totalSizeInByte) * min(1.0, viewModel.fractionCompleted + 0.1)    // 9:1
                                            let total = viewModel.byteCountFormatter.string(fromByteCount: Int64(totalSizeInByte))
                                            let upload = viewModel.byteCountFormatter.string(fromByteCount: Int64(uploadSizeInByte))
                                            return "\(upload) / \(total)"
                                        } else {
                                            return L10n.Scene.Compose.Attachment.serverProcessingState
                                        }
                                    }
                                case .retry:
                                    return L10n.Scene.Compose.Attachment.uploadFailed
                                }
                            }()
                            let subtitle: String = {
                                switch action {
                                case .remove:
                                    if viewModel.progress.fractionCompleted < 1, viewModel.uploadState == .uploading {
                                        if viewModel.progress.fractionCompleted < 0.9 {
                                            return viewModel.remainTimeLocalizedString ?? ""
                                        } else {
                                            return ""
                                        }
                                    } else if viewModel.videoCompressProgress < 1, viewModel.uploadState == .compressing {
                                        return viewModel.percentageFormatter.string(from: NSNumber(floatLiteral: viewModel.videoCompressProgress)) ?? ""
                                    } else {
                                        return ""
                                    }
                                case .retry:
                                    return viewModel.error?.localizedDescription ?? ""
                                }
                            }()
                            Text(title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            Text(subtitle)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .lineLimit(nil)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 240)
                        }
                    }
                }   // end ZStack
            )
    }   // end body
    
}
