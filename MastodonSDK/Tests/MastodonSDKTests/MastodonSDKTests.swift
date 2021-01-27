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
        Mastodon.API.App.create(session: session, query: query)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                
            } receiveValue: { response in
                theExpectation.fulfill()
            }
            .store(in: &disposeBag)

        wait(for: [theExpectation], timeout: 10.0)
    }
    
    
    
}
