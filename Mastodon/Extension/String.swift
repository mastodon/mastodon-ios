//
//  String.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/29.
//

import Foundation
extension String {
    public func pregReplace(pattern: String, with: String, options: NSRegularExpression.Options = []) -> String {
        // swiftlint:disable force_try
        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        return regex.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: nsLength), withTemplate: with)
    }
}
extension String {
    public var nsLength: Int {
        let string_NS = self as NSString
        return string_NS.length
    }
}
extension String {
    func toPlainText() -> String {
        return self.pregReplace(pattern: "<br.+?>", with: "\n")
            .replacingOccurrences(of: "</p><p>", with: "\n\n")
            .pregReplace(pattern: "<.+?>", with: "")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
}
extension String {
    func string(in nsrange: NSRange) -> String? {
        guard let range = Range(nsrange, in: self) else { return nil }
        return String(self[range])
    }
}
