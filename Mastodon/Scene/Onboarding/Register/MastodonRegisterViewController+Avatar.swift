//
//  MastodonRegisterViewController+Avatar.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/2.
//

import Foundation
import UIKit
import CropViewController
import PhotosUI
extension MastodonRegisterViewController: CropViewControllerDelegate, PHPickerViewControllerDelegate, UINavigationControllerDelegate{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        if let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let self = self, let image = image as? UIImage else { return }
                DispatchQueue.main.async {
                    let cropController = CropViewController(croppingStyle: .default, image: image)
                    cropController.delegate = self
                    self.image = image
                    picker.dismiss(animated: true, completion: {
                        self.present(cropController, animated: true, completion: nil)
                    })
                }
            }
        } else {
            picker.dismiss(animated: true, completion: {
            })
        }
    }
    
    public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        self.image = image
        self.photoButton.setImage(image, for: .normal)
        cropViewController.dismiss(animated: true, completion: nil)
    }

    @objc func avatarButtonPressed(_ sender: UIButton) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        
        let imagePicker = PHPickerViewController(configuration: configuration)
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
}
