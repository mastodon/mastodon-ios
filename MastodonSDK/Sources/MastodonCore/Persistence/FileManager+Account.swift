// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

public extension FileManager {
    func store(account: Mastodon.Entity.Account, forUserID userID: UserIdentifier) {
        var accounts = accounts(for: userID)

        if let index = accounts.firstIndex(of: account) {
            accounts.remove(at: index)
        }

        accounts.append(account)

        storeJSON(accounts, userID: userID)
    }

    func accounts(for userId: UserIdentifier) -> [Mastodon.Entity.Account] {
        guard let sharedDirectory else { assert(false); return [] }

        let accountPath = Persistence.accounts(userId).filepath(baseURL: sharedDirectory)

        guard let data = try? Data(contentsOf: accountPath) else { return [] }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601

        do {
            let accounts = try jsonDecoder.decode([Mastodon.Entity.Account].self, from: data)
            assert(accounts.count > 0)
            return accounts
        } catch {
            return []
        }

    }
}

private extension FileManager {
    private func storeJSON(_ encodable: Encodable, userID: UserIdentifier) {
        guard let sharedDirectory else { return }

        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        do {
            let data = try jsonEncoder.encode(encodable)

            let accountsPath = Persistence.accounts( userID).filepath(baseURL: sharedDirectory)
            try data.write(to: accountsPath)
        } catch {
            debugPrint(error.localizedDescription)
        }

    }

}
