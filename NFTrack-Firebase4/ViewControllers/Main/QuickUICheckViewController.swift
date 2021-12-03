//
//  QuickUICheckViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-29.
//

import UIKit
import Combine

class QuickUICheckViewController: ParentListViewController<Post>, FetchContractAddress, ContextAction {    
    private var scrollView = UIScrollView()
    private var idTitleLabel: UILabel!
    private var idContainerView: UIView!
    private var idTextField: UITextField!
    private var scanButton: UIButton!
    private var idTitleTextFieldConstraints: NSLayoutConstraint!
    private var postButton: UIButton!
    private let CELL_HEIGHT: CGFloat = 330
    private var statusLabel: UILabel!
    private var infoButtonItem: UIBarButtonItem!
    private var customNavView: BackgroundView5!
    var storage: Set<AnyCancellable>! = {
        return Set<AnyCancellable>()
    }()

    final override func setDataStore(postArr: [Post]) {
        dataStore = PostImageDataStore(posts: postArr)
    }
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        setConstraint()
        configureNavigationBar()
    }
    
    func configureNavigationBar() {
        guard let infoImage = UIImage(systemName: "info.circle") else { return }
        infoButtonItem = UIBarButtonItem(image: infoImage, style: .plain, target: self, action: #selector(buttonPressed(_:)))
        infoButtonItem.tag = 3
        self.navigationItem.rightBarButtonItem = infoButtonItem
    }
    
    final override func configureUI() {
        super.configureUI()
        title = "Quick UI Check"
        self.hideKeyboardWhenTappedAround()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        customNavView = BackgroundView5()
        customNavView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(customNavView)
        
        idTitleLabel = createTitleLabel(text: "Unique Identifier")
        scrollView.addSubview(idTitleLabel)
        
        idContainerView = UIView()
        idContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(idContainerView)
        
        idTextField = createTextField(delegate: self)
        idTextField.autocapitalizationType = .none
        idTextField.placeholder = "Case insensitive, i.e. VIN, IMEI..."
        idContainerView.addSubview(idTextField)
        
        guard let scanImage = UIImage(systemName: "qrcode.viewfinder") else { return }
        scanButton = UIButton.systemButton(with: scanImage.withTintColor(.black, renderingMode: .alwaysOriginal), target: self, action: #selector(buttonPressed))
        scanButton.layer.cornerRadius = 5
        scanButton.layer.borderWidth = 0.7
        scanButton.layer.borderColor = UIColor.lightGray.cgColor
        scanButton.tag = 1
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        idContainerView.addSubview(scanButton)
        
        postButton = UIButton()
        postButton.setTitle("Check", for: .normal)
        postButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        postButton.layer.cornerRadius = 5
        postButton.backgroundColor = .black
        postButton.tag = 2
        postButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(postButton)
        
        tableView = configureTableView(delegate: self, dataSource: self, height: CELL_HEIGHT, cellType: CardCell.self, identifier: CardCell.identifier)
        tableView.prefetchDataSource = self
        tableView.isScrollEnabled = false
        scrollView.addSubview(tableView)
        
        statusLabel = UILabel()
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.numberOfLines = 0
        statusLabel.isHidden = true
        statusLabel.sizeToFit()
        scrollView.addSubview(statusLabel)
    }
    
    private func setConstraint() {
        idTitleTextFieldConstraints = idTitleLabel.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor, constant: -150)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            customNavView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 0),
            customNavView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            customNavView.heightAnchor.constraint(equalToConstant: 50),
            
            idTitleTextFieldConstraints,
            idTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            idTitleLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            idTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            idContainerView.topAnchor.constraint(equalTo: idTitleLabel.bottomAnchor, constant: 0),
            idContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            idContainerView.heightAnchor.constraint(equalToConstant: 50),
            idContainerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            
            idTextField.widthAnchor.constraint(equalTo: idContainerView.widthAnchor, multiplier: 0.75),
            idTextField.heightAnchor.constraint(equalToConstant: 50),
            idTextField.leadingAnchor.constraint(equalTo: idContainerView.leadingAnchor),
            
            scanButton.widthAnchor.constraint(equalTo: idContainerView.widthAnchor, multiplier: 0.2),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            scanButton.trailingAnchor.constraint(equalTo: idContainerView.trailingAnchor),
            
            postButton.topAnchor.constraint(equalTo: idContainerView.bottomAnchor, constant: 40),
            postButton.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            postButton.heightAnchor.constraint(equalToConstant: 50),
            postButton.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: postButton.bottomAnchor, constant: 50),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: postButton.bottomAnchor, constant: 150),
            statusLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            statusLabel.heightAnchor.constraint(equalToConstant: 100),
            statusLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor)
        ])
    }
    
    @objc private func buttonPressed(_ sender: UIButton!) {
        switch sender.tag {
            case 1:
                let scannerVC = ScannerViewController()
                scannerVC.delegate = self
                scannerVC.modalPresentationStyle = .fullScreen
                self.present(scannerVC, animated: true, completion: nil)
            case 2:
                fetchData()
            case 3:
                let infoVC = InfoViewController(infoModelArr: [InfoModel(title: "Unique Identifier", detail: InfoText.quickUICheck)])
                self.present(infoVC, animated: true, completion: nil)
            default:
                break
        }
    }
    
    final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CardCell.identifier) as? CardCell else {
            fatalError("Sorry, could not load cell")
        }
        cell.selectionStyle = .none
        let post = postArr[indexPath.row]
        cell.updateAppearanceFor(.pending(post))
        
        return cell
    }
    
    final override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = postArr[indexPath.row]
        guard let vc = getPreviewVC(post: post) else { return }
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension QuickUICheckViewController: ScannerDelegate {
    // MARK: - scannerDidOutput
    final func scannerDidOutput(code: String) {
        idTextField.text = code
    }
}

extension QuickUICheckViewController: UITextFieldDelegate {
    final  func textFieldDidBeginEditing(_ textField: UITextField) {
        idTitleTextFieldConstraints.isActive = false
        idTitleTextFieldConstraints = idTitleLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 40)
        idTitleTextFieldConstraints.isActive = true
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.scrollView.layoutIfNeeded()
        }
    }
}

extension QuickUICheckViewController: PostParseDelegate {
    private func fetchData() {
        cache.removeAllObjects()
        
        guard let text = idTextField.text, !text.isEmpty else {
            alert.showDetail("Sorry", with: "The field cannot be empty.", for: self)
            return
        }
        
        FirebaseService.shared.db.collection("post")
            .whereField("itemIdentifier", isEqualTo: text)
            .limit(to: 20)
            .getDocuments() { [weak self](querySnapshot, err) in
                guard let `self` = self else { return }
                if let err = err {
                    self.alert.showDetail("Sorry", with: err.localizedDescription, for: self)
                } else {
                    guard let querySnapshot = querySnapshot, !querySnapshot.isEmpty else {
                        self.postArr.removeAll()
                        self.tableView.reloadData()
                        self.statusLabel.isHidden = false
                        self.statusLabel.text = "No item found. Register your item!"
                        self.tableView.contentSize = .zero
                        self.scrollView.contentSize = .zero
                        return
                    }
                    self.statusLabel.isHidden = true
                    self.statusLabel.text = ""
                    if let data = self.parseDocuments(querySnapshot: querySnapshot) {
                        self.postArr = data
                        DispatchQueue.main.async {
                            self.tableView.contentSize = CGSize(width: self.view.bounds.size.width, height: CGFloat(self.postArr.count) * self.CELL_HEIGHT + 200)
                            self.scrollView.contentSize = CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.width + CGFloat(self.postArr.count) * self.CELL_HEIGHT + 50)
                            self.tableView.reloadData()
                        }
                    }
                }
            }
    }
}
