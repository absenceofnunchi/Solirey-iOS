//
//  PDFCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-01.
//

import UIKit
import PDFKit

class PDFCell: PreviewCell {
    let pdfView = PDFView()
    static let reuseIdentifier = "pdf-cell-reuse-identifier"

    override func configure() {
        pdfView.contentMode = .scaleAspectFit
        pdfView.layer.cornerRadius = 10
        pdfView.clipsToBounds = true
        pdfView.autoScales = true
        pdfView.dropShadow()
        pdfView.backgroundColor = .white
        self.addSubview(pdfView)
        pdfView.fill(inset: 4)
        
        let image = UIImage(systemName: "multiply.circle.fill")!.withTintColor(.red, renderingMode: .alwaysOriginal)
        closeButton = UIButton.systemButton(with: image, target: self, action: #selector(buttonPressed))
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(closeButton)
    }
    override func setConstraints() {
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: self.topAnchor, constant: -5),
            closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 5),
            closeButton.widthAnchor.constraint(equalToConstant: 25),
            closeButton.heightAnchor.constraint(equalToConstant: 25),
        ])
    }
}
