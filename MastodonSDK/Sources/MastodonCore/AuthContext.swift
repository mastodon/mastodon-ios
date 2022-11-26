//
//  AuthContext.swift
//  
//
//  Created by MainasuK on 22/10/8.
//

import os.log
import Foundation
import Combine
import CoreDataStack
import MastodonSDK

public protocol AuthContextProvider {
    var authContext: AuthContext { get }
}

public class AuthContext {
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "AuthContext", category: "AuthContext")
    
    // Mastodon
    public private(set) var mastodonAuthenticationBox: MastodonAuthenticationBox

    private init(mastodonAuthenticationBox: MastodonAuthenticationBox) {
        self.mastodonAuthenticationBox = mastodonAuthenticationBox
    }
    
}

extension AuthContext {

    public convenience init?(authentication: MastodonAuthentication) {
        self.init(mastodonAuthenticationBox: MastodonAuthenticationBox(authentication: authentication))
        
        ManagedObjectObserver.observe(object: authentication)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(error.localizedDescription)")
                case .finished:
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): observer finished")
                }
            } receiveValue: { [weak self] change in
                guard let self = self else { return }
                switch change.changeType {
                case .update(let object):
                    guard let authentication = object as? MastodonAuthentication else {
                        assertionFailure()
                        return
                    }
                    self.mastodonAuthenticationBox = .init(authentication: authentication)
                default:
                    break
                }
            }
            .store(in: &disposeBag)
    }

}
