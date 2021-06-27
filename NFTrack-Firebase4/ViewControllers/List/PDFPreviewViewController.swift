//
//  PDFPreviewViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-26.
//

import UIKit
import PDFKit

class PDFPreviewViewController: UIViewController {
    var document: PDFDocument!
    var pdfView: PDFView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.document = document
        view.addSubview(pdfView)
        pdfView.fill()
    }
}
