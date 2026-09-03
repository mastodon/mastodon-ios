//
//  MastodonRegexTests.swift
//  MastodonTests
//
//  Created by Assistant on 2025-11-02.
//

import XCTest
@testable import Mastodon
import MastodonUI

final class MastodonRegexTests: XCTestCase {

    func testExample() throws {
        XCTAssertTrue(true)
    }

    func testUnicodeRegexPatterns() throws {
        // Test that our regex patterns correctly match Unicode characters with combining marks
        let highlightPattern = MastodonRegex.highlightPattern
        let autoCompletePattern = MastodonRegex.autoCompletePattern

        let testCases = [
            "@café@examplë.com",
            "@unikonstanz@bawü.social",
            "@user@täst.de",
            "@björn@exämple.com"
        ]

        // Test highlight pattern
        let highlightRegex = try NSRegularExpression(pattern: highlightPattern, options: [])
        for testCase in testCases {
            let nsString = testCase as NSString
            let range = NSRange(location: 0, length: nsString.length)
            let matches = highlightRegex.matches(in: testCase, options: [], range: range)

            XCTAssertEqual(matches.count, 1, "Highlight pattern should match \(testCase)")
        }

        // Test autocomplete pattern
        let autoCompleteRegex = try NSRegularExpression(pattern: autoCompletePattern, options: [])
        for testCase in testCases {
            let nsString = testCase as NSString
            let range = NSRange(location: 0, length: nsString.length)
            let matches = autoCompleteRegex.matches(in: testCase, options: [], range: range)

            XCTAssertEqual(matches.count, 1, "Autocomplete pattern should match \(testCase)")
        }
    }

    func testHighlightPatternWithUnicodeCharacters() throws {
        let highlightPattern = MastodonRegex.highlightPattern
        let regex = try NSRegularExpression(pattern: highlightPattern, options: [])

        // Test cases with unicode characters
        let testCases = [
            "@unikonstanz@bawü.social",
            "@user@täst.de",
            "@björn@exämple.com",
            "@用户@example.com",
            "@example@例え.テスト",
            "@café@examplë.com"  // Test with combining marks
        ]

        for testCase in testCases {
            let nsString = testCase as NSString
            let range = NSRange(location: 0, length: nsString.length)
            let matches = regex.matches(in: testCase, options: [], range: range)

            // Should find exactly one match
            XCTAssertEqual(matches.count, 1, "Failed to match \(testCase)")

            if let match = matches.first {
                // The full match should cover the entire string
                XCTAssertEqual(match.range.location, 0)
                XCTAssertEqual(match.range.length, nsString.length)

                // The first capture group should be the username part
                let usernameRange = match.range(at: 1)
                if usernameRange.location != NSNotFound {
                    let username = nsString.substring(with: usernameRange)
                    XCTAssertTrue(username.count > 0, "Username capture group is empty for \(testCase)")
                }

                // The second capture group should be the domain part (if present)
                let domainRange = match.range(at: 2)
                if domainRange.location != NSNotFound {
                    let domain = nsString.substring(with: domainRange)
                    XCTAssertTrue(domain.count > 0, "Domain capture group is empty for \(testCase)")
                }
            }
        }
    }

    func testAutoCompletePatternWithUnicodeCharacters() throws {
        let autoCompletePattern = MastodonRegex.autoCompletePattern
        let regex = try NSRegularExpression(pattern: autoCompletePattern, options: [])

        // Test cases with unicode characters
        let testCases = [
            "@unikonstanz@bawü.social",
            "@user@täst.de",
            "@björn@exämple.com",
            "@用户@example.com",
            "@example@例え.テスト",
            "@café@examplë.com"  // Test with combining marks
        ]

        for testCase in testCases {
            let nsString = testCase as NSString
            let range = NSRange(location: 0, length: nsString.length)
            let matches = regex.matches(in: testCase, options: [], range: range)

            // Should find exactly one match
            XCTAssertEqual(matches.count, 1, "Failed to match \(testCase)")

            if let match = matches.first {
                // The full match should cover the entire string
                XCTAssertEqual(match.range.location, 0)
                XCTAssertEqual(match.range.length, nsString.length)
            }
        }
    }

    func testHighlightPatternWithAsciiCharacters() throws {
        let highlightPattern = MastodonRegex.highlightPattern
        let regex = try NSRegularExpression(pattern: highlightPattern, options: [])

        // Test cases with ASCII characters (should still work)
        let testCases = [
            "@user@example.com",
            "@test@domain.org",
            "@simple@site.net",
            "@café@example.com"  // Test with combining marks
        ]

        for testCase in testCases {
            let nsString = testCase as NSString
            let range = NSRange(location: 0, length: nsString.length)
            let matches = regex.matches(in: testCase, options: [], range: range)

            // Should find exactly one match
            XCTAssertEqual(matches.count, 1, "Failed to match \(testCase)")

            if let match = matches.first {
                // The full match should cover the entire string
                XCTAssertEqual(match.range.location, 0)
                XCTAssertEqual(match.range.length, nsString.length)
            }
        }
    }

    func testAutoCompletePatternWithAsciiCharacters() throws {
        let autoCompletePattern = MastodonRegex.autoCompletePattern
        let regex = try NSRegularExpression(pattern: autoCompletePattern, options: [])

        // Test cases with ASCII characters (should still work)
        let testCases = [
            "@user@example.com",
            "@test@domain.org",
            "@simple@site.net",
            "@café@example.com"  // Test with combining marks
        ]

        for testCase in testCases {
            let nsString = testCase as NSString
            let range = NSRange(location: 0, length: nsString.length)
            let matches = regex.matches(in: testCase, options: [], range: range)

            // Should find exactly one match
            XCTAssertEqual(matches.count, 1, "Failed to match \(testCase)")

            if let match = matches.first {
                // The full match should cover the entire string
                XCTAssertEqual(match.range.location, 0)
                XCTAssertEqual(match.range.length, nsString.length)
            }
        }
    }
}