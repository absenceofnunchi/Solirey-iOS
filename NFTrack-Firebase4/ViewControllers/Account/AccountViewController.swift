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
    let localDatabase = LocalDatabase()
    
    var tableView: UITableView!
    var data: [AccountMenu] = [
        AccountMenu(imageTitle: "person.circle", imageColor: UIColor(red: 198/255, green: 122/255, blue: 206/255, alpha: 1), titleString: "Update Profile"),
        AccountMenu(imageTitle: "lock.circle", imageColor: UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), titleString: "Reset Password"),
        AccountMenu(imageTitle: "arrowshape.turn.up.right.circle", imageColor: UIColor(red: 156/255, green: 61/255, blue: 84/255, alpha: 1), titleString: "Logout"),
        AccountMenu(imageTitle: "envelope.circle", imageColor: UIColor(red: 61/255, green: 156/255, blue: 133/255, alpha: 1), titleString: "Feedback"),
        AccountMenu(imageTitle: "trash.circle", imageColor: UIColor(red: 49/255, green: 11/255, blue: 11/255, alpha: 1), titleString: "Delete Account")
    ]
    
    var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 14.0, *) {
            data.insert(AccountMenu(imageTitle: "creditcard.circle", imageColor: UIColor(red: 238/255, green: 183/255, blue: 107/255, alpha: 1), titleString: "Wallet")
, at: 0)
        } else {
            data.insert(AccountMenu(imageTitle: "folder.circle", imageColor: UIColor(red: 238/255, green: 183/255, blue: 107/255, alpha: 1), titleString: "Wallet"), at: 0)
        }

        configureNavigationBar(vc: self)
        configureUI()
        setConstraints()
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
                didUpdateProfile()
            case 2:
                didRequestPasswordReset()
            case 3:
                didLogout()
            case 4:
                print("feedback")
            case 5:
                didDeleteUser()
            default:
                break
        }
    }
}

extension AccountViewController {
    //MARK: - didRequestPasswordReset
    func didRequestPasswordReset() {
        let detailVC = DetailViewController(height: 250, detailVCStyle: .withTextField)
        detailVC.titleString = "Enter your email of your account"
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
        let detailVC = DetailViewController(height: 280, detailVCStyle: .withCancelButton)
        detailVC.titleString = "Logout"
        detailVC.message = "Logging out will also delete your wallet from the local storage. Please make sure to remember your password and the private key."
        detailVC.buttonAction = { [weak self] vc in
            self?.dismiss(animated: true, completion: nil)
            self?.showSpinner({
                self?.localDatabase.deleteWallet { (error) in
                    if let error = error {
                        self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self!)
                    } else {
                        let firebaseAuth = Auth.auth()
                        do {
                            try firebaseAuth.signOut()
                        } catch let signOutError as NSError {
                            self?.alert.showDetail("Error", with: "Error signing out: \(signOutError)", for: self!)
                        }
                    }
                }
            })
        }
        self.present(detailVC, animated: true, completion: {
            self.hideSpinner {}
        })
    }
    
    // MARK: - didDeleteUser
    func didDeleteUser() {
        let detailVC = DetailViewController(height: 280, detailVCStyle: .withCancelButton)
        detailVC.titleString = "Delete Account"
        detailVC.message = "Are you sure you want to delete your account? Any transaction records on the blockchain will remain intact."
        detailVC.buttonAction = { [weak self] vc in
            self?.dismiss(animated: true, completion: nil)
            self?.showSpinner({
                self?.localDatabase.deleteWallet { (error) in
                    if let error = error {
                        self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self!)
                    } else {
                        let user = Auth.auth().currentUser
                        user?.delete { error in
                            if let error = error {
                                self?.alert.showDetail("Error resetting the user", with: error.localizedDescription, for: self!)
                            } else {
                                self?.alert.showDetail("Success!", with: "You account has been successfully deleted.", for: self!)
                            }
                        }
                    }
                }
            })
        }
        self.present(detailVC, animated: true, completion: {
            self.hideSpinner {}
        })
    }
    
    // MARK: - didUpdateProfile
    func didUpdateProfile() {
        let profileVC = ProfileViewController()
        profileVC.modalPresentationStyle = .fullScreen
        present(profileVC, animated: true, completion: nil)
    }
}
