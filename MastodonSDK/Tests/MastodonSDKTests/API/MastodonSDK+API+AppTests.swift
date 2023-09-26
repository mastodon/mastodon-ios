//
//  MastodonSDK+API+AppTests.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/29.
//

import XCTest
import Combine
@testable import MastodonSDK

extension MastodonSDKTests {
    
    func testCreateAnAnpplication() throws {
        try _testCreateAnAnpplication(domain: domain)
    }
    
    func _testCreateAnAnpplication(domain: String) throws {
        let theExpectation = expectation(description: "Create An Application")
        
        let query = Mastodon.API.App.CreateQuery(
            clientName: "XCTest",
            redirectURIs: "mastodon://joinmastodon.org/oauth",
            website: nil
        )
        Mastodon.API.App.create(session: session, domain: domain, query: query)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { response in
                XCTAssertEqual(response.value.name, "XCTest")
                XCTAssertEqual(response.value.website, nil)
                XCTAssertEqual(response.value.redirectURI, "urn:ietf:wg:oauth:2.0:oob")
                theExpectation.fulfill()
            }
            .store(in: &disposeBag)
        
        wait(for: [theExpectation], timeout: 5.0)
    }

}

extension MastodonSDKTests {
    
    func testVerifyAppCredentials() throws {
        try _testVerifyAppCredentials(domain: domain, accessToken: testToken)
    }
    
    func _testVerifyAppCredentials(domain: String, accessToken: String) throws {
        let theExpectation = expectation(description: "Verify App Credentials")
        
        let authorization = Mastodon.API.OAuth.Authorization(accessToken: accessToken)
        Mastodon.API.App.verifyCredentials(
            session: session,
            domain: domain,
            authorization: authorization
        )
        .receive(on: DispatchQueue.main)
        .sink { completion in
            switch completion {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .finished:
                break
            }
        } receiveValue: { response in
            XCTAssertEqual(response.value.name, "XCTest")
            XCTAssertEqual(response.value.website, nil)
            theExpectation.fulfill()
        }
        .store(in: &disposeBag)
        
        wait(for: [theExpectation], timeout: 5.0)
    }
    
}
