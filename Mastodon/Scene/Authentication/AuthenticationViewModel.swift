//
//  AuthenticationViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/1.
//

import Foundation
import Combine

final class AuthenticationViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let input = CurrentValueSubject<String, Never>("")
    
    // output
    let domain = CurrentValueSubject<String?, Never>(nil)
    let isSignInButtonEnabled = CurrentValueSubject<Bool, Never>(false)
    
    init() {
        input
            .map { input in
                let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !trimmed.isEmpty else { return nil }
                
                let urlString = trimmed.hasPrefix("https://") ? trimmed : "https://" + trimmed
                guard let url = URL(string: urlString),
                      let host = url.host else {
                    return nil
                }
                let components = host.components(separatedBy: ".")
                guard (components.filter { !$0.isEmpty }).count >= 2 else { return nil }
                
                return host
            }
            .assign(to: \.value, on: domain)
            .store(in: &disposeBag)
        
        domain
            .print()
            .map { $0 != nil }
            .assign(to: \.value, on: isSignInButtonEnabled)
            .store(in: &disposeBag)
    }
    
}
