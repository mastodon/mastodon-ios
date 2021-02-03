import XCTest
import Combine
@testable import MastodonSDK

final class MastodonSDKTests: XCTestCase {
    
    var disposeBag = Set<AnyCancellable>()

    let session = URLSession(configuration: .ephemeral)
    var domain: String { MastodonSDKTests.environmentVariable(key: "domain") }
    
    static func environmentVariable(key: String) -> String {
        return ProcessInfo.processInfo.environment[key]!
    }

}

extension MastodonSDKTests {
    
    func testPublicTimeline() throws {
        try _testPublicTimeline(domain: domain)
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
