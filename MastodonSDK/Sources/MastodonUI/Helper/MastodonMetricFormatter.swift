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
    
    var asDouble: Double {
        Double(self.rawValue)
    }
}

/// Abbreviate a given number into the highest significant digits and a unit (K for thousands)
public final class MastodonMetricFormatter: Formatter {
    
    private let ten_thousands = DecimalUnit.thousand.asInt * 10
    private let ten_millions = DecimalUnit.million.asInt * 10
    
    /// The number formatter instance that will be used. May be customized through ``abbreviatedGroupingSeparator``.
    private let numberFormatter = NumberFormatter()

    /// MastodonMetricFormatter first converts to decimel _then_ displays the value.
    /// Use this instead of the NumberFormatter.groupingSeparator.
    /// Ex: "1,5K" in the EU, and "1.5K" in the US.
    public var abbreviatedGroupingSeparator: String {
        get {
            numberFormatter.decimalSeparator
        }
        set {
            numberFormatter.decimalSeparator = newValue
        }
    }

    public func string(from number: Int) -> String? {
        let isPositive = number >= 0
        let symbol = isPositive ? "" : "-"
     
        let value = abs(number)
        let metric: String
        
        switch value {
        case 0 ..< DecimalUnit.thousand.asInt: // 0 ~ 1K
            numberFormatter.maximumFractionDigits = 0
            let string = numberFormatter.string(from: NSNumber(value: value)) ?? String(value)
            metric = string
        case DecimalUnit.thousand.asInt ..< DecimalUnit.million.asInt: // 1K ~ 1M
            numberFormatter.maximumFractionDigits = value < ten_thousands ? 1 : 0
            let string = numberFormatter.string(from: NSNumber(value: Double(value) / DecimalUnit.thousand.asDouble)) ??
            String(value / DecimalUnit.thousand.asInt)
            metric = string + "K"
        case DecimalUnit.million.asInt ..< DecimalUnit.billion.asInt: // 1M ~ 1B
            numberFormatter.maximumFractionDigits = value < ten_millions ? 1 : 0
            let string = numberFormatter.string(from: NSNumber(value: Double(value) / DecimalUnit.million.asDouble)) ??
            String(value / DecimalUnit.million.asInt)
            metric = string + "M"
        case DecimalUnit.billion.asInt ..< DecimalUnit.trillion.asInt: // 1B ~ 1T
            numberFormatter.maximumFractionDigits = 0
            let string = numberFormatter.string(from: NSNumber(value: Double(value) / DecimalUnit.billion.asDouble)) ??
            String(value / DecimalUnit.billion.asInt)
            metric = string + "B"
        default: // > 1T
            numberFormatter.maximumFractionDigits = 0
            let string = numberFormatter.string(from: NSNumber(value: Double(value) / DecimalUnit.trillion.asDouble)) ??
            String(value / DecimalUnit.trillion.asInt)
            metric = string + "T"
        }
        
        return symbol + metric
    }
    
}
