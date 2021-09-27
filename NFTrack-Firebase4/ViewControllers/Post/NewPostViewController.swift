//
//  NewPostViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-29.
//

/*
 Parent container view controller for PostVC and DigitalVC
 */

import UIKit

class NewPostViewController: UIViewController, SegmentConfigurable {
    var segmentedControl: UISegmentedControl!
    var postVC: PostViewController! {
      return PostViewController()
    }
    var digitalVC: DigitalAssetViewController! {
        return DigitalAssetViewController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSwitch()
        addBaseViewController(postVC)
    }
  
    // MARK: - configureSwitch
    func configureSwitch() {
        // Segmented control as the custom title view.
        let segmentTextContent = PostType.getSegmentText()
        segmentedControl = UISegmentedControl(items: segmentTextContent)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.autoresizingMask = .flexibleWidth
        segmentedControl.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
        segmentedControl.addTarget(self, action: #selector(segmentedControlSelectionDidChange(_:)), for: .valueChanged)
//        segmentedControl.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        UISegmentedControl.appearance().backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.1)
        segmentedControl.selectedSegmentTintColor = UIColor.white
        self.navigationItem.titleView = segmentedControl
    }
    
    // MARK: - segmentedControlSelectionDidChange
    @objc func segmentedControlSelectionDidChange(_ sender: UISegmentedControl) {
        guard let segment = PostType(rawValue: sender.selectedSegmentIndex)
        else { fatalError("No item at \(sender.selectedSegmentIndex)) exists.") }
        switch segment {
            case .tangible:
                removeBaseViewController(digitalVC)
                addBaseViewController(postVC)
            case .digital:
                removeBaseViewController(postVC)
                addBaseViewController(digitalVC)
        }
    }
    
    // MARK: - Switching Between View Controllers
    
    /// Adds a child view controller to the container.
    private func addBaseViewController<T: UIViewController>(_ viewController: T) {
        addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        viewController.view.fill()
    }
    
    /// Removes a child view controller from the container.
    private func removeBaseViewController(_ viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}
