//
//  ProfileDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-08.
//

/*
 Abstract: ParentVC for ProfilePostVC and ProfileReviewListVC
 */

import UIKit
import FirebaseFirestore

class ProfileDetailViewController: ParentProfileViewController {
    var profileImage: UIImage!
    private var itemsTitleLabel: UILabel!
    private var tableView: UITableView!
    private let CELL_HEIGHT: CGFloat = 100
    private var tableViewHeight: CGFloat = 0
    private var customSegmentedControl: CustomSegmentedControl!
    private var profilePostingsVC: ProfilePostingsViewController!
    private var profileReviewVC: ProfileReviewListViewController!
    private let db = FirebaseService.shared
    private var lastSnapshot: QueryDocumentSnapshot!

    override func viewDidLoad() {
        super.viewDidLoad()

        db.lastSnapshotDelegate = self
        profilePostingsVC = addBaseViewController(ProfilePostingsViewController.self)
//        getCurrentPosts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        DispatchQueue.main.async {
            if self.profileImage != nil {
                self.profileImageButton = self.createProfileImageButton(self.profileImageButton, image: self.profileImage!)
            }
        }
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        self.scrollView.contentSize = CGSize(width: self.view.bounds.size.width, height: container.preferredContentSize.height)
    }
}

extension ProfileDetailViewController {
    override func configureUI() {
        super.configureUI()
        view.backgroundColor = .white
        
        displayNameTextField.isUserInteractionEnabled = false

        customSegmentedControl = CustomSegmentedControl()
        customSegmentedControl.addTarget(self, action: #selector(segmentedControlSelectionDidChange(_:)), for: .valueChanged)
        customSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(customSegmentedControl)

        NSLayoutConstraint.activate([
            customSegmentedControl.topAnchor.constraint(equalTo: displayNameTextField.bottomAnchor, constant: 10),
            customSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            customSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            customSegmentedControl.heightAnchor.constraint(equalToConstant: 50),
        ])
        customSegmentedControl.layoutIfNeeded()
        customSegmentedControl.buttonTitles = ["Postings", "Reviews"]
    }

    private func getCurrentPosts() {
        guard let uid = userInfo.uid else { return }
        FirebaseService.shared.db.collection("post")
            .whereField("sellerUserId", isEqualTo: uid)
            .whereField("status", isEqualTo: "ready")
            .getDocuments { [weak self] (querySnapshot, err) in
                if let err = err {
                    self?.alert.showDetail("Error Fetching Data", with: err.localizedDescription, for: self)
                } else {
                    if let postArr = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.profilePostingsVC.postArr = postArr
                    }
                }
            }
    }
 
    
    // MARK: - segmentedControlSelectionDidChange
    @objc private func segmentedControlSelectionDidChange(_ sender: CustomSegmentedControl) {
        guard let segment = sender.selectedSegmentIndex
        else { fatalError("No item at \(String(describing: sender.selectedSegmentIndex))) exists.") }
        switch segment {
            case 0:
                removeBaseViewController(profileReviewVC)
                profilePostingsVC = addBaseViewController(ProfilePostingsViewController.self)
                getCurrentPosts()
            case 1:
                removeBaseViewController(profilePostingsVC)
                profileReviewVC = addBaseViewController(ProfileReviewListViewController.self)
                guard let uid = userInfo.uid else { return }
                db.getReviews(uid: uid)
            default:
                break
        }
    }
    
    // MARK: - Switching Between View Controllers
    
    /// Adds a child view controller to the container.
    private func addBaseViewController<T: UIViewController>(_ viewController: T.Type) -> T {
        let vc = viewController.init()
        addChild(vc)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(vc.view)
        
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: customSegmentedControl.bottomAnchor, constant: 15),
            vc.view.heightAnchor.constraint(equalToConstant: 400),
            vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
        vc.didMove(toParent: self)
        return vc
    }
    
    /// Removes a child view controller from the container.
    private func removeBaseViewController(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}

extension ProfileDetailViewController: PaginateFetchDelegate {
    func didGetLastSnapshot(_ lastSnapshot: QueryDocumentSnapshot) {
        self.lastSnapshot = lastSnapshot
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height
        let reload_distance:CGFloat = 10.0
        if y > (h + reload_distance) {
            guard let uid = userInfo.uid else { return }
            db.refetchReviews(uid: uid, lastSnapshot: self.lastSnapshot)
        }
    }
}
