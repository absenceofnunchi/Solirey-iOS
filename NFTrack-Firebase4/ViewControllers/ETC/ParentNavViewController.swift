//
//  ParentNavViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-05.
//

import UIKit

class ParentNavViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        
    }

    // MARK: - configureNavigationBar
    func configureNavigationBar() {
        view.backgroundColor = .white
        // navigation controller
        self.navigationController?.navigationBar.tintColor = UIColor.gray
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.prefersLargeTitles = true

        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = .white
            appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            navigationController?.navigationBar.compactAppearance = appearance
            
        } else {
            self.navigationController?.navigationBar.barTintColor = .white
            self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        }
    }
}
