//
//  PreviewPDFViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-25.
//

import UIKit

import UIKit
import QuickLook

class PreviewPDFViewController: QLPreviewController {
//    var buttonAction: (()->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let barButton = UIBarButtonItem(title: "Upload", style: .plain, target: self, action: #selector(buttonTapped))
//        self.navigationItem.rightBarButtonItems = [barButton]
//        self.navigationItem.setLeftBarButtonItems([], animated: true)
        //        self.navigationItem.hidesBackButton = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
//    @objc func buttonTapped(_ sender: UIButton) {
//        if let buttonAction = self.buttonAction {
//            buttonAction()
//        }
//    }
}
