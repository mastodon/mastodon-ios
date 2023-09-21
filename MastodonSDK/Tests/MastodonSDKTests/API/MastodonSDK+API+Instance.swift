//
//  MastodonSDK+API+Instance.swift
//  
//
//  Created by MainasuK Cirno on 2021-2-5.
//

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
    
    func testInstanceRules() throws {
        switch domain {
        case "mastodon.online":     break
        default:                    return
        }
        
        try _testInstanceRules(domain: domain)
    }
    
    func _testInstanceRules(domain: String) throws {
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
                XCTAssert(!(response.value.rules ?? []).isEmpty)
                print(response.value.rules?.sorted(by: { $0.id < $1.id }) ?? "")
                theExpectation.fulfill()
            }
            .store(in: &disposeBag)

        wait(for: [theExpectation], timeout: 10.0)
    }

}
