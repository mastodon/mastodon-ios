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
    
    func test_thousandNinetynineFormat() {
        let formatter_EU = MastodonMetricFormatter()
        formatter_EU.abbreviatedGroupingSeparator = ","
        let value_EU = formatter_EU.string(from: 1099)

        XCTAssertEqual(value_EU, "1,1K")

        let formatter_US = MastodonMetricFormatter()
        formatter_US.abbreviatedGroupingSeparator = "."
        let value_US = formatter_US.string(from: 1099)

        XCTAssertEqual(value_US, "1.1K")
    }
    
    // TODO: Test US and EU formatters

    func test_thousandNinehundredFormat() {
        let formatter = MastodonMetricFormatter()
        formatter.abbreviatedGroupingSeparator = ","
        let value = formatter.string(from: 1900)
        
        XCTAssertEqual(value, "1,9K")
    }
    
    func test_thousandsFormat() {
        let formatter = MastodonMetricFormatter()
        formatter.abbreviatedGroupingSeparator = ","
        let value = formatter.string(from: 1234)
        
        XCTAssertEqual(value, "1,2K")
    }
    
    func test_sixThousandsFormat() {
        let formatter = MastodonMetricFormatter()
        formatter.abbreviatedGroupingSeparator = ","
        let value = formatter.string(from: 6666)
        
        XCTAssertEqual(value, "6,7K")
    }
    
    func test_millionsFormat_oneTwoThreeMillion() {
        let formatter = MastodonMetricFormatter()
        formatter.abbreviatedGroupingSeparator = ","
        let value = formatter.string(from: 1_234_567)
        
        XCTAssertEqual(value, "1,2M")
    }
    
    func test_millionsFormat_exactlyTenMillion() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 10_000_000)
        
        XCTAssertEqual(value, "10M")
    }
    
    func test_millionsFormat_twelveOneTwoThreeMillion() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 12_345_789)
        
        XCTAssertEqual(value, "12M")
    }
    
    func test_billionsFormat() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 10_000_000_000)
        
        XCTAssertEqual(value, "10B")
    }
    
    func test_billionsFormat_oneTwoThreeBillion() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 12_345_678_912)
        
        XCTAssertEqual(value, "12B")
    }
    
    func test_trillionsFormat() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 10_000_000_000_000)
        
        XCTAssertEqual(value, "10T")
    }
    
    func test_trillionsFormat_oneTwoThreeTrillion() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 12_345_678_912_345)
        
        XCTAssertEqual(value, "12T")
    }
    
    func test_trillionsFormat_oneTwoThree_youGottaBeKiddinMeTrillion() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 12_345_678_912_345_678)
        
        XCTAssertEqual(value, "12346T")
    }
    
    func test_trillionsFormat_oneTwoThree_lastDigitBeforeIntegerOverflowTrillion() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 12_345_678_912_345_678_91)
        
        XCTAssertEqual(value, "1234568T")
    }
}
