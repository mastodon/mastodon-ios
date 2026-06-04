// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import XCTest
@testable import MastodonUI

class MetricFormatterTests: XCTestCase {
    func test_tensFormat() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 12)
        
        XCTAssertEqual(value, "12")
    }
    
    func test_hundredsFormat() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 123)
        
        XCTAssertEqual(value, "123")
    }
    
    func test_thousandOneFormat() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 1001)
        
        XCTAssertEqual(value, "1K")
    }
    
    func test_thousandFiftyFormat() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 1050)
        
        XCTAssertEqual(value, "1K")
    }

    func test_oneThousandOneHundredFiftySeparatorFormat() {
        let value_comma = germanFormatter().string(from: 1150)

        XCTAssertEqual(value_comma, "1,1K")
        
        let usFormatter = MastodonMetricFormatter()
        usFormatter.locale = .init(identifier: "en_US")
        let value_period = usFormatter.string(from: 1150)
        
        XCTAssertEqual(value_period, "1.1K")
    }

    func test_thousandNinehundredFormat() {
        let formatter = germanFormatter()
        let value = formatter.string(from: 1900)
        
        XCTAssertEqual(value, "1,9K")
    }
    
    func test_thousandsFormat() {
        let formatter = germanFormatter()
        let value = formatter.string(from: 1234)
        
        XCTAssertEqual(value, "1,2K")
    }
    
    func test_sixThousandsFormat() {
        let formatter = germanFormatter()
        let value = formatter.string(from: 6666)

        XCTAssertEqual(value, "6,6K")
    }
    
    func test_millionsFormat_oneTwoThreeMillion() {
        let formatter = germanFormatter()
        let value = formatter.string(from: 1_234_567)
        
        XCTAssertEqual(value, "1,2M")
    }
    
    func test_millionsFormat_exactlyTenMillion() {
        let formatter = germanFormatter()
        let value = formatter.string(from: 10_000_000)
        
        XCTAssertEqual(value, "10M")
    }
    
    func test_millionsFormat_twelveOneTwoThreeMillion() {
        let formatter = germanFormatter()
        let value = formatter.string(from: 12_345_789)
        
        XCTAssertEqual(value, "12M")
    }
    
    func test_billionsFormat() {
        let formatter = germanFormatter()
        let value = formatter.string(from: 10_000_000_000)
        
        XCTAssertEqual(value, "10B")
    }
    
    func test_billionsFormat_oneTwoThreeBillion() {
        let formatter = germanFormatter()
        let value = formatter.string(from: 12_345_678_912)
        
        XCTAssertEqual(value, "12B")
    }
    
    func test_trillionsFormat() {
        let formatter = germanFormatter()
        let value = formatter.string(from: 10_000_000_000_000)
        
        XCTAssertEqual(value, "10T")
    }
    
    func test_trillionsFormat_oneTwoThreeTrillion() {
        let formatter = germanFormatter()
        let value = formatter.string(from: 12_345_678_912_345)
        
        XCTAssertEqual(value, "12T")
    }
    
    func test_trillionsFormat_oneTwoThree_youGottaBeKiddinMeTrillion() {
        let formatter = germanFormatter()
        let value = formatter.string(from: 12_345_678_912_345_678)

        XCTAssertEqual(value, "12345T")
    }
    
    func test_trillionsFormat_oneTwoThree_lastDigitBeforeIntegerOverflowTrillion() {
        let formatter = germanFormatter()
        let value = formatter.string(from: 12_345_678_912_345_678_91)

        XCTAssertEqual(value, "1234567T")
    }

    func test_roundsDown_doesNotAbbreviateUnderOneThousand() {
        XCTAssertEqual(germanFormatter().string(from: 999), "999")
    }

    func test_roundsDown_exactlyOneThousand() {
        XCTAssertEqual(germanFormatter().string(from: 1000), "1K")
    }

    func test_roundsDown_truncatesOneThousandFiftyOne() {
        XCTAssertEqual(germanFormatter().string(from: 1051), "1K")
    }

    func test_roundsDown_truncatesTwoThousandNineHundredNinetyNine() {
        XCTAssertEqual(germanFormatter().string(from: 2999), "2,9K")
    }

    func test_roundsDown_truncatesNineThousandNineHundredNinetyNine() {
        XCTAssertEqual(germanFormatter().string(from: 9999), "9,9K")
    }

    func test_roundsDown_truncatesTenThousandFiveHundredOne() {
        XCTAssertEqual(germanFormatter().string(from: 10501), "10K")
    }

    func test_roundsDown_elevenThousand() {
        XCTAssertEqual(germanFormatter().string(from: 11000), "11K")
    }

    func test_roundsDown_ninetyNineThousandNineHundredNinetyNine() {
        XCTAssertEqual(germanFormatter().string(from: 99999), "99K")
    }

    func test_roundsDown_hundredThousandFiveHundredOne() {
        XCTAssertEqual(germanFormatter().string(from: 100501), "100K")
    }

    func test_roundsDown_oneHundredOneThousand() {
        XCTAssertEqual(germanFormatter().string(from: 101000), "101K")
    }

    func test_roundsDown_nineHundredNinetyNineThousandNineHundredNinetyNine() {
        XCTAssertEqual(germanFormatter().string(from: 999999), "999K")
    }

    func test_roundsDown_truncatesToTwoPointNineMillion() {
        XCTAssertEqual(germanFormatter().string(from: 2999999), "2,9M")
    }

    func test_roundsDown_truncatesToNinePointNineMillion() {
        XCTAssertEqual(germanFormatter().string(from: 9999999), "9,9M")
    }

    private func germanFormatter() -> MastodonMetricFormatter {
        let formatter = MastodonMetricFormatter()
        formatter.locale = .init(identifier: "de-DE")
        return formatter
    }
}
