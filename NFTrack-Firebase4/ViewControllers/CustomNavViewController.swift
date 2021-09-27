//
//  CustomNavViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-27.
//

import UIKit

class CustomNavController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBarTintColorToTheNavigationBar5()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationBar.sizeToFit()
    }
    
    func applyBarTintColorToTheNavigationBar5(
        tintColor: UIColor = UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1),
        titleTextColor: UIColor = .white
    ) {
        self.isHiddenHairline = true
        
        // For comparison, apply the same barTintColor to the toolbar, which has been configured to be opaque.
        self.toolbar.barTintColor = tintColor
        self.toolbar.isTranslucent = true
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundImage = UIImage()
        appearance.backgroundColor = tintColor
        appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: titleTextColor, NSAttributedString.Key.font: UIFont.rounded(ofSize: 30, weight: .bold)]
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: titleTextColor]
        
        let navigationBarAppearance = self.navigationBar
        navigationBarAppearance.prefersLargeTitles = true
        navigationBarAppearance.scrollEdgeAppearance = appearance
        navigationBarAppearance.standardAppearance = appearance
        navigationBarAppearance.tintColor = titleTextColor
    }
}
