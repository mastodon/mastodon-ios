//
//  MastodonSDK+API+OAuthTests.swift
//
//
//  Created by MainasuK Cirno on 2021/1/29.
//

import os.log
import XCTest
import Combine
@testable import MastodonSDK

extension MastodonSDKTests {
    
    func testOAuthAuthorize() throws {
        try _testOAuthAuthorize(domain: domain)
    }
    
    func _testOAuthAuthorize(domain: String) throws {
        let query = Mastodon.API.OAuth.AuthorizeQuery(clientID: "StubClientID")
        let authorizeURL = Mastodon.API.OAuth.authorizeURL(domain: domain, query: query)
        os_log("%{public}s[%{public}ld], %{public}s: (%s) authorizeURL %s", ((#file as NSString).lastPathComponent), #line, #function, domain, authorizeURL.absoluteString)
        XCTAssertEqual(
            authorizeURL.absoluteString,
            "https://\(domain)/oauth/authorize?response_type=code&client_id=StubClientID&redirect_uri=urn:ietf:wg:oauth:2.0:oob&scope=read%20write%20follow%20push"
        )
    }

}
