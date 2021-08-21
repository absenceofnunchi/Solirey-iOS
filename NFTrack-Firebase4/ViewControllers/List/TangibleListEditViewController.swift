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
    var imagePreviewVC: ImagePreviewViewController!
    var imagePreviewConstraintHeight: NSLayoutConstraint!
    var previewDataArr: [PreviewData]! {
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
    
    var IMAGE_PREVIEW_HEIGHT: CGFloat! = 180
    lazy var SCROLLVIEW_CONTENTSIZE_WITH_IMAGE_PREVIEW: CGFloat! = SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT + IMAGE_PREVIEW_HEIGHT

    let configuration = UIImage.SymbolConfiguration(pointSize: 50, weight: .light, scale: .medium)
    var pickerImageName: String! {
        var imageName: String!
        if #available(iOS 14.0, *) {
            imageName = "rectangle.fill.on.rectangle.fill.circle"
        } else {
            imageName = "tv.circle"
        }
        return imageName
    }
    var buttonPanel: UIStackView!
    final var panelButtons: [PanelButton] {
        let buttonPanels = [
            PanelButton(imageName: "camera.circle", imageConfig: configuration, tintColor: UIColor(red: 198/255, green: 122/255, blue: 206/255, alpha: 1), tag: 8),
            PanelButton(imageName: pickerImageName, imageConfig: configuration, tintColor: UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), tag: 9),
            PanelButton(imageName: "doc.circle", imageConfig: configuration, tintColor: UIColor(red: 61/255, green: 156/255, blue: 133/255, alpha: 1), tag: 10)
        ]
        return buttonPanels
    }
    var constraints: [NSLayoutConstraint]!
    var documentPicker: DocumentPicker!
    var url: URL!
    var userId: String!
    var storage = Set<AnyCancellable>()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if imagePreviewVC != nil {
            /// whenever the image picker is dismissed, the collection view has to be updated
            imagePreviewVC.data = previewDataArr
        }
    }

    override func configureUI() {
        super.configureUI()
        constraints = [NSLayoutConstraint]()
        previewDataArr = [PreviewData]()
        
        createButtonPanel(panelButtons: panelButtons, superView: scrollView) { (buttonsArr) in
            buttonsArr.forEach { (button) in
                button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            }
        }
        
        if let files = post.files, files.count > 0 {
            for file in files {
                guard let filePath = URL(string: file) else { return }
                if file.contains("pdf") {
                    previewDataArr.append(PreviewData(header: .document, filePath: filePath))
                } else {
                    

//                    saveImage(imageName: <#T##String#>, image: <#T##UIImage#>)
                    previewDataArr.append(PreviewData(header: .remoteImage, filePath: filePath))
                }
            }
        }
        
        
        // the digital type should never run
        if post.type == "digital" {
            configureImagePreview(postType: .digital(.onlineDirect), superView: scrollView)
        } else {
            configureImagePreview(postType: .tangible, superView: scrollView)
        }
    }
    
//    func downloadFiled(files: [String]) {
//        files.map { (file) -> AnyPublisher<String, PostingError> in
//            Future<String, PostingError> { promise in
//                
//            }
//            .eraseToAnyPublisher()
//        }
//    }
    
    override func setConstraints() {
        super.setConstraints()
        
        setButtonPanelConstraints(topView: descTextView)
        
        // if you set the height to the image height here, self?.imagePreviewConstraintHeight.constant = 0 in the property observer of previewDataArr for the empty array gets called
        // AFTER previewDataArr.count > 0 is called.
        // in other words, SCROLLVIEW_CONTENTSIZE_DEFAULT_HEIGHT is called after SCROLLVIEW_CONTENTSIZE_WITH_IMAGE_PREVIEW is called causing the content size to be reduced.
        imagePreviewConstraintHeight = imagePreviewVC.view.heightAnchor.constraint(equalToConstant: 0)

        constraints.append(contentsOf: [
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
    
    @objc override func buttonPressed(_ sender: UIButton) {
        guard previewDataArr.count < 6 else {
            self.alert.showDetail(
                "Upload Limit",
                with: "There is a limit of 6 files per post.",
                for: self)
            return
        }
                
        switch sender.tag {
            case 0:
                guard let itemTitle = titleNameTextField.text,
                      let desc = descTextView.text else { return }
                
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
                        func withFiles(_ data: [PreviewData]) -> AnyPublisher<Bool, PostingError> {
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
                                .flatMap { (urlStrings) -> AnyPublisher<Bool, PostingError> in
                                    Future<Bool, PostingError> { promise in
                                        self?.db.collection("post").document(postId).updateData([
                                            "title": itemTitle,
                                            "description": desc,
                                            "files": urlStrings
                                        ]) { (error) in
                                            if let error = error {
                                                promise(.failure(.generalError(reason: error.localizedDescription)))
                                            }
                                            
                                            promise(.success(true))
                                        }
                                    }
                                    .eraseToAnyPublisher()
                                }
                                .eraseToAnyPublisher()
                        }
                        
                        // if there are no files to upload
                        func withoutFiles() -> AnyPublisher<Bool, PostingError> {
                            Future<Bool, PostingError> { promise in
                                self?.db.collection("post").document(postId).updateData([
                                    "title": itemTitle,
                                    "description": desc,
                                    "files": ""
                                ]) { (error) in
                                    if let error = error {
                                        promise(.failure(.generalError(reason: error.localizedDescription)))
                                    }
                                    
                                    promise(.success(true))
                                }
                            }
                            .eraseToAnyPublisher()
                        }

                        var updatePublisher: AnyPublisher<Bool, PostingError>!
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
                                            self?.navigationController?.popViewController(animated: true)
                                        })
                                    }, completion:  {
                                        self?.delegate?.didUpdatePost(titleString: itemTitle, desc: desc, files: nil)
                                    })
                                    break
                            }
                        } receiveValue: { (isDone) in }
                        .store(in: &self!.storage)
                    }
                }
                self.present(alertVC, animated: true, completion: nil)
                
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
                            if let files = self?.post.files {
                                for file in files {
                                    // Create a reference to the file to delete
                                    let storage = Storage.storage()
                                    let storageRef = storage.reference()
                                    let mediaRef = storageRef.child(file)
                                    
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
            default:
                break
        }
    }
}

// MARK: - Image picker
extension TangibleListEditViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let filePath = info[UIImagePickerController.InfoKey.imageURL] as? URL else {
            print("No image found")
            return
        }

        print("picker", filePath)
        let previewData = PreviewData(header: .image, filePath: filePath)
        previewDataArr.append(previewData)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension TangibleListEditViewController: DocumentDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        //        return self.url as QLPreviewItem
        let docTitle = UUID().uuidString
        let previewItem = CustomPreviewItem(url: url, title: docTitle)
        return previewItem as QLPreviewItem
    }
    
    // MARK: - didPickDocument
    func didPickDocument(document: Document?) {
        if let pickedDoc = document {
            let fileURL = pickedDoc.fileURL
            guard fileURL.pathExtension == "pdf" else {
                self.alert.showDetail("Sorry", with: "The document has to be a PDF file", for: self)
                return
            }
            url = fileURL
            let previewData = PreviewData(header: .document, filePath: fileURL)
            previewDataArr.append(previewData)
            
            let preview = PreviewPDFViewController()
            preview.delegate = self
            preview.dataSource = self
            present(preview, animated: true, completion: nil)
        }
    }
}

extension TangibleListEditViewController {
    // MARK: - didDeleteImage
    func didDeleteFileFromPreview(filePath: URL) {
        previewDataArr = previewDataArr.filter { $0.filePath != filePath }
    }
}
