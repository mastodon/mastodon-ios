//
//  MastodonRegisterViewController+Avatar.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/2.
//

import CropViewController
import Foundation
import OSLog
import PhotosUI
import UIKit
import MastodonAsset
import MastodonLocalization

extension MastodonRegisterViewController {
    private func cropImage(image: UIImage, pickerViewController: UIViewController) {
        DispatchQueue.main.async {
            let cropController = CropViewController(croppingStyle: .default, image: image)
            cropController.delegate = self
            cropController.setAspectRatioPreset(.presetSquare, animated: true)
            cropController.aspectRatioPickerButtonHidden = true
            cropController.aspectRatioLockEnabled = true
            
            // fix iPad compatibility issue
            // ref: https://github.com/TimOliver/TOCropViewController/issues/365#issuecomment-550239604
            cropController.modalTransitionStyle = .crossDissolve
            cropController.transitioningDelegate = nil
            
            pickerViewController.dismiss(animated: true, completion: {
                self.present(cropController, animated: true, completion: nil)
            })
        }
    }
}

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
                DispatchQueue.main.async {
                    guard let error = error else { return }
                    let alertController = UIAlertController(for: error, title: "", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default, handler: nil)
                    alertController.addAction(okAction)
                    _ = self.coordinator.present(
                        scene: .alertController(alertController: alertController),
                        from: nil,
                        transition: .alertController(animated: true, completion: nil)
                    )
                }
                return
            }
            self.cropImage(image: image, pickerViewController: picker)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension MastodonRegisterViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)

        guard let image = info[.originalImage] as? UIImage else { return }

        cropImage(image: image, pickerViewController: picker)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        os_log("%{public}s[%{public}ld], %{public}s", (#file as NSString).lastPathComponent, #line, #function)
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIDocumentPickerDelegate
extension MastodonRegisterViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        do {
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            let imageData = try Data(contentsOf: url)
            guard let image = UIImage(data: imageData) else { return }
            cropImage(image: image, pickerViewController: controller)
        } catch {
            os_log("%{public}s[%{public}ld], %{public}s: %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
        }
    }
}

// MARK: - CropViewControllerDelegate
extension MastodonRegisterViewController: CropViewControllerDelegate {
    public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        self.viewModel.avatarImage = image
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

