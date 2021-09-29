//
//  CustomTabBarViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-28.
//

import UIKit

class CustomTabBarViewController: UITabBarController, UITabBarControllerDelegate {
    private var indicatorLayer: CALayer!
    private var position: CGPoint!
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure() {
        delegate = self
        setValue(CustomTabBar(frame: tabBar.frame), forKey: "tabBar")
    }
    
    final override func viewDidAppear(_ animated: Bool) {
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
    
    final override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()

        guard let viewTabBar = item.value(forKey: "view") as? UIView else { return }
        
        position = CGPoint(x: viewTabBar.frame.midX, y: viewTabBar.frame.minY - 5)
        if indicatorLayer == nil {
            indicatorLayer = CALayer()
//            indicatorLayer.backgroundColor = UIColor.black.cgColor
            indicatorLayer.backgroundColor = UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1).cgColor
            indicatorLayer.frame = CGRect(origin: position, size: .init(width: 25, height: 25))
            indicatorLayer.position = position
            indicatorLayer.cornerRadius = 30
            indicatorLayer.isHidden = true
            tabBar.layer.addSublayer(indicatorLayer)
        } else {
            indicatorLayer.isHidden = false
            indicatorLayer.position = position
        }
    }
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

private extension CustomTabBar {
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
