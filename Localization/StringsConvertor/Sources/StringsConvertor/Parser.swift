//
//  File.swift
//  
//
//  Created by Cirno MainasuK on 2020-7-7.
//

import Foundation

class Parser {
    
    let json: [String: Any]
    
    init(data: Data) throws {
        let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        self.json = dict ?? [:]
    }
    
    
}

extension Parser {
    enum KeyStyle {
        case infoPlist
        case swiftgen
    }
}

extension Parser {
    
    func generateStrings(keyStyle: KeyStyle = .swiftgen) -> String {
        let pairs = traval(dictionary: json, prefixKeys: [])
        
        var lines: [String] = []
        for pair in pairs {
            let key = [
                "\"",
                pair.prefix
                    .map { segment in
                        segment
                            .split(separator: "_")
                            .map { String($0) }
                            .map {
                                switch keyStyle {
                                case .infoPlist:        return $0
                                case .swiftgen:         return $0.capitalized
                                }
                            }
                            .joined()
                    }
                    .joined(separator: "."),
                "\""
            ].joined()
            let value = [
                "\"",
                pair.value.replacingOccurrences(of: "%s", with: "%@"),
                "\""
            ].joined()
            let line = [
                [key, value].joined(separator: " = "),
                ";"
            ].joined()
            
            lines.append(line)
        }
        
        let strings = lines
            .sorted()
            .joined(separator: "\n")
        return strings
    }
    
}

extension Parser {
    
    typealias PrefixKeys = [String]
    typealias LocalizationPair = (prefix: PrefixKeys, value: String)

    private func traval(dictionary: [String: Any], prefixKeys: PrefixKeys) -> [LocalizationPair] {
        var pairs: [LocalizationPair] = []
        for (key, any) in dictionary {
            let prefix = prefixKeys + [key]

            // if leaf node of dict tree
            if let value = any as? String {
                pairs.append(LocalizationPair(prefix: prefix, value: value))
                continue
            }
            
            // if not leaf node of dict tree
            if let dict = any as? [String: Any] {
                let innerPairs = traval(dictionary: dict, prefixKeys: prefix)
                pairs.append(contentsOf: innerPairs)
            }
        }
        return pairs
    }
    
}
