//
//  DocumentPicker.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-25.
//

import UIKit
import UniformTypeIdentifiers
import MobileCoreServices

// MARK: - Protocol

protocol DocumentDelegate: class {
    func didPickDocument(document: Document?)
}

class DocumentPicker: NSObject {
    private var pickerController: UIDocumentPickerViewController?
    private weak var presentationController: UIViewController?
    private weak var delegate: DocumentDelegate?
    
    private var pickedDocument: Document?
    
    init(presentationController: UIViewController, delegate: DocumentDelegate) {
        super.init()
        self.presentationController = presentationController
        self.delegate = delegate
    }
    
    public func displayPicker() {
        if #available(iOS 14, *) {
            let supportedTypes: [UTType] = [UTType.text, UTType.plainText, UTType.rtf, UTType.xml, UTType.spreadsheet, UTType.image, UTType.jpeg, UTType.png, UTType.pdf]
            self.pickerController = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        } else {
            self.pickerController = UIDocumentPickerViewController(documentTypes: [String(kUTTypePNG), String(kUTTypeJPEG), String(kUTTypePDF), String(kUTTypeText), String(kUTTypePlainText), String(kUTTypeRTF), String(kUTTypeRTF), String(kUTTypeSpreadsheet)], in: .import)
        }
        
        self.pickerController!.delegate = self
        self.pickerController?.modalPresentationStyle = .fullScreen
        self.presentationController?.present(self.pickerController!, animated: true)
    }
}

// MARK: - Delegate methods

extension DocumentPicker: UIDocumentPickerDelegate {
    /// delegate method, when the user selects a file
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        documentFromURL(pickedURL: url)
        delegate?.didPickDocument(document: pickedDocument)
    }
    
    /// delegate method, when the user cancels
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        delegate?.didPickDocument(document: nil)
    }
    
    private func documentFromURL(pickedURL: URL) {
        
        /// start accessing the resource
        let shouldStopAccessing = pickedURL.startAccessingSecurityScopedResource()
        
        defer {
            if shouldStopAccessing {
                pickedURL.stopAccessingSecurityScopedResource()
            }
        }
        
        NSFileCoordinator().coordinate(readingItemAt: pickedURL, error: NSErrorPointer.none) { (readURL) in
            let document = Document(fileURL: readURL)
            pickedDocument = document
        }
    }
}
