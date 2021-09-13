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
    private var memberHistoryTitleLabel: UILabel!
    private var memberHistoryTextField: UITextField!
    private var detailButton: UIButton!
     
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

    final override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let contentHeight: CGFloat = profileImageButton.bounds.size.height +
            displayNameTitleLabel.bounds.size.height +
            displayNameTextField.bounds.size.height +
            memberHistoryTitleLabel.bounds.size.height +
            memberHistoryTextField.bounds.size.height +
            detailButton.bounds.size.height +
            300

        self.scrollView.contentSize = CGSize(width: self.view.bounds.size.width, height: contentHeight)
    }
}

extension ProfileDetailViewController {
    final override func configureUI() {
        super.configureUI()
        displayNameTextField.isUserInteractionEnabled = false
        
        memberHistoryTitleLabel = createTitleLabel(text: "Member Since")
        scrollView.addSubview(memberHistoryTitleLabel)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let formattedDate = formatter.string(from: userInfo.memberSince ?? Date())

        memberHistoryTextField = createTextField(content: formattedDate, delegate: self)
        memberHistoryTextField.isUserInteractionEnabled = false
        scrollView.addSubview(memberHistoryTextField)
        
        detailButton = UIButton()
        detailButton.setTitle("User Details", for: .normal)
        detailButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        detailButton.backgroundColor = .black
        detailButton.layer.cornerRadius = 5
        detailButton.tag = 0
        detailButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(detailButton)

        NSLayoutConstraint.activate([
            memberHistoryTitleLabel.topAnchor.constraint(equalTo: displayNameTextField.bottomAnchor, constant: 30),
            memberHistoryTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            memberHistoryTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
            memberHistoryTitleLabel.heightAnchor.constraint(equalToConstant: 50),

            memberHistoryTextField.topAnchor.constraint(equalTo: memberHistoryTitleLabel.bottomAnchor, constant: 10),
            memberHistoryTextField.heightAnchor.constraint(equalToConstant: 50),
            memberHistoryTextField.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            memberHistoryTextField.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
            
            detailButton.topAnchor.constraint(equalTo: memberHistoryTextField.bottomAnchor, constant: 50),
            detailButton.heightAnchor.constraint(equalToConstant: 50),
            detailButton.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            detailButton.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
        ])
    }
    
    @objc override func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 0:
                let userDetailVC = UserDetailViewController()
                userDetailVC.userInfo = userInfo
                navigationController?.pushViewController(userDetailVC, animated: true)
            default:
                break
        }
    }
}

extension ProfileDetailViewController {
    final override func configureCustomProfileImage(from url: String) {
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
