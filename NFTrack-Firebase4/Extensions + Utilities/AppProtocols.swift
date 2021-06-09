//
//  AppProtocols.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

import UIKit
import FirebaseFirestore

// WalletViewController
protocol WalletDelegate: AnyObject {
    func didProcessWallet()
}

// MARK: - PreviewDelegate
/// PostViewController
protocol PreviewDelegate: AnyObject {
    func didDeleteImage(imageName: String)
}

// MARK: - MessageDelegate
/// PostViewController
protocol MessageDelegate: AnyObject {
    func didReceiveMessage(topics: [String])
}

// MARK: - TableViewRefreshDelegate
protocol TableViewRefreshDelegate: AnyObject {
    func didRefreshTableView()
}

// MARK: - TableViewConfigurable
protocol TableViewConfigurable {
    func configureTableView(delegate: UITableViewDelegate, dataSource: UITableViewDataSource, height: CGFloat, cellType: UITableViewCell.Type, identifier: String) -> UITableView
}

extension TableViewConfigurable where Self: UITableViewDataSource {
    func configureTableView(delegate: UITableViewDelegate, dataSource: UITableViewDataSource, height: CGFloat, cellType: UITableViewCell.Type, identifier: String) -> UITableView {
        let tableView = UITableView()
        tableView.register(cellType, forCellReuseIdentifier: identifier)
        tableView.estimatedRowHeight = height
        tableView.rowHeight = height
        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }
}

// MARK: - ModalConfigurable
protocol ModalConfigurable where Self: UIViewController {
    var closeButton: UIButton! { get set }
    func configureCloseButton()
    func setButtonConstraints()
    func closeButtonPressed()
}

extension ModalConfigurable {
    func configureCloseButton() {
        // close button
        guard let closeButtonImage = UIImage(systemName: "multiply") else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        closeButton = UIButton(type: .custom)
        closeButton.addAction { [weak self] in
            self?.closeButtonPressed()
        }
        closeButton.setImage(closeButtonImage, for: .normal)
        closeButton.tag = 10
        closeButton.tintColor = .black
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
    }
    
    func setButtonConstraints() {
        NSLayoutConstraint.activate([
            // close button
            closeButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            closeButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 60),
            closeButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    func closeButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
}

typealias Closure = () -> ()

///
class ClosureSleeve {
    let closure: Closure
    init(_ closure: @escaping Closure) {
        self.closure = closure
    }
    @objc func invoke () {
        closure()
    }
}

extension UIControl {
    func addAction(for controlEvents: UIControl.Event = .touchUpInside, _ closure: @escaping Closure) {
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
        objc_setAssociatedObject(self, String(format: "[%d]", arc4random()), sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}


protocol FileUploadable {
    func uploadSomething(completion: (() -> Void)?)
}

extension FileUploadable {
    func uploadSomething(completion: (() -> Void)? = nil) {
        print("hello")
        completion?()
    }
}
