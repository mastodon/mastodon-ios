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
    
    let action: (Action) -> Void
    
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
                    let image: UIImage = {
                        if let _ = viewModel.error {
                            return Asset.Scene.Compose.Attachment.retry.image.withRenderingMode(.alwaysTemplate)
                        } else {
                            return Asset.Scene.Compose.Attachment.stop.image.withRenderingMode(.alwaysTemplate)
                        }
                    }()
                    Image(uiImage: image)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(Asset.Scene.Compose.Attachment.indicatorButtonBackground.color))
                        .clipShape(Circle())
                        .padding()
                    let title: String = {
                        if let _ = viewModel.error {
                            return "Upload Failed"  // TODO: i18n
                        } else {
                            let total = ByteCountFormatter.string(fromByteCount: Int64(viewModel.outputSizeInByte), countStyle: .memory)
                            return "…/\(total)"
                        }
                    }()
                    let subtitle: String = {
                        if let error = viewModel.error {
                            return error.localizedDescription
                        } else {
                            return "… remaining"
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
        .onChange(of: viewModel.progress) { progress in
            // not works…
            print(progress.completedUnitCount)
        }
    }   // end body
    
}

extension AttachmentView {
    public enum Action: Hashable {
        case remove
        case retry
    }
}
