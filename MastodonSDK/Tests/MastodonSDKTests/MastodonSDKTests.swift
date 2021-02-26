import XCTest
import Combine
@testable import MastodonSDK

final class MastodonSDKTests: XCTestCase {
    
    var disposeBag = Set<AnyCancellable>()

    let session = URLSession(configuration: .ephemeral)
    var domain: String { MastodonSDKTests.environmentVariable(key: "domain") }

    // TODO: replace with test account token
    var testToken = ""
    
    static func environmentVariable(key: String) -> String {
        return ProcessInfo.processInfo.environment[key]!
    }

}
