// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

extension FileManager {
    public func store(account: Mastodon.Entity.Account, forUserID userID: String) {
        // store accounts for each loged in user
        var accounts = accounts(forUserID: userID)

        if let index = accounts.firstIndex(of: account) {
            accounts.remove(at: index)
        }

        accounts.append(account)

        storeJSON(accounts, userID: userID)
    }

    public func accounts(forUserID userID: String) -> [Mastodon.Entity.Account] {
        guard let documentsDirectory else { return [] }

        let accountPath = Persistence.accounts(userID: userID).filepath(baseURL: documentsDirectory)

        guard let data = try? Data(contentsOf: accountPath) else { return [] }

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601

        do {
            let accounts = try jsonDecoder.decode([Mastodon.Entity.Account].self, from: data)
            return accounts
        } catch {
            return []
        }

    }

    private func storeJSON(_ encodable: Encodable, userID: String) {
        guard let documentsDirectory else { return }

        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        do {
            let data = try jsonEncoder.encode(encodable)

            let accountsPath = Persistence.accounts(userID: userID).filepath(baseURL: documentsDirectory)
            try data.write(to: accountsPath)
        } catch {
            debugPrint(error.localizedDescription)
        }

    }

}
