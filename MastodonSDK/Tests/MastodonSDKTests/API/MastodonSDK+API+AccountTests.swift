//
//  MastodonSDK+API+AccountTests.swift
//  
//
//  Created by jk234ert on 2/9/21.
//

import XCTest
import Combine
import UIKit
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
                XCTAssert(!result.value.acct.isEmpty)
                theExpectation1.fulfill()
                
                let query = Mastodon.API.Account.UpdateCredentialQuery(
                    bot: !(result.value.bot ?? false),
                    note: dateString,
                    header: Mastodon.Query.MediaAttachment.jpeg(UIImage(systemName: "house")!.jpegData(compressionQuality: 0.8))
                )
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
    
    func testRetrieveAccountInfo() throws {
        let theExpectation = expectation(description: "Verify Account Credentials")

        Mastodon.API.Account.accountInfo(session: session, domain: "mastodon.online", userID: "1", authorization: nil)
        .receive(on: DispatchQueue.main)
        .sink { completion in
            switch completion {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .finished:
                break
            }
        } receiveValue: { response in
            XCTAssertEqual(response.value.acct, "Gargron")
            theExpectation.fulfill()
        }
        .store(in: &disposeBag)

        wait(for: [theExpectation], timeout: 5.0)
    }
    
}
