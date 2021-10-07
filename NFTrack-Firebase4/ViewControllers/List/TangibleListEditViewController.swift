//
//  TangibleListEditViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-08-16.
//

/*
 Abstract:
 Edits or Deletes Tangible asset postings
 */

import UIKit
import Firebase
import QuickLook
import Combine

class TangibleListEditViewController: ParentListEditViewController, PreviewDelegate, ButtonPanelConfigurable, FileUploadable {    
    final var imagePreviewVC: ImagePreviewViewController!
    final var imagePreviewConstraintHeight: NSLayoutConstraint!
    // for the tangible list, the address title and the address field have to be added
    
    final var previewDataArr: [PreviewData]! {
        didSet {
            guard let previewDataArr = previewDataArr else { return }
            /// shows the image preview when an image or a doc is selected
            if previewDataArr.count > 0 {
                DispatchQueue.main.async { [weak self] in
                    self?.imagePreviewVC.view.isHidden = false
                    self?.imagePreviewConstraintHeight.constant = self!.IMAGE_PREVIEW_HEIGHT
                    UIView.animate(withDuration: 0.5) {
                        self?.view.layoutIfNeeded()
                    } completion: { (_) in
                        guard let `self` = self else { return }
                        self.scrollView.contentSize = CGSize(width: self.view.bounds.width, height: self.SCROLLVIEW_CONTENTSIZE_WITH_IMAGE_PREVIEW)
                        self.imagePreviewVC.data = previewDataArr
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.imagePreviewConstraintHeight.constant = 0
                    self?.imagePreviewVC.view.isHidden = true
                    UIView.animate(withDuration: 0.5) {
                        self?.view.layoutIfNeeded()
                    } completion: { (_) in
                        guard let `self` = self else { return }
                        self.scrollView.contentSize = CGSize(width: self.view.bounds.width, height: self.SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT)
                    }
                }
            }
        }
    }
    
    final var IMAGE_PREVIEW_HEIGHT: CGFloat! = 180
    final lazy var SCROLLVIEW_CONTENTSIZE_WITH_IMAGE_PREVIEW: CGFloat! = SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT + IMAGE_PREVIEW_HEIGHT

    final let configuration = UIImage.SymbolConfiguration(pointSize: 50, weight: .light, scale: .medium)
    final var pickerImageName: String! {
        var imageName: String!
        if #available(iOS 14.0, *) {
            imageName = "rectangle.fill.on.rectangle.fill.circle"
        } else {
            imageName = "tv.circle"
        }
        return imageName
    }
    final var buttonPanel: UIStackView!
    final var panelButtons: [PanelButton] {
        let buttonPanels = [
            PanelButton(imageName: "camera.circle", imageConfig: configuration, tintColor: UIColor(red: 198/255, green: 122/255, blue: 206/255, alpha: 1), tag: 8),
            PanelButton(imageName: pickerImageName, imageConfig: configuration, tintColor: UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), tag: 9),
            PanelButton(imageName: "doc.circle", imageConfig: configuration, tintColor: UIColor(red: 61/255, green: 156/255, blue: 133/255, alpha: 1), tag: 10)
        ]
        return buttonPanels
    }
    final var constraints: [NSLayoutConstraint]!
    final var documentPicker: DocumentPicker!
    final var url: URL!
    final var userId: String!
    final var storage = Set<AnyCancellable>()
    final var storageRef: StorageReference! {
        let storage = Storage.storage()
        return storage.reference()
    }
    final var addressTitleLabel: UILabel!
    final var addressLabel: UILabel!
    final var addressDeleteButton: UIButton!
    final var shippingInfo: ShippingInfo!
    final var buttonPanelHeight: NSLayoutConstraint!
    
    // The tangible item needs the address modified
    final override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let addressHeight: CGFloat = addressTitleLabel.bounds.size.height + addressLabel.bounds.size.height + 80
        SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT = addressHeight + getDefaultHeight()
    }
    
    final override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if imagePreviewVC != nil {
            /// whenever the image picker is dismissed, the collection view has to be updated
            imagePreviewVC.data = previewDataArr
        }
    }

    final override func configureUI() {
        super.configureUI()
        constraints = [NSLayoutConstraint]()
        previewDataArr = [PreviewData]()
        
        guard let deleteImage = UIImage(systemName: "minus.circle.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal) else {
            return
        }
        addressDeleteButton = UIButton.systemButton(with: deleteImage, target: self, action: #selector(buttonPressed(_:)))
        addressDeleteButton.tag = 12
        addressDeleteButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(addressDeleteButton)
        
        addressTitleLabel = createTitleLabel(text: "Shipping Restriction")
        scrollView.addSubview(addressTitleLabel)
        
        addressLabel = createLabel(text: post.shippingInfo?.addresses.first ?? "")
        addressLabel.isUserInteractionEnabled = true
        addressLabel.tag = 11
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        addressLabel.addGestureRecognizer(tap)
        scrollView.addSubview(addressLabel)
        
        createButtonPanel(panelButtons: panelButtons, superView: scrollView) { (buttonsArr) in
            buttonsArr.forEach { (button) in
                button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            }
        }
        
        // Two reasons for writing the files to the disk instead of using the data form
        //  1. The newly added image/pdf files will be used with the url from the disk.
        //  2. ImagePreviewController used in posting will require the url from the disk.
        if let files = post.files, files.count > 0 {
            downloadFiles(files: files)
        }
        
        // the digital type should never run
        if post.type == "digital" {
            configureImagePreview(postType: .digital(.onlineDirect), superView: scrollView)
        } else {
            configureImagePreview(postType: .tangible, superView: scrollView)
        }
    }
    
    final override func setConstraints() {
        super.setConstraints()
        
        setButtonPanelConstraints(topView: addressLabel)
        
        // if you set the height to the image height here, self?.imagePreviewConstraintHeight.constant = 0 in the property observer of previewDataArr for the empty array gets called
        // AFTER previewDataArr.count > 0 is called.
        // in other words, SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT is called after SCROLLVIEW_CONTENTSIZE_WITH_IMAGE_PREVIEW is called causing the content size to be reduced.
        imagePreviewConstraintHeight = imagePreviewVC.view.heightAnchor.constraint(equalToConstant: 0)

        constraints.append(contentsOf: [
            addressTitleLabel.topAnchor.constraint(equalTo: descTextView.bottomAnchor, constant: 40),
            addressTitleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            addressTitleLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            
            addressDeleteButton.topAnchor.constraint(equalTo: descTextView.bottomAnchor, constant: 40),
            addressDeleteButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            
            addressLabel.topAnchor.constraint(equalTo: addressTitleLabel.bottomAnchor, constant: 10),
            addressLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            addressLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            addressLabel.heightAnchor.constraint(equalToConstant: 50),
                        
            imagePreviewVC.view.topAnchor.constraint(equalTo: buttonPanel.bottomAnchor, constant: 40),
            imagePreviewVC.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            imagePreviewVC.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imagePreviewConstraintHeight,

            stackView.topAnchor.constraint(equalTo: imagePreviewVC.view.bottomAnchor, constant: 5),
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 50)
        ])

        NSLayoutConstraint.activate(constraints)
    }
    
    @objc final override func buttonPressed(_ sender: UIButton) {
        guard previewDataArr.count < 6 else {
            self.alert.showDetail(
                "Upload Limit",
                with: "There is a limit of 6 files per post.",
                for: self)
            return
        }
                
        switch sender.tag {
            case 0:
                update()
            case 1:
                let content = [
                    StandardAlertContent(
                        index: 0,
                        titleString: "Delete Post",
                        body: ["": "Are you sure you want to delete your post?"],
                        fieldViewHeight: 100,
                        messageTextAlignment: .left,
                        alertStyle: .withCancelButton
                    )
                ]
                
                let alertVC = AlertViewController(height: 350, standardAlertContent: content)
                alertVC.action = { [weak self] (modal, mainVC) in
                    // responses to the main vc's button
                    mainVC.buttonAction = { _ in
                        guard let postId = self?.post.documentId else { return }
                        // delete the collection in the post document
                        self?.db.collection("post").document(postId).delete(completion: { (error) in
                            if let error = error {
                                self?.alert.showDetail("Update Error", with: error.localizedDescription, height: 400, for: self)
                            }
                            
                            // delete the image and pdf files in the storage
                            self?.deleteAllStorageFiles()
                            
                            self?.alert.showDetail("Success!", with: "Your post has been successfully deleted.", for: self, buttonAction: {
                                self?.dismiss(animated: true, completion: {
                                    self?.navigationController?.popToRootViewController(animated: true)
                                })
                            }, completion:  {})
                        })
                    }
                }
                self.present(alertVC, animated: true, completion: nil)
            case 8:
                let vc = UIImagePickerController()
                vc.sourceType = .camera
                vc.allowsEditing = true
                vc.delegate = self
                present(vc, animated: true)
            case 9:
                let imagePickerController = UIImagePickerController()
                imagePickerController.allowsEditing = false
                imagePickerController.sourceType = .photoLibrary
                imagePickerController.delegate = self
                imagePickerController.modalPresentationStyle = .fullScreen
                present(imagePickerController, animated: true, completion: nil)
            case 10:
                documentPicker = DocumentPicker(presentationController: self, delegate: self)
                documentPicker.displayPicker()
                break
            case 12:
                // delete the address text field
                addressLabel.text = ""
                break
            default:
                break
        }
    }
    
    private func update() {
        let whitespaceCharacterSet = CharacterSet.whitespaces
        
        guard let itemTitle = titleNameTextField.text else {
            self.alert.showDetail("Missing Information", with: "Title cannot be empty", for: self)
            return
        }
        
        let strippedTitle = itemTitle.trimmingCharacters(in: whitespaceCharacterSet)
        guard strippedTitle != "" else {
            self.alert.showDetail("Missing Information", with: "Title cannot be empty", for: self)
            return
        }
        
        guard let desc = descTextView.text else {
            self.alert.showDetail("Missing Information", with: "Description cannot be empty.", for: self)
            return
        }
        
        let strippedDesc = desc.trimmingCharacters(in: whitespaceCharacterSet)
        guard strippedDesc != "" else {
            self.alert.showDetail("Missing Information", with: "Description cannot be empty", for: self)
            return
        }
        
        guard let address = addressLabel.text else {
            self.alert.showDetail("Missing Information", with: "Shipping information cannot be empty.", for: self)
            return
        }
        
        let strippedAddress = address.trimmingCharacters(in: whitespaceCharacterSet)
        guard strippedAddress != "" else {
            self.alert.showDetail("Missing Information", with: "Shipping information cannot be empty", for: self)
            return
        }
        
        let content = [
            StandardAlertContent(
                index: 0,
                titleString: "Update Post",
                body: ["": "Are you sure you want to update your post?"],
                fieldViewHeight: 100,
                messageTextAlignment: .left,
                alertStyle: .withCancelButton
            )
        ]
        
        let alertVC = AlertViewController(height: 350, standardAlertContent: content)
        alertVC.action = { [weak self] (modal, mainVC) in
            // responses to the main vc's button
            mainVC.buttonAction = { _ in
                guard let postId = self?.post.documentId,
                      let userId = self?.userId else { return }
                
                // if there are files to upload
                func withFiles(_ data: [PreviewData]) -> AnyPublisher<[String?], PostingError> {
                    let fileURLs = data.map { (previewData) -> AnyPublisher<String?, PostingError> in
                        return Future<String?, PostingError> { promise in
                            self?.uploadFileWithPromise(
                                fileURL: previewData.filePath,
                                userId: userId,
                                promise: promise
                            )
                        }.eraseToAnyPublisher()
                    }
                    return Publishers.MergeMany(fileURLs)
                        .collect()
                        .eraseToAnyPublisher()
                        .flatMap { (urlStrings) -> AnyPublisher<[String?], PostingError> in
                            Future<[String?], PostingError> { promise in
                                var updateData: [String: Any] = [
                                    "title": itemTitle,
                                    "description": desc,
                                    "files": urlStrings,
                                ]
                                
                                if let si = self?.shippingInfo {
                                    let shippingInfoData: [String: Any] = [
                                        "scope": si.scope.stringValue,
                                        "addresses": si.addresses,
                                        "radius": si.radius,
                                        "longitude": si.longitude ?? 0,
                                        "latitude": si.latitude ?? 0
                                    ]
                                    
                                    updateData.updateValue(shippingInfoData, forKey: "shippingInfo")
                                }
                                                                
                                self?.db.collection("post").document(postId).updateData(updateData) { (error) in
                                    if let error = error {
                                        promise(.failure(.generalError(reason: error.localizedDescription)))
                                    }
                                    
                                    promise(.success(urlStrings))
                                }
                            }
                            .eraseToAnyPublisher()
                        }
                        .eraseToAnyPublisher()
                }
                
                // if there are no files to upload
                func withoutFiles() -> AnyPublisher<[String?], PostingError> {
                    Future<[String?], PostingError> { promise in
                        var updateData: [String: Any] = [
                            "title": itemTitle,
                            "description": desc,
                            "files": "",
                        ]
                        
                        if let si = self?.shippingInfo {
                            let shippingInfoData: [String: Any] = [
                                "scope": si.scope.stringValue,
                                "addresses": si.addresses,
                                "radius": si.radius,
                                "longitude": si.longitude ?? 0,
                                "latitude": si.latitude ?? 0
                            ]
                            
                            updateData.updateValue(shippingInfoData, forKey: "shippingInfo")
                        }
                                                
                        self?.db.collection("post").document(postId).updateData(updateData) { (error) in
                            if let error = error {
                                promise(.failure(.generalError(reason: error.localizedDescription)))
                            }
                            
                            promise(.success([]))
                        }
                    }
                    .eraseToAnyPublisher()
                }
                
                //
                self?.dismiss(animated: true, completion: {
                    self?.showSpinner({
                        var updatePublisher: AnyPublisher<[String?], PostingError>!
                        if let previewDataArr = self?.previewDataArr {
                            // the path either starts from "https://" or "file://"
                            // the former implies that it's already uploaded in Firebase Storage, therefore doesn't need to be uploaded
                            let filtered = previewDataArr.filter { $0.filePath.absoluteString.lowercased().hasPrefix("file:") }
                            updatePublisher = withFiles(filtered)
                        } else {
                            updatePublisher = withoutFiles()
                        }
                        
                        updatePublisher
                            .sink { (completion) in
                                switch completion {
                                    case .failure(let error):
                                        self?.alert.showDetail("Update Error", with: error.localizedDescription, for: self)
                                        break
                                    case .finished:
                                        self?.alert.showDetail("Success!", with: "Your post has been successfully updated.", for: self, buttonAction: {
                                            self?.dismiss(animated: true, completion: {
                                                self?.deleteAllStorageFiles()
                                                self?.navigationController?.popViewController(animated: true)
//                                                guard let window = UIApplication.shared.windows.first,
//                                                      let tabBarController = window.rootViewController as? UITabBarController else { return }
//
//                                                self?.navigationController?.popToRootViewController(animated: true)
//                                                tabBarController.selectedIndex = 1
//                                                guard let vcs = tabBarController.viewControllers, let listVC = vcs[0] as? ListViewController else { return }
//                                                listVC.segmentedControl.selectedSegmentIndex = 3
//                                                listVC.segmentedControl.sendActions(for: UIControl.Event.valueChanged)
                                            })
                                        }, completion:  {
                                            
                                        })
                                        break
                                }
                            } receiveValue: { [weak self] (urlStrings) in
                                print("urlStrings", urlStrings)
                                let imagesString: [String] = urlStrings.compactMap { $0 }
                                self?.delegate?.didUpdatePost(title: itemTitle, desc: desc, imagesString: imagesString)
                            }
                            .store(in: &self!.storage)
                    }) // show spinner
                }) // dismiss
            } // button action
        } // alert action
        self.present(alertVC, animated: true, completion: nil)
    }
    
    private func deleteAllStorageFiles() {
        // delete the image and pdf files in the storage
        if let files = self.post.files {
            for file in files {
                // Create a reference to the file to delete
                let mediaRef = self.storageRef.child(file)
                
                // Delete the file
                mediaRef.delete { error in
                    if let error = error {
                        // Uh-oh, an error occurred!
                        print("storage delete error", error)
                    } else {
                        // File deleted successfully
                        print("storage delete success")
                    }
                }
            }
        }
    }
    
    @objc private func tapped(_ sender: UITapGestureRecognizer) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        guard let v = sender.view else { return }
        switch v.tag {
            case 11:
                let shippingVC = ShippingViewController()
                shippingVC.shippingDelegate = self
                navigationController?.pushViewController(shippingVC, animated: true)
            default:
                break
        }
    }
}

// MARK: - Image picker
extension TangibleListEditViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    final func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let filePath = info[UIImagePickerController.InfoKey.imageURL] as? URL else {
            print("No image found")
            return
        }

        let previewData = PreviewData(header: .image, filePath: filePath)
        previewDataArr.append(previewData)
    }

    final func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

//extension TangibleListEditViewController: DocumentDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
//    final func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
//        return 1
//    }
//
//    final func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
//        //        return self.url as QLPreviewItem
//        let docTitle = UUID().uuidString
//        let previewItem = CustomPreviewItem(url: url, title: docTitle)
//        return previewItem as QLPreviewItem
//    }
    
extension TangibleListEditViewController: DocumentDelegate {

    // MARK: - didPickDocument
    final func didPickDocument(document: Document?) {
        if let pickedDoc = document {
            let fileURL = pickedDoc.fileURL
            guard fileURL.pathExtension == "pdf" else {
                self.alert.showDetail("Sorry", with: "The document has to be a PDF file", for: self)
                return
            }
            url = fileURL
            
            let previewData = PreviewData(header: .document, filePath: fileURL)
            previewDataArr.append(previewData)
            
//            let preview = PreviewPDFViewController()
//            present(preview, animated: true, completion: nil)
        }
    }
}

extension TangibleListEditViewController {
    // MARK: - didDeleteImage
    final func didDeleteFileFromPreview(filePath: URL) {
        previewDataArr = previewDataArr.filter { $0.filePath != filePath }
    }
}

extension TangibleListEditViewController {
    final func downloadFiles(files: [String]) {
        let previewDataPublishers = files.map { (file) -> AnyPublisher<PreviewData, PostingError> in
            if let url = URL(string: file), url.pathExtension == "pdf" {
                return downloadFiles(urlString: file, type: .document)
            } else {
                return downloadFiles(urlString: file, type: .image)
            }
        }
        return Publishers.MergeMany(previewDataPublishers)
            .collect()
            .eraseToAnyPublisher()
            .sink { [weak self] (completion) in
                switch completion {
                    case .failure(.generalError(reason: let error)):
                        self?.alert.showDetail("Image/Doc Fetch Error", with: error, for: self)
                    case .finished:
                        break
                    default:
                        self?.alert.showDetail("Image/Doc Fetch Error", with: "Unable to fetch the data.", for: self)
                }
            } receiveValue: { [weak self] (previewArr) in
                self?.previewDataArr = previewArr
            }
            .store(in: &self.storage)
    }
    
    // save documents
    final func saveFile(fileName: String, data: Data, promise: @escaping (Result<PreviewData, PostingError>) -> Void) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            promise(.failure(.generalError(reason: "Could not create a URL to save the image.")))
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName).appendingPathExtension("pdf")
        
        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch {
                promise(.failure(.generalError(reason: "Couldn't remove file at path.")))
            }
        }
        
        do {
            try data.write(to: fileURL)
            promise(.success(PreviewData(header: .document, filePath: fileURL.absoluteURL)))
        } catch {
            promise(.failure(.generalError(reason: "Error saving file with error")))
        }
    }
    
    // save images
    final func saveImage(imageName: String, image: UIImage, promise: @escaping (Result<PreviewData, PostingError>) -> Void) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            promise(.failure(.generalError(reason: "Could not create a URL to save the image.")))
            return
        }
        
        let fileName = imageName
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            promise(.failure(.generalError(reason: "Could not process the downloaded image data.")))
            return
        }
        
        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch {
                promise(.failure(.generalError(reason: "Couldn't remove file at path.")))
            }
        }
        
        do {
            try data.write(to: fileURL)
            promise(.success(PreviewData(header: .image, filePath: fileURL)))
        } catch {
            promise(.failure(.generalError(reason: "Error saving file with error")))
        }
    }
    
    final func downloadFiles(urlString: String, type: Header) -> AnyPublisher<PreviewData, PostingError> {
        Future<Data, PostingError> { promise in
            FirebaseService.shared.downloadURL(urlString: urlString, promise: promise)
        }
        .eraseToAnyPublisher()
        .flatMap { [weak self] (data) -> AnyPublisher<PreviewData, PostingError> in
            Future<PreviewData, PostingError> { promise in
                if type == .document {
                    self?.saveFile(fileName: UUID().uuidString, data: data, promise: promise)
                } else {
                    guard let image = UIImage(data: data) else {
                        promise(.failure(.generalError(reason: "Unable to process the image preivew.")))
                        return
                    }
                    self?.saveImage(imageName: UUID().uuidString, image: image, promise: promise)
                }
            }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}

extension TangibleListEditViewController: ShippingDelegate {
    final func didFetchShippingInfo(_ shippingInfo: ShippingInfo) {
        self.shippingInfo = shippingInfo
        if let address = shippingInfo.addresses.first {
            addressLabel.text = address
        }
    }
}

// ca US
// 38.577
// -121.4848
// 1000
// state
// ready
