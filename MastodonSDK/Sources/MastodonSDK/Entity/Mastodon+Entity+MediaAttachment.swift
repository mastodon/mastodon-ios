//
//  Mastodon+Entity+MediaAttachment.swift
//  
//
//  Created by jk234ert on 2/9/21.
//

import Foundation

extension Mastodon.Entity {
    public enum MediaAttachment {
        /// JPEG (Joint Photographic Experts Group) image
        case jpeg(Data?)
        /// GIF (Graphics Interchange Format) image
        case gif(Data?)
        /// PNG (Portable Network Graphics) image
        case png(Data?)
        /// Other media file
        case other(Data?, fileExtension: String, mimeType: String)
    }
}

extension Mastodon.Entity.MediaAttachment {
    var data: Data? {
        switch self {
        case .jpeg(let data): return data
        case .gif(let data): return data
        case .png(let data): return data
        case .other(let data, _, _): return data
        }
    }

    var fileName: String {
        switch self {
        case .jpeg: return "file.jpg"
        case .gif: return "file.gif"
        case .png: return "file.png"
        case .other(_, let fileExtension, _): return "file.\(fileExtension)"
        }
    }

    var mimeType: String {
        switch self {
        case .jpeg: return "image/jpg"
        case .gif: return "image/gif"
        case .png: return "image/png"
        case .other(_, _, let mimeType): return mimeType
        }
    }

    var base64EncondedString: String? {
        return data.map { "data:" + mimeType + ";base64," + $0.base64EncodedString() }
    }
}

