//
//  IntTests.swift
//  
//
//  Created by Marcus Kida on 28.12.22.
//

import XCTest
@testable import MastodonSDK

class IntFriendlyCountTests: XCTestCase {
    func testFriendlyCount_for_1000() {
        let input = 1_000
        let expectedOutput = "1K"
        
        XCTAssertEqual(expectedOutput, input.asAbbreviatedCountString())
    }
    
    func testFriendlyCount_for_1200() {
        let input = 1_200
        let expectedOutput = "1.2K"
        
        XCTAssertEqual(expectedOutput, input.asAbbreviatedCountString())
    }
    
    func testFriendlyCount_for_50000() {
        let input = 50_000
        let expectedOutput = "50K"
        
        XCTAssertEqual(expectedOutput, input.asAbbreviatedCountString())
    }
    
    func testFriendlyCount_for_70666() {
        let input = 70_666
        let expectedOutput = "70.7K"
        
        XCTAssertEqual(expectedOutput, input.asAbbreviatedCountString())
    }
    
    func testFriendlyCount_for_1M() {
        let input = 1_000_000
        let expectedOutput = "1M"
        
        XCTAssertEqual(expectedOutput, input.asAbbreviatedCountString())
    }
    
    func testFriendlyCount_for_1dot5M() {
        let input = 1_499_000
        let expectedOutput = "1.5M"
        
        XCTAssertEqual(expectedOutput, input.asAbbreviatedCountString())
    }
}
