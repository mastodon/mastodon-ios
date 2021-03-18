//
//  MastodonAttachmentService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-17.
//

import UIKit
import Combine
import PhotosUI

final class MastodonAttachmentService {
    
    var disposeBag = Set<AnyCancellable>()
    
    let identifier = UUID()
    
    // input
    let pickerResult: PHPickerResult
    
    // output
    let imageData = CurrentValueSubject<Data?, Never>(nil)
    let error = CurrentValueSubject<Error?, Never>(nil)
    
    init(pickerResult: PHPickerResult) {
        self.pickerResult = pickerResult
        // end init
        
        PHPickerResultLoader.loadImageData(from: pickerResult)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    self.error.value = error
                case .finished:
                    break
                }
            } receiveValue: { [weak self] imageData in
                guard let self = self else { return }
                self.imageData.value = imageData
            }
            .store(in: &disposeBag)
    }
    
}

extension MastodonAttachmentService: Equatable, Hashable {
    
    static func == (lhs: MastodonAttachmentService, rhs: MastodonAttachmentService) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
}
