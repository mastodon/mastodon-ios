//
//  Int.swift
//  
//
//  Created by Marcus Kida on 28.12.22.
//

import Foundation

public extension Int {
    func asAbbreviatedCountString() -> String {
        switch self {
        case ..<1_000:
            return String(format: "%d", locale: Locale.current, self)
        case 1_000 ..< 999_999:
            return String(format: "%.1fK", locale: Locale.current, Double(self) / 1_000)
                .sanitizedAbbreviatedCountString(for: "K")
        default:
            return String(format: "%.1fM", locale: Locale.current, Double(self) / 1_000_000)
                .sanitizedAbbreviatedCountString(for: "M")
        }
    }
}

fileprivate extension String {
    func sanitizedAbbreviatedCountString(for value: String) -> String {
        [".0", ",0", "٫٠"].reduce(self) { res, acc in
            return res.replacingOccurrences(of: "\(acc)\(value)", with: value)
        }
    }
}
