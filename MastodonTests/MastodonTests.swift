//
//  MastodonTests.swift
//  MastodonTests
//
//  Created by MainasuK Cirno on 2021/1/22.
//

import XCTest
@testable import Mastodon
import MastodonCore

@MainActor
class MastodonTests: XCTestCase {
    func testWebFinger() {
        let expectation = expectation(description: "webfinger")
        let cancellable = APIService.shared.webFinger(domain: "pawoo.net")
            .receive(on: DispatchQueue.main)
            .sink { completion in
                expectation.fulfill()
            } receiveValue: { domain in
                print("\(#function) identified domain: \(domain)")
            }
        withExtendedLifetime(cancellable) {
            wait(for: [expectation], timeout: 10)
        }
    }

    // TODO: Find a new reachable example onion server
    func testConnectOnion() async throws {
        let request = URLRequest(
            url: URL(string: "http://a232ncr7jexk2chvubaq2v6qdizbocllqap7mnn7w7vrdutyvu32jeyd.onion/@k0gen")!,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 10
        )
        do {
            let data = try await URLSession.shared.data(for: request, delegate: nil)
            print(data)
        } catch {
            debugPrint(error)
            XCTFail(error.localizedDescription)
        }
    }
}
