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

extension MastodonRegisterViewController {
    func createMediaContextMenu() -> UIMenu {
        var children: [UIMenuElement] = []
        let photoLibraryAction = UIAction(title: L10n.Scene.Compose.MediaSelection.photoLibrary, image: UIImage(systemName: "rectangle.on.rectangle"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak self] _ in
            guard let self = self else { return }
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        children.append(photoLibraryAction)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAction(title: L10n.Scene.Compose.MediaSelection.camera, image: UIImage(systemName: "camera"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak self] _ in
                guard let self = self else { return }
                self.present(self.imagePickerController, animated: true, completion: nil)
            })
            children.append(cameraAction)
        }
        let browseAction = UIAction(title: L10n.Scene.Compose.MediaSelection.browse, image: UIImage(systemName: "ellipsis"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak self] _ in
            guard let self = self else { return }
            self.present(self.documentPickerController, animated: true, completion: nil)
        }
        children.append(browseAction)
        if self.viewModel.avatarImage.value != nil {
            let deleteAction = UIAction(title: L10n.Scene.Register.Input.Avatar.delete, image: UIImage(systemName: "delete.left"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.avatarImage.value = nil
            }
            children.append(deleteAction)
        }

        return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: children)
    }
    
    private func cropImage(image: UIImage, pickerViewController: UIViewController) {
        DispatchQueue.main.async {
            let cropController = CropViewController(croppingStyle: .default, image: image)
            cropController.delegate = self
            cropController.setAspectRatioPreset(.presetSquare, animated: true)
            cropController.aspectRatioPickerButtonHidden = true
            cropController.aspectRatioLockEnabled = true
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
                    self.coordinator.present(
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
        self.viewModel.avatarImage.value = image
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

