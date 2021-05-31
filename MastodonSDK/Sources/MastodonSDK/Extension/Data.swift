//
//  Data.swift
//  
//
//  Created by MainasuK Cirno on 2021-3-8.
//

import Foundation

extension Data {
        
    static func multipart(
        boundary: String = Multipart.boundary,
        key: String,
        value: MultipartFormValue
    ) -> Data {
        var data = Data()
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(key)\"".data(using: .utf8)!)
        if let filename = value.multipartFilename {
            data.append("; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        } else {
            data.append("\r\n".data(using: .utf8)!)
        }
        if let contentType = value.multipartContentType {
            data.append("Content-Type: \(contentType)\r\n".data(using: .utf8)!)
        }
        data.append("\r\n".data(using: .utf8)!)
        if value.multipartStreamValue == nil {
            data.append(value.multipartValue)
        } else {
            // needs append stream multipart value outside
            // seealso: SerialStream
        }
        return data
    }
    
    static func multipartEnd(boundary: String = Multipart.boundary) -> Data {
        return "\r\n--\(boundary)--\r\n".data(using: .utf8)!
    }

}

extension Data {
    func base64UrlEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
