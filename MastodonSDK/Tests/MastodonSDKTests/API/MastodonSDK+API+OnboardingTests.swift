//
//  MastodonSDK+API+OnboardingTests.swift
//  
//
//  Created by MainasuK Cirno on 2021-2-18.
//

import XCTest
import Combine
@testable import MastodonSDK

extension MastodonSDKTests {
    
    func testServers() throws {
        try _testServers(query: Mastodon.API.Onboarding.ServersQuery(language: nil, category: nil, registrations: nil))
        try _testServers(query: Mastodon.API.Onboarding.ServersQuery(language: "en", category: "tech", registrations: nil))
    }
    
    func _testServers(query: Mastodon.API.Onboarding.ServersQuery) throws {
        let theExpectation = expectation(description: "Fetch Server List")
        Mastodon.API.Onboarding.servers(
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
    
    func testCategories() throws {
        let theExpectation = expectation(description: "Fetch Server Categories")
        Mastodon.API.Onboarding.categories(
            session: session
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
    
    func testCategoryKind() {
        XCTAssertEqual(Mastodon.Entity.Category.Kind.allCases.count, 12) 
    }
    

}
