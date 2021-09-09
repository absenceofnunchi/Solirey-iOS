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
//    private var itemsTitleLabel: UILabel!
//    private let CELL_HEIGHT: CGFloat = 100
//    private var tableViewHeight: CGFloat = 0
//    private var tableView: UITableView!

    var profileImage: UIImage!
    private var customSegmentedControl: CustomSegmentedControl!
    private var profilePostingsVC: ProfilePostingsViewController!
    private var profileReviewVC: ProfileReviewListViewController!
    private let db = FirebaseService.shared
    private var lastSnapshot: QueryDocumentSnapshot!
    private var memberHistoryTitleLabel: UILabel!
    private var memberHistoryTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        db.lastSnapshotDelegate = self
        profilePostingsVC = addBaseViewController(ProfilePostingsViewController.self)
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
    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        
//        DispatchQueue.main.async {
//            if self.profileImage != nil {
//                self.profileImageButton = self.createProfileImageButton(self.profileImageButton, image: self.profileImage!)
//            }
//        }
//    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        self.scrollView.contentSize = CGSize(width: self.view.bounds.size.width, height: container.preferredContentSize.height + 150)
    }
}

extension ProfileDetailViewController {
    override func configureUI() {
        super.configureUI()
        view.backgroundColor = .white
        
        displayNameTextField.isUserInteractionEnabled = false
        
        memberHistoryTitleLabel = createTitleLabel(text: "Member Since")
        scrollView.addSubview(memberHistoryTitleLabel)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let formattedDate = formatter.string(from: userInfo.memberSince ?? Date())
        
        memberHistoryTextField = createTextField(content: formattedDate, delegate: self)
        memberHistoryTextField.isUserInteractionEnabled = false
        scrollView.addSubview(memberHistoryTextField)

        customSegmentedControl = CustomSegmentedControl()
        customSegmentedControl.addTarget(self, action: #selector(segmentedControlSelectionDidChange(_:)), for: .valueChanged)
        customSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(customSegmentedControl)

        NSLayoutConstraint.activate([
            memberHistoryTitleLabel.topAnchor.constraint(equalTo: displayNameTextField.bottomAnchor, constant: 30),
            memberHistoryTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            memberHistoryTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
            memberHistoryTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            memberHistoryTextField.topAnchor.constraint(equalTo: memberHistoryTitleLabel.bottomAnchor, constant: 10),
            memberHistoryTextField.heightAnchor.constraint(equalToConstant: 50),
            memberHistoryTextField.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            memberHistoryTextField.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
            
            customSegmentedControl.topAnchor.constraint(equalTo: memberHistoryTextField.bottomAnchor, constant: 50),
            customSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            customSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            customSegmentedControl.heightAnchor.constraint(equalToConstant: 50),
        ])
        customSegmentedControl.layoutIfNeeded()
        customSegmentedControl.buttonTitles = ProfileDetailMenu.getSegmentText()
        customSegmentedControl.selectedSegmentIndex = 0
        customSegmentedControl.sendActions(for: UIControl.Event.valueChanged)
    }
    
    // MARK: - segmentedControlSelectionDidChange
    @objc private func segmentedControlSelectionDidChange(_ sender: CustomSegmentedControl) {
        guard let segment = ProfileDetailMenu(rawValue: sender.selectedSegmentIndex)
        else { fatalError("No item at \(String(describing: sender.selectedSegmentIndex))) exists.") }
        guard let uid = userInfo.uid else { return }

        switch segment {
            case .postings:
                removeBaseViewController(profileReviewVC)
                profilePostingsVC = addBaseViewController(ProfilePostingsViewController.self)
                profilePostingsVC.loadingQueue.cancelAllOperations()
                profilePostingsVC.loadingOperations.removeAll()
                db.getCurrentPosts(uid: uid)
            case .reviews:
                removeBaseViewController(profilePostingsVC)
                profileReviewVC = addBaseViewController(ProfileReviewListViewController.self)
                profileReviewVC.loadingQueue.cancelAllOperations()
                profileReviewVC.loadingOperations.removeAll()
                db.getReviews(uid: uid)
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
    private func removeBaseViewController(_ viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}

extension ProfileDetailViewController: PaginateFetchDelegate {
    typealias FetchResult = MediaConfigurable
    
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
            
            print("userInfo.uid", userInfo.uid)
            print("self.lastSnapshot", self.lastSnapshot)
            guard let uid = userInfo.uid,
                  let lastSnapshot = self.lastSnapshot else { return }
            db.refetchReviews(uid: uid, lastSnapshot: lastSnapshot)
        }
    }
}

extension ProfileDetailViewController {
    override func configureCustomProfileImage(from url: String) {
        let loadingIndicator = UIActivityIndicatorView()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        profileImageButton.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: profileImageButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: profileImageButton.centerYAnchor)
        ])
        loadingIndicator.startAnimating()
        
        FirebaseService.shared.downloadImage(urlString: url) { [weak self] (image, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                self?.alert.showDetail("Sorry", with: error.localizedDescription, for: strongSelf)
                return
            }
            
            if let image = image {
                loadingIndicator.stopAnimating()
                strongSelf.profileImageButton = strongSelf.createProfileImageButton(strongSelf.profileImageButton, image: image)
            }
        }
    }
}
