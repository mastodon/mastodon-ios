//
//  MastodonSDK+API+Instance.swift
//  
//
//  Created by MainasuK Cirno on 2021-2-5.
//

import os.log
import XCTest
import Combine
@testable import MastodonSDK

extension MastodonSDKTests {
    
    func testInstance() throws {
        try _testInstance(domain: domain)
    }
    
    func _testInstance(domain: String) throws {
        let theExpectation = expectation(description: "Fetch Instance Infomation")
        
        Mastodon.API.Instance.instance(session: session, domain: domain)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { response in
                XCTAssertNotEqual(response.value.uri, "")
                print(response.value)
                theExpectation.fulfill()
            }
            .store(in: &disposeBag)

        wait(for: [theExpectation], timeout: 10.0)
    }

}
