//
//  AccountViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-06.
//
/*
 wallet
 reset password
 logout
 delete user
 */

import UIKit
import Firebase

class AccountViewController: UIViewController {
    let alert = Alerts()
    var tableView: UITableView!
    let data: [AccountMenu] = [
        AccountMenu(imageTitle: "creditcard.circle", imageColor: UIColor(red: 238/255, green: 183/255, blue: 107/255, alpha: 1), titleString: "Wallet"),
        AccountMenu(imageTitle: "lock.circle", imageColor: UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), titleString: "Reset Password"),
        AccountMenu(imageTitle: "arrowshape.turn.up.right.circle", imageColor: UIColor(red: 156/255, green: 61/255, blue: 84/255, alpha: 1), titleString: "Logout"),
        AccountMenu(imageTitle: "envelope.circle", imageColor: UIColor(red: 61/255, green: 156/255, blue: 133/255, alpha: 1), titleString: "Feedback"),
        AccountMenu(imageTitle: "trash.circle", imageColor: UIColor(red: 49/255, green: 11/255, blue: 11/255, alpha: 1), titleString: "Delete Account")
    ]
    
    var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar(vc: self)
        configureUI()
        setConstraints()
    }
    
    @objc func buttonPressed() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
}

extension AccountViewController: TableViewConfigurable {
    func configureUI() {
        tableView = configureTableView(delegate: self, dataSource: self, height: 80, cellType: AccountCell.self, identifier: Cell.accountCell)
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        view.addSubview(tableView)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
        ])
    }
}

extension AccountViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = AccountCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: Cell.accountCell)
        cell.selectionStyle = .none
        let datum = data[indexPath.row]
        cell.set(data: datum)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
            case 0:
                let walletVC = WalletViewController()
                walletVC.modalPresentationStyle = .fullScreen
                self.present(walletVC, animated: true)
            case 1:
                didRequestPasswordReset()
            case 2:
                didLogout()
            case 3:
                print("feedback")
            case 4:
                didDeleteUser()
            default:
                break
        }
    }
}

extension AccountViewController {
    //MARK: - didRequestPasswordReset
    func didRequestPasswordReset() {
        let detailVC = DetailViewController(height: 250, isTextField: true)
        detailVC.titleString = "Enter your email"
        detailVC.buttonAction = { [weak self] vc in
            if let dvc = vc as? DetailViewController, let email = dvc.textField.text {
                self?.dismiss(animated: true, completion: {
                    self?.showSpinner {
                        Auth.auth().sendPasswordReset(withEmail: email) { error in
                            // [START_EXCLUDE]
                            self?.hideSpinner {
                                if let error = error {
                                    self?.alert.showDetail("Error resetting the password", with: error.localizedDescription, for: self!)
                                    return
                                }
                                self?.alert.showDetail("Success!", with: "An email has been sent to reset the password", for: self!)
                            }
                            // [END_EXCLUDE]
                        }
                    }
                })
            }
        }
        self.present(detailVC, animated: true, completion: nil)
    }
    
    // MARK: - didLogout
    func didLogout() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            self.alert.showDetail("Error", with: "Error signing out: \(signOutError)", for: self)
        }
    }
    
    // MARK: - didDeleteUser
    func didDeleteUser() {
        let user = Auth.auth().currentUser
        
        user?.delete { error in
            if let error = error {
                self.alert.showDetail("Error resetting the user", with: error.localizedDescription, for: self)
            } else {
                self.alert.showDetail("Success!", with: "You account has been successfully deleted.", for: self)
            }
        }
    }
}

struct AccountMenu {
    let imageTitle: String
    let imageColor: UIColor
    let titleString: String
}
