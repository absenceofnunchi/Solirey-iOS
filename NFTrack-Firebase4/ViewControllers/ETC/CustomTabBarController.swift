//
//  CustomTabBarViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-28.
//

import UIKit

class CustomTabBarViewController: UITabBarController, UITabBarControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        setValue(CustomTabBar(frame: tabBar.frame), forKey: "tabBar")        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        guard let tabBarItems = tabBar.items else { return }
        for tabBarItem in tabBarItems {
            guard let viewTabBar = tabBarItem.value(forKey: "view") as? UIView,
                  let imgView = viewTabBar.subviews[0] as? UIImageView else { return }
            
            let margin = (viewTabBar.bounds.height - imgView.bounds.height) / 2
            viewTabBar.bounds.origin.y = -margin - 5
            imgView.frame.size.height = 24
            imgView.frame.size.width = 24
            imgView.clipsToBounds = true
            imgView.contentMode = .scaleAspectFit
        }
    }
    
//    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
//        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
//        feedbackGenerator.impactOccurred()
//
//        guard let viewTabBar = item.value(forKey: "view") as? UIView,
//              let imgView = viewTabBar.subviews[0] as? UIImageView else { return }
//        print("imgView.bounds.origin", imgView.bounds.origin)
//    }
}

class CustomTabBar: UITabBar {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureBackground()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension CustomTabBar {
    private func configureBackground() {
        layer.borderWidth = 0.3
        layer.borderColor = UIColor.lightGray.cgColor
        layer.cornerRadius = 30
        layer.masksToBounds = true
        layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        backgroundColor = .white
        tintColor = .lightGray
        barTintColor = .white
    }
}
