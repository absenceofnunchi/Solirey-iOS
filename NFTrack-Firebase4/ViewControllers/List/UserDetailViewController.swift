//
//  UserDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-11.
//

import UIKit
import FirebaseFirestore

class UserDetailViewController: UIViewController {
    final var segmentedControl: UISegmentedControl!
    final var userInfo: UserInfo!

    private var profilePostingsVC: ProfilePostingsViewController! {
        return ProfilePostingsViewController(userInfo: userInfo)
    }

    private var profileReviewVC: ProfileReviewListViewController! {
        return ProfileReviewListViewController(userInfo: userInfo)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        configureSwitch()
    }
    
    final override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    final override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
    }
}

extension UserDetailViewController {
    func configureUI() {
        view.backgroundColor = .white
        addBaseViewController(profilePostingsVC)
    }
}

extension UserDetailViewController: SegmentConfigurable {
    enum Segment: Int, CaseIterable {
        case posts, reviews
        
        func asString() -> String {
            switch self {
                case .posts:
                    return NSLocalizedString("Posts", comment: "")
                case .reviews:
                    return NSLocalizedString("Reviews", comment: "")
            }
        }
        
        static func getSegmentText() -> [String] {
            let segmentArr = Segment.allCases
            var segmentTextArr = [String]()
            for segment in segmentArr {
                segmentTextArr.append(NSLocalizedString(segment.asString(), comment: ""))
            }
            return segmentTextArr
        }
    }
    
    // MARK: - configureSwitch
    final func configureSwitch() {
        // Segmented control as the custom title view.
        let segmentTextContent = Segment.getSegmentText()
        segmentedControl = UISegmentedControl(items: segmentTextContent)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.autoresizingMask = .flexibleWidth
        segmentedControl.frame = CGRect(x: 0, y: 0, width: 300, height: 30)
        segmentedControl.addTarget(self, action: #selector(segmentedControlSelectionDidChange(_:)), for: .valueChanged)
        self.navigationItem.titleView = segmentedControl
    }
    
    // MARK: - segmentedControlSelectionDidChange
    @objc final func segmentedControlSelectionDidChange(_ sender: UISegmentedControl) {
        guard let segment = Segment(rawValue: sender.selectedSegmentIndex)
        else { fatalError("No item at \(sender.selectedSegmentIndex)) exists.") }
        switch segment {
            case .posts:
                if profileReviewVC != nil {
                    profileReviewVC.loadingQueue.cancelAllOperations()
                    profileReviewVC.loadingOperations.removeAll()
                }
                removeBaseViewController(profileReviewVC)
                addBaseViewController(profilePostingsVC)
            case .reviews:
                if profilePostingsVC != nil {
                    profilePostingsVC.loadingQueue.cancelAllOperations()
                    profilePostingsVC.loadingOperations.removeAll()
                }
                removeBaseViewController(profilePostingsVC)
                addBaseViewController(profileReviewVC)
        }
    }
    
    // MARK: - Switching Between View Controllers
    private func addBaseViewController<T: UIViewController>(_ vc: T) {
        addChild(vc)
        view.addSubview(vc.view)
        vc.view.fill()
        vc.didMove(toParent: self)
    }

    /// Removes a child view controller from the container.
    private func removeBaseViewController(_ viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}
