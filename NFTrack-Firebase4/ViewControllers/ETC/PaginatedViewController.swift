//
//  PaginatedViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-07-17.
//

import UIKit

class PaginatedViewController: UIViewController {
    var page: Int!

    init(page: Int) {
        super.init(nibName: nil, bundle: nil)
        self.page = page
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
