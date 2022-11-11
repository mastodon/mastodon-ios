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

public struct AttachmentView: View {
    
    @ObservedObject var viewModel: AttachmentViewModel
        
    var blurEffect: UIBlurEffect {
        UIBlurEffect(style: .systemUltraThinMaterialDark)
    }

    public var body: some View {
        ZStack {
            let image = viewModel.thumbnail ?? .placeholder(color: .secondarySystemFill)
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                
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
                    Text("Load Failed")    // TODO: i18n
                        .font(.system(size: 13, weight: .semibold))
                    Text(error.localizedDescription)
                        .font(.system(size: 12, weight: .regular))
                }
            }
            
            // loaded
            // uploading… or upload failed
            // could retry upload when error emit
            if viewModel.output != nil {
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
                                CircleProgressView(progress: viewModel.fractionCompleted)
                                    .animation(.default, value: viewModel.fractionCompleted)
                            )
                            .clipShape(Circle())
                            .padding()
                    }

                    let title: String = {
                        switch action {
                        case .remove:
                            let totalSizeInByte = viewModel.outputSizeInByte
                            let uploadSizeInByte = Double(totalSizeInByte) * min(1.0, viewModel.fractionCompleted)
                            let total = viewModel.byteCountFormatter.string(fromByteCount: Int64(totalSizeInByte))
                            let upload = viewModel.byteCountFormatter.string(fromByteCount: Int64(uploadSizeInByte))
                            return "\(upload) / \(total)"
                        case .retry:
                            return "Upload Failed"  // TODO: i18n
                        }
                    }()
                    let subtitle: String = {
                        switch action {
                        case .remove:
                            if viewModel.progress.fractionCompleted < 1, viewModel.uploadState == .uploading {
                                return viewModel.remainTimeLocalizedString ?? ""
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
                }
            }
        }   // end ZStack
    }   // end body
    
}
