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

// MARK: - PHPickerViewControllerDelegate
extension MastodonRegisterViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) else {
            picker.dismiss(animated: true, completion: {})
            return
        }
        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            guard let self = self else { return }
            guard let image = image as? UIImage else {
                guard let error = error else { return }
                let alertController = UIAlertController(for: error, title: "", preferredStyle: .alert)
                let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default, handler: nil)
                alertController.addAction(okAction)
                DispatchQueue.main.async {
                    self.coordinator.present(
                        scene: .alertController(alertController: alertController),
                        from: nil,
                        transition: .alertController(animated: true, completion: nil)
                    )
                }
                return
            }
            DispatchQueue.main.async {
                let cropController = CropViewController(croppingStyle: .default, image: image)
                cropController.delegate = self
                cropController.setAspectRatioPreset(.presetSquare, animated: true)
                cropController.aspectRatioPickerButtonHidden = true
                cropController.aspectRatioLockEnabled = true
                picker.dismiss(animated: true, completion: {
                    self.present(cropController, animated: true, completion: nil)
                })
            }
        }
    }
}

// MARK: - CropViewControllerDelegate
extension MastodonRegisterViewController: CropViewControllerDelegate {
    public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        self.viewModel.avatarImage.value = image
        self.avatarButton.setImage(image, for: .normal)
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

extension MastodonRegisterViewController {
    @objc func avatarButtonPressed(_ sender: UIButton) {
        self.present(imagePicker, animated: true, completion: nil)
    }
}
