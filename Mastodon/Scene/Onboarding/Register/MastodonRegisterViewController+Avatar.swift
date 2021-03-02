//
//  MastodonRegisterViewController+Avatar.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/2.
//

import CropViewController
import Foundation
import PhotosUI
import UIKit

extension MastodonRegisterViewController: CropViewControllerDelegate, PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) else {
            picker.dismiss(animated: true, completion: {})
            return
        }
        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            guard let self = self, let image = image as? UIImage else { return }
            DispatchQueue.main.async {
                let cropController = CropViewController(croppingStyle: .default, image: image)
                cropController.delegate = self
                cropController.setAspectRatioPreset(.presetSquare, animated: true)
                cropController.aspectRatioLockEnabled = true
                picker.dismiss(animated: true, completion: {
                    self.present(cropController, animated: true, completion: nil)
                })
            }
        }
    }

    public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        self.viewModel.avatarImage.value = image
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
