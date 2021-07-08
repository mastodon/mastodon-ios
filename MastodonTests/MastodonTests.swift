//
//  MastodonTests.swift
//  MastodonTests
//
//  Created by MainasuK Cirno on 2021/1/22.
//

import XCTest
@testable import Mastodon

class MastodonTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

extension MastodonTests {
    func testWebFinger() {
        let expectation = expectation(description: "webfinger")
        let cancellable = AppContext.shared.apiService.webFinger(domain: "pawoo.net")
            .sink { completion in
                expectation.fulfill()
            } receiveValue: { domain in
                expectation.fulfill()
            }
        wait(for: [expectation], timeout: 10)
    }
}
