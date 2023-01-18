//
//  MediaAttachment.swift
//
//
//  Created by jk234ert on 2/9/21.
//

import Foundation

extension Mastodon.Query {
    public enum MediaAttachment {
        /// JPEG (Joint Photographic Experts Group) image
        case jpeg(Data?)
        /// GIF (Graphics Interchange Format) image
        case gif(Data?)
        /// PNG (Portable Network Graphics) image
        case png(Data?)
        /// Other media file
        /// e.g video
        case other(URL?, fileExtension: String, mimeType: String)
    }
}

extension Mastodon.Query.MediaAttachment {
    public var data: Data? {
        switch self {
        case .jpeg(let data): return data
        case .gif(let data): return data
        case .png(let data): return data
        case .other: return nil
        }
    }

    public var fileName: String {
        let name = UUID().uuidString
        switch self {
        case .jpeg: return "\(name).jpg"
        case .gif: return "\(name).gif"
        case .png: return "\(name).png"
        case .other(_, let fileExtension, _): return "\(name).\(fileExtension)"
        }
    }

    public var mimeType: String {
        switch self {
        case .jpeg: return "image/jpeg"
        case .gif: return "image/gif"
        case .png: return "image/png"
        case .other(_, _, let mimeType): return mimeType
        }
    }

    var base64EncondedString: String? {
        return data.map { "data:" + mimeType + ";base64," + $0.base64EncodedString() }
    }

    public var sizeInByte: Int? {
        switch self {
        case .jpeg(let data), .gif(let data), .png(let data):
            return data?.count
        case .other(let url, _, _):
            guard let url = url else { return nil }
            guard let attribute = try? FileManager.default.attributesOfItem(atPath: url.path) else { return nil }
            guard let size = attribute[.size] as? UInt64 else { return nil }
            return Int(size)
        }
    }
}

extension Mastodon.Query.MediaAttachment: MultipartFormValue {
    var multipartValue: Data { return data ?? Data() }
    var multipartStreamValue: InputStream? {
        switch self {
        case .other(let url, _, _):
            return url.flatMap { InputStream(url: $0) }
        default:
            return nil
        }
    }
    var multipartContentType: String? { return mimeType }
    var multipartFilename: String? { return fileName }
}
