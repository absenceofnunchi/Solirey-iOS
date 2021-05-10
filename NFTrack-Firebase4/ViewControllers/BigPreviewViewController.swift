//
//  BigPreviewViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-09.
//

import UIKit

class BigPreviewViewController: UIViewController {
    let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.contentMode = .scaleAspectFill
        view.addSubview(imageView)
        imageView.fill()
    }
}
