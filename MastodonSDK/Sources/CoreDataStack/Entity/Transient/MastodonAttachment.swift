//
//  MastodonAttachment.swift
//  MastodonAttachment
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreGraphics

public final class MastodonAttachment: NSObject, Codable {
    public typealias ID = String
    
    public let id: ID
    public let kind: Kind
    public let size: CGSize
    public let focus: CGPoint?
    public let blurhash: String?
    public let assetURL: String?
    public let previewURL: String?
    public let textURL: String?
    public let durationMS: Int?
    public let altDescription: String?
    
    public init(
        id: MastodonAttachment.ID,
        kind: MastodonAttachment.Kind,
        size: CGSize,
        focus: CGPoint?,
        blurhash: String?,
        assetURL: String?,
        previewURL: String?,
        textURL: String?,
        durationMS: Int?,
        altDescription: String?
    ) {
        self.id = id
        self.kind = kind
        self.size = size
        self.focus = focus
        self.blurhash = blurhash
        self.assetURL = assetURL
        self.previewURL = previewURL
        self.textURL = textURL
        self.durationMS = durationMS
        self.altDescription = altDescription
    }
}

extension MastodonAttachment {
    public enum Kind: String, Codable {
        case image
        case video
        case gifv
        case audio
    }
}
