//
//  MastodonSDK+API+TimelineTests.swift
//  
//
//  Created by MainasuK Cirno on 2021/2/3.
//

import XCTest
import Combine
@testable import MastodonSDK

extension MastodonSDKTests {
    
    func testPublicTimeline() throws {
        try _testPublicTimeline(domain: domain)
    }
    
    private func _testPublicTimeline(domain: String) throws {
        let theExpectation = expectation(description: "Fetch Public Timeline")
        
        let query = Mastodon.API.Timeline.PublicTimelineQuery()
        Mastodon.API.Timeline.public(
            session: session,
            domain: domain,
            query: query,
            authorization: nil
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
            XCTAssert(!response.value.isEmpty)
            theExpectation.fulfill()
        }
        .store(in: &disposeBag)

        wait(for: [theExpectation], timeout: 10.0)
    }

}

extension MastodonSDKTests {
    
    func testHomeTimeline() {
        let accessToken = testToken
        guard !domain.isEmpty, !accessToken.isEmpty else { return }
        
        let query = Mastodon.API.Timeline.HomeTimelineQuery()
        let authorization = Mastodon.API.OAuth.Authorization(accessToken: accessToken)
        let theExpectation = expectation(description: "Fetch Home Timeline")
        Mastodon.API.Timeline.home(session: session, domain: domain, query: query, authorization: authorization)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                case .finished:
                    break
                }
            } receiveValue: { response in
                XCTAssert(!response.value.isEmpty)
                theExpectation.fulfill()
            }
            .store(in: &disposeBag)

        wait(for: [theExpectation], timeout: 10.0)
    }
    
}
