//
//  MultipartFormValue.swift
//  
//
//  Created by MainasuK Cirno on 2021-3-8.
//

import Foundation

enum Multipart {
    static let boundary = "__boundary__"
}

protocol MultipartFormValue {
    var multipartValue: Data { get }
    var multipartStreamValue: InputStream? { get }
    var multipartContentType: String? { get }
    var multipartFilename: String? { get }
}

extension MultipartFormValue {
    var multipartStreamValue: InputStream? { nil }
}

extension Bool: MultipartFormValue {
    var multipartValue: Data {
        switch self {
        case true:      return "true".data(using: .utf8)!
        case false:     return "false".data(using: .utf8)!
        }
    }
    var multipartContentType: String? { return nil }
    var multipartFilename: String? { return nil }
}

extension String: MultipartFormValue {
    var multipartValue: Data {
        return self.data(using: .utf8)!
    }
    var multipartContentType: String? { return nil }
    var multipartFilename: String? { return nil }
}


extension Int: MultipartFormValue {
    var multipartValue: Data {
        return String(self).data(using: .utf8)!
    }
    var multipartContentType: String? { return nil }
    var multipartFilename: String? { return nil }
}
