// Copyright © 2025 Mastodon gGmbH. All rights reserved.
//
//  InlinePostPreview.swift
//  Design
//
//  Created by Sam on 2024-05-08.
//

import MastodonSDK
import SwiftUI
import SDWebImageSwiftUI

struct InlinePostPreview: View {
    let viewModel: Mastodon.Entity.Status.ViewModel
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                header()
                if let content = viewModel.content, let html = content.htmlWithEntities?.html {
                    let emojis = content.htmlWithEntities?.emojis ?? []
                    MastodonContentView.timelinePost(html: html, emojis: emojis, isInlinePreview: true)
                        .font(.subheadline)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let attachmentInfo = viewModel.attachmentInfo {
                    HStack {
                        Image(systemName: attachmentInfo.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: tinyAvatarSize)
                        Text(attachmentInfo.labelText)
                    }
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .lineLimit(1)
                }
            }
            Spacer(minLength: 0) // This pushes the VStack all the way to the left.
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background {
            MastodonSecondaryBackground(fillInDarkModeOnly: true)
        }
    }

    private let tinyAvatarSize: CGFloat = 16
    private let avatarShape = RoundedRectangle(cornerRadius: 4)

    @ViewBuilder func header() -> some View {
        HStack(spacing: 4) {
            if viewModel.needsUserAttribution {
                if let url = viewModel.accountAvatarUrl {
                    WebImage(
                        url: url,
                        content: { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(avatarShape)
                        },
                        placeholder: {
                            avatarShape
                                .foregroundStyle(
                                    Color(UIColor.secondarySystemFill))
                        }
                    )
                    .frame(width: tinyAvatarSize, height: tinyAvatarSize)
                }
                Text(viewModel.accountDisplayName ?? "")
                    .bold()
                Text(viewModel.accountFullName ?? "")
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else if viewModel.isPinned {
                //  This *should* be a Label but it acts funky when this is in a List
                Group {
                    Image(systemName: "pin.fill")
                    Text("Pinned")
                }
                .bold()
                .foregroundStyle(.secondary)
                .imageScale(.small)
            }
        }
        .lineLimit(1)
        .font(.subheadline)
    }
}
