//
//  ProfileDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-08.
//

import UIKit

class ProfileDetailViewController: ParentProfileViewController {
    var postArr = [Post]()
    var profileImage: UIImage!
    private var itemsTitleLabel: UILabel!
    private var tableView: UITableView!
    private let CELL_HEIGHT: CGFloat = 100
    private var tableViewHeight: CGFloat = 0 {
        didSet {
            self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: self.tableViewHeight + 500)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let uid = userInfo.uid {
            getCurrentPosts(uid: uid)
        }
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
}

extension ProfileDetailViewController: TableViewConfigurable {
    override func configureUI() {
        super.configureUI()
        view.backgroundColor = .white
        
        displayNameTextField.isUserInteractionEnabled = false
        
        itemsTitleLabel = createTitleLabel(text: "Details")
        scrollView.addSubview(itemsTitleLabel)
        
        tableView = configureTableView(delegate: self, dataSource: self, height: CELL_HEIGHT, cellType: ListCell.self, identifier: ListCell.identifier)
        tableView.isScrollEnabled = false
        scrollView.addSubview(tableView)
    }
    
    override func setConstraints() {
        super.setConstraints()
        
        NSLayoutConstraint.activate([
            itemsTitleLabel.topAnchor.constraint(equalTo: displayNameTextField.bottomAnchor, constant: 50),
            itemsTitleLabel.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 20),
            itemsTitleLabel.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: -20),
            itemsTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            tableView.topAnchor.constraint(equalTo: itemsTitleLabel.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: scrollView.layoutMarginsGuide.trailingAnchor, constant: 0),
        ])
    }
    
    func getCurrentPosts(uid: String) {
        FirebaseService.shared.db.collection("post")
            .whereField("sellerUserId", isEqualTo: uid)
            .whereField("status", isEqualTo: "ready")
            .getDocuments { [weak self] (querySnapshot, err) in
                if let err = err {
                    self?.alert.showDetail("Error Fetching Data", with: err.localizedDescription, for: self)
                } else {
                    if let data = self?.parseDocuments(querySnapshot: querySnapshot) {
                        self?.postArr = data
                        DispatchQueue.main.async {
                            self?.tableViewHeight = CGFloat(self!.postArr.count) * self!.CELL_HEIGHT
                            print("self?.tableViewHeight", self?.tableViewHeight)
                            NSLayoutConstraint.activate([
                                self!.tableView.heightAnchor.constraint(equalToConstant: self!.tableViewHeight),
                            ])
                            self?.tableView.reloadData()
                        }
                    }
                }
            }
    }
}

extension ProfileDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ListCell.identifier, for: indexPath) as! ListCell
        cell.selectionStyle = .none
        
        let post = postArr[indexPath.row]
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let formattedDate = formatter.string(from: post.date)
        cell.set(title: post.title, date: formattedDate)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let listDetailVC = ListDetailViewController()
        listDetailVC.post = postArr[indexPath.row]
        self.navigationController?.pushViewController(listDetailVC, animated: true)
    }
}
