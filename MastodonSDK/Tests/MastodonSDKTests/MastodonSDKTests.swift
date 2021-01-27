import XCTest
import Combine
@testable import MastodonSDK

final class MastodonSDKTests: XCTestCase {
    
    var disposeBag = Set<AnyCancellable>()
    
    let domain = "mstdn.jp"
    let session = URLSession(configuration: .ephemeral)
    
    func testCreateAnAnpplication() throws {
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
