//
//  MastodonMetricFormatter.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-2.
//

import Foundation

enum DecimalUnit: Int {
    case one = 1
    case ten = 10
    case hundred = 100
    case thousand = 1_000
    case million = 1_000_000
    case billion = 1_000_000_000
    case trillion = 1_000_000_000_000
    
    var asInt: Int {
        self.rawValue
    }
}

/// Abbreviate a given number into the highest significant digits and a unit (K for thousands)
public final class MastodonMetricFormatter: Formatter {

    /// The locale that determines the decimal separator (e.g. "1.9K" in the US, "1,9K" in the EU).
    public var locale: Locale = .autoupdatingCurrent

    public func string(from number: Int) -> String? {
        let isPositive = number >= 0
        let symbol = isPositive ? "" : "-"

        let value = abs(number)
        let metric: String

        switch value {
        case 0 ..< DecimalUnit.thousand.asInt: // 0 ~ 1K
            metric = value.formatted(.number.grouping(.never).locale(locale))
        case DecimalUnit.thousand.asInt ..< DecimalUnit.million.asInt: // 1K ~ 1M
            metric = abbreviateRoundingDown(value, unit: .thousand, maximumFractionDigits: value < 10_000 ? 1 : 0) + "K"
        case DecimalUnit.million.asInt ..< DecimalUnit.billion.asInt: // 1M ~ 1B
            metric = abbreviateRoundingDown(value, unit: .million, maximumFractionDigits: value < 10_000_000 ? 1 : 0) + "M"
        case DecimalUnit.billion.asInt ..< DecimalUnit.trillion.asInt: // 1B ~ 1T
            metric = abbreviateRoundingDown(value, unit: .billion, maximumFractionDigits: 0) + "B"
        default: // > 1T
            metric = abbreviateRoundingDown(value, unit: .trillion, maximumFractionDigits: 0) + "T"
        }

        return symbol + metric
    }
    
    private func abbreviateRoundingDown(_ value: Int, unit: DecimalUnit, maximumFractionDigits: Int) -> String {
        let scaled = Decimal(value) / Decimal(unit.asInt)
        return scaled.formatted(
            .number
                .precision(.fractionLength(0 ... maximumFractionDigits))
                .rounded(rule: .towardZero)
                .grouping(.never)
                .locale(locale)
        )
    }

}
