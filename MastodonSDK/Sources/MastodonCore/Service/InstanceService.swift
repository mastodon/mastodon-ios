//
//  InstanceService.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-10-9.
//

import Foundation
import Combine
import MastodonSDK

@MainActor
public final class InstanceService {
    
    static let shared = InstanceService()
    
}

extension InstanceService {
    
    @MainActor
    func updateInstance(domain: String) async {
        let apiService = APIService.shared
        guard let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value, authBox.domain == domain else { return }
        
        let response = try? await apiService.instance(domain: domain, authenticationBox: authBox)
            .singleOutput()
            
        if response?.value.version?.majorServerVersion(greaterThanOrEquals: 4) == true {
            guard let instanceV2 = try? await apiService.instanceV2(domain: domain, authenticationBox: authBox).singleOutput() else {
                return
            }
            
            self.updateInstanceV2(domain: domain, response: instanceV2)
            if let translationResponse = try? await apiService.translationLanguages(domain: domain, authenticationBox: authBox).singleOutput() {
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
    func serverVersionGreaterThanOrEqual(toMajorVersion majorThreshold: Int, minorVersion minorThreshold: Int?) -> Bool {
        let majorAndMinor = split(separator: ".").prefix(2)
        let major = majorAndMinor.first
        let minor = majorAndMinor.count > 1 ? majorAndMinor[1] : "0"
        guard let major, let majorVersionInt = Int(major) else { return false }
        guard let minorThreshold, minorThreshold > 0 else { return majorVersionInt >= majorThreshold }
        guard let minorVersionInt = Int(minor) else { return false }
        return majorVersionInt >= majorThreshold && minorVersionInt >= minorThreshold
    }
}
