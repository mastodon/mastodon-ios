//
//  Punycode.swift
//  
//
//  Created by Jed Fox on 2022-11-15.
//

import Foundation

public enum Punycode {
    // https://datatracker.ietf.org/doc/html/rfc3492#section-5
    private static let base         = UInt32(36)
    private static let tmin         = UInt32(1)
    private static let tmax         = UInt32(26)
    private static let skew         = UInt32(38)
    private static let damp         = UInt32(700)
    private static let initial_bias = UInt32(72)
    private static let initial_n    = UInt32(128) // = 0x80

    private static let digits: [String] = "abcdefghijklmnopqrstuvwxyz0123456789".map { String($0) }

    public static func encode<S: StringProtocol>(_ input: S) -> String {
        let codePoints = input.unicodeScalars
        let basicCodePoints = String.UnicodeScalarView(codePoints.filter(\.isASCII))
        let codePointsSorted = codePoints.map(\.value).sorted()
        if basicCodePoints.count == codePoints.count { return String(input) }

        // https://datatracker.ietf.org/doc/html/rfc3492#section-6.3
        // [Swift fails on overflow already, so no special consideration necessary]
        var n = initial_n
        var delta = UInt32(0)
        var bias = initial_bias
        // the number of basic code points in the input
        let b = UInt32(basicCodePoints.count)
        var h = b
        // copy them to the output in order, followed by a delimiter if b > 0
        var output = "xn--" + String(basicCodePoints)
        if b > 0 {
            output += "-"
        }

        while h < codePoints.count {
            // the minimum code point >= n in the input
            let m = codePointsSorted.first(where: { $0 >= n })!
            delta = delta + (m - n) * (h + 1)
            n = m
            for codePoint in codePoints {
                let c = codePoint.value
                if c < n || codePoint.isASCII {
                    delta += 1
                }
                if c == n {
                    var q = delta
                    var k = base
                    repeat {
                        let t = k <= bias + tmin ? tmin : (k >= bias + tmax ? tmax : k - bias)
                        if q < t { break }
                        output += digits[Int(t + ((q - t) % (base - t)))]
                        q = (q - t) / (base - t)
                        k += base
                    } while true
                    output += digits[Int(q)]
                    bias = adapt(delta, h + 1, h == b)
                    delta = 0
                    h += 1
                }
            }
            delta += 1
            n += 1
        }
        return output
    }

    // https://datatracker.ietf.org/doc/html/rfc3492#section-6.1
    private static func adapt(_ delta: UInt32, _ numpoints: UInt32, _ firsttime: Bool) -> UInt32 {
        var delta = firsttime ? delta / damp : delta / 2
        delta = delta + (delta / numpoints)
        var k = UInt32(0)
        while delta > ((base - tmin) * tmax) / 2 {
            delta = delta / (base - tmin)
            k = k + base
        }
        return k + (((base - tmin + 1) * delta) / (delta + skew))
    }
}
