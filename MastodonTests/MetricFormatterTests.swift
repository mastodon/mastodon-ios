//
//  MetricFormatterTests.swift
//  MastodonTests
//
//  Created by Marcus Kida on 04.04.24.
//

import XCTest
@testable import MastodonUI

class MetricFormatterTests: XCTestCase {
    
    func test_millionsFormat_exactMillion() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 10_000_000)
        
        XCTAssertEqual(value, "10M")
    }
    
    func test_millionsFormat_oneTwoThreeMillion() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 12_345_789)
        
        XCTAssertEqual(value, "12,3M")
    }
    
    func test_billionsFormat() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 10_000_000_000)
        
        XCTAssertEqual(value, "10B")
    }
    
    func test_billionsFormat_oneTwoThreeBillion() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 12_345_678_912)
        
        XCTAssertEqual(value, "12,3B")
    }
    
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
    
    func test_thousandsFormat() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 1234)
        
        XCTAssertEqual(value, "1,2K")
    }
    
    func test_sixThousandsFormat() {
        let formatter = MastodonMetricFormatter()
        let value = formatter.string(from: 6666)
        
        XCTAssertEqual(value, "6,7K")
    }
}
