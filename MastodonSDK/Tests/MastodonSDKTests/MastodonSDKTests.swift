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
