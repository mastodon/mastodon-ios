import XCTest
import Combine
@testable import MastodonSDK

final class MastodonSDKTests: XCTestCase {
    
    var disposeBag = Set<AnyCancellable>()
    
    let mstdnDomain = "mstdn.jp"
    let pawooDomain = "pawoo.net"
    let session = URLSession(configuration: .ephemeral)

}

extension MastodonSDKTests {
    
    func testCreateAnAnpplication_mstdn() throws {
        try _testCreateAnAnpplication(domain: pawooDomain)
    }
    
    func testCreateAnAnpplication_pawoo() throws {
        try _testCreateAnAnpplication(domain: pawooDomain)
    }
    
    func _testCreateAnAnpplication(domain: String) throws {
        let theExpectation = expectation(description: "Create An Application")
        
        let query = Mastodon.API.App.CreateQuery(
            clientName: "XCTest",
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

        wait(for: [theExpectation], timeout: 10.0)
    }
}

extension MastodonSDKTests {
    
    func testPublicTimeline_mstdn() throws {
        try _testPublicTimeline(domain: mstdnDomain)
    }
    
    func testPublicTimeline_pawoo() throws {
        try _testPublicTimeline(domain: pawooDomain)
    }
    
    private func _testPublicTimeline(domain: String) throws {
        let theExpectation = expectation(description: "Fetch Public Timeline")
        
        let query = Mastodon.API.Timeline.PublicTimelineQuery()
        Mastodon.API.Timeline.public(session: session, domain: domain, query: query)
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
