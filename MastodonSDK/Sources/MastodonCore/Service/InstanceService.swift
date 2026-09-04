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
    
    /// This fetches the instance and applies it to any already-known accounts on that domain, but returns the instance so that the caller can apply it if needed (in the fresh login case, the update step won't have found anything to update)
    @MainActor
    func updateInstance(authBox: MastodonAuthenticationBox) async -> MastodonAuthentication.InstanceConfiguration? {
        let apiService = APIService.shared
        
        if let instanceV2 = try? await apiService.instanceV2(domain: authBox.domain, authenticationBox: authBox).singleOutput() {
            self.updateInstanceV2(domain: authBox.domain, response: instanceV2)
            if let translationResponse = try? await apiService.translationLanguages(domain: authBox.domain, authenticationBox: authBox).singleOutput() {
                updateTranslationLanguages(domain: authBox.domain, response: translationResponse)
                return .fromEndpointV2(instanceV2.value, translationResponse.value)
            } else {
                return .fromEndpointV2(instanceV2.value, [:])
            }
        } else if let response = try? await apiService.instance(domain: authBox.domain, authenticationBox: authBox)
            .singleOutput() {
            return self.updateInstance(domain: authBox.domain, response: response)
        }
        return nil
    }

    @MainActor
    private func updateTranslationLanguages(domain: String, response: Mastodon.Response.Content<TranslationLanguages>) {
        AuthenticationServiceProvider.shared
            .updating(translationLanguages: response.value, for: domain)
    }
    
    @MainActor
    private func updateInstance(domain: String, response: Mastodon.Response.Content<Mastodon.Entity.Instance>) -> MastodonAuthentication.InstanceConfiguration {
        AuthenticationServiceProvider.shared
            .updating(instanceV1: response.value, for: domain)
        return .fromEndpointV1(response.value)
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
