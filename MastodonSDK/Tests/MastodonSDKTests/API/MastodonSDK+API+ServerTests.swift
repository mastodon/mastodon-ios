//
//  MastodonSDK+API+ServerTests.swift
//  
//
//  Created by MainasuK Cirno on 2021-2-18.
//

import os.log
import XCTest
import Combine
@testable import MastodonSDK

extension MastodonSDKTests {
    
    func testServers() throws {
        try _testServers(query: Mastodon.API.Server.ServersQuery(language: nil, category: nil))
        try _testServers(query: Mastodon.API.Server.ServersQuery(language: "en", category: "tech"))
    }
    
    func _testServers(query: Mastodon.API.Server.ServersQuery) throws {
        let theExpectation = expectation(description: "Fetch Server List")
        Mastodon.API.Server.servers(
            session: session,
            query: query
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
