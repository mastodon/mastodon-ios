//
//  InstanceService.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-10-9.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

public final class InstanceService {
    
    var disposeBag = Set<AnyCancellable>()

    // input
    let backgroundManagedObjectContext: NSManagedObjectContext
    weak var apiService: APIService?
    weak var authenticationService: AuthenticationService?
    
    // output

    init(
        apiService: APIService,
        authenticationService: AuthenticationService
    ) {
        self.backgroundManagedObjectContext = apiService.backgroundManagedObjectContext
        self.apiService = apiService
        self.authenticationService = authenticationService
        
        authenticationService.$mastodonAuthenticationBoxes
            .receive(on: DispatchQueue.main)
            .compactMap { $0.first?.domain }
            .removeDuplicates()     // prevent infinity loop
            .asyncMap { [weak self] in await self?.updateInstance(domain: $0) }
            .sink {}
            .store(in: &disposeBag)
    }
    
}

extension InstanceService {
    
    @MainActor
    func updateInstance(domain: String) async {
        guard let apiService else { return }
        
       let response = try? await apiService.instance(domain: domain, authenticationBox: authenticationService?.mastodonAuthenticationBoxes.first)
            .singleOutput()
            
        if response?.value.version?.majorServerVersion(greaterThanOrEquals: 4) == true {
            guard let instanceV2 = try? await apiService.instanceV2(domain: domain, authenticationBox: authenticationService?.mastodonAuthenticationBoxes.first).singleOutput() else {
                return
            }
            
            self.updateInstanceV2(domain: domain, response: instanceV2)
            if let translationResponse = try? await apiService.translationLanguages(domain: domain, authenticationBox: authenticationService?.mastodonAuthenticationBoxes.first).singleOutput() {
                updateTranslationLanguages(domain: domain, response: translationResponse)
            }
        } else if let response {
            self.updateInstance(domain: domain, response: response)
        }
    }

    @MainActor
    private func updateTranslationLanguages(domain: String, response: Mastodon.Response.Content<TranslationLanguages>) {
        AuthenticationServiceProvider.shared
            .updating(translationLanguages: response.value, for: domain)
    }
    
    @MainActor
    private func updateInstance(domain: String, response: Mastodon.Response.Content<Mastodon.Entity.Instance>) {
        AuthenticationServiceProvider.shared
            .updating(instanceV1: response.value, for: domain)
    }
    
    @MainActor
    private func updateInstanceV2(domain: String, response: Mastodon.Response.Content<Mastodon.Entity.V2.Instance>) {
            AuthenticationServiceProvider.shared
            .updating(instanceV2: response.value, for: domain)
    }
}

public extension String {
    func majorServerVersion(greaterThanOrEquals comparedVersion: Int) -> Bool {
        guard
            let majorVersionString = split(separator: ".").first,
            let majorVersionInt = Int(majorVersionString)
        else { return false }
        
        return majorVersionInt >= comparedVersion
    }
}
