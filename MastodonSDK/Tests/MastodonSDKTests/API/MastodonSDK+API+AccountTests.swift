//
//  MastodonSDK+API+AccountTests.swift
//  
//
//  Created by jk234ert on 2/9/21.
//

import os.log
import XCTest
import Combine
@testable import MastodonSDK

extension MastodonSDKTests {
    func testVerifyCredentials() throws {
        let theExpectation = expectation(description: "Verify Account Credentials")

        let authorization = Mastodon.API.OAuth.Authorization(accessToken: testToken)
        Mastodon.API.Account.verifyCredentials(session: session, domain: domain, authorization: authorization)
        .receive(on: DispatchQueue.main)
        .sink { completion in
            switch completion {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .finished:
                break
            }
        } receiveValue: { response in
            XCTAssertEqual(response.value.acct, "ugling88")
            theExpectation.fulfill()
        }
        .store(in: &disposeBag)

        wait(for: [theExpectation], timeout: 5.0)
    }

    func testUpdateCredentials() throws {
        let theExpectation1 = expectation(description: "Verify Account Credentials")
        let theExpectation2 = expectation(description: "Update Account Credentials")

        let authorization = Mastodon.API.OAuth.Authorization(accessToken: testToken)
        let dateString = "\(Date().timeIntervalSince1970)"

        Mastodon.API.Account.verifyCredentials(session: session, domain: domain, authorization: authorization)
            .flatMap({ (result) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> in

                // TODO: replace with test account acct
                XCTAssertEqual(result.value.acct, "")
                theExpectation1.fulfill()

                var query = Mastodon.API.Account.CredentialQuery()
                query.note = dateString
                return Mastodon.API.Account.updateCredentials(session: self.session, domain: self.domain, query: query, authorization: authorization)
            })
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { response in
                // The server will generate the corresponding HTML.
                // Here the updated `note` would be wrapped by a `p` tag by server
                XCTAssertEqual(response.value.note, "<p>\(dateString)</p>")
                theExpectation2.fulfill()
            }
            .store(in: &disposeBag)


        wait(for: [theExpectation1, theExpectation2], timeout: 10.0)
    }
}
