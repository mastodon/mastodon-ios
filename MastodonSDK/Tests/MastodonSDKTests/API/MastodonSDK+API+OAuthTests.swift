//
//  MastodonSDK+API+OAuthTests.swift
//
//
//  Created by MainasuK Cirno on 2021/1/29.
//

import XCTest
import Combine
@testable import MastodonSDK

extension MastodonSDKTests {
    
    func testOAuthAuthorize() throws {
        try _testOAuthAuthorize(domain: domain)
    }
    
    func _testOAuthAuthorize(domain: String) throws {
        let query = Mastodon.API.OAuth.AuthorizeQuery(clientID: "StubClientID", redirectURI: "mastodon://joinmastodon.org/oauth")
        let authorizeURL = Mastodon.API.OAuth.authorizeURL(domain: domain, query: query)
        XCTAssertEqual(
            authorizeURL.absoluteString,
            "\(URL.httpScheme(domain: domain))://\(domain)/oauth/authorize?response_type=code&client_id=StubClientID&redirect_uri=mastodon://joinmastodon.org/oauth&scope=read%20write%20follow%20push"
        )
    }

    func testRevokeToken() throws {
        _testRevokeTokenFail()
    }

    func _testRevokeTokenFail() {
        let theExpectation = expectation(description: "Revoke Instance Information")
        let query = Mastodon.API.OAuth.RevokeTokenQuery(clientID: "StubClientID", clientSecret: "", token: "")
        Mastodon.API.OAuth.revokeToken(session: session, domain: domain, query: query)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure:
                    theExpectation.fulfill()
                case .finished:
                    XCTFail("Success in a failed test?")
                }
            } receiveValue: { response in
            }
            .store(in: &disposeBag)

        wait(for: [theExpectation], timeout: 10.0)
    }

}
