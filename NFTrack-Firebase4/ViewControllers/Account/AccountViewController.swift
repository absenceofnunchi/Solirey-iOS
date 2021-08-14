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
import FirebaseAuth
import web3swift

class AccountViewController: UIViewController {
    let alert = Alerts()
    let localDatabase = LocalDatabase()
    var scrollView: UIScrollView!
    let balanceCardView = BalanceCardView()
    var tableView: UITableView!
    var data: [AccountMenu] = [
        AccountMenu(imageTitle: "person.circle", imageColor: UIColor(red: 198/255, green: 122/255, blue: 206/255, alpha: 1), titleString: NSLocalizedString("Update Profile", comment: "")),
        AccountMenu(imageTitle: "lock.circle", imageColor: UIColor(red: 226/255, green: 112/255, blue: 58/255, alpha: 1), titleString: NSLocalizedString("Reset Password", comment: "")),
        AccountMenu(imageTitle: "purchased.circle", imageColor: UIColor(red: 255/255, green: 160/255, blue: 160/255, alpha: 1), titleString: NSLocalizedString("Purchases", comment: "")),
        AccountMenu(imageTitle: "arrowshape.turn.up.right.circle", imageColor: UIColor(red: 156/255, green: 61/255, blue: 84/255, alpha: 1), titleString: NSLocalizedString("Logout", comment: "")),
        AccountMenu(imageTitle: "pencil.circle", imageColor: .blue, titleString: NSLocalizedString("Pending Reviews", comment: "")),
        AccountMenu(imageTitle: "envelope.circle", imageColor: UIColor(red: 61/255, green: 156/255, blue: 133/255, alpha: 1), titleString: NSLocalizedString("Feedback", comment: "")),
        AccountMenu(imageTitle: "trash.circle", imageColor: UIColor(red: 49/255, green: 11/255, blue: 11/255, alpha: 1), titleString: NSLocalizedString("Delete Account", comment: ""))
    ]
    var logoutButton: UIButton!
    let CARD_HEIGHT: CGFloat = 200
    let CELL_HEIGHT: CGFloat = 70
    let transactionService = TransactionService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        if #available(iOS 14.0, *) {
//            data.insert(AccountMenu(imageTitle: "creditcard.circle", imageColor: UIColor(red: 238/255, green: 183/255, blue: 107/255, alpha: 1), titleString: "Wallet")
//, at: 0)
//        } else {
//            data.insert(AccountMenu(imageTitle: "folder.circle", imageColor: UIColor(red: 238/255, green: 183/255, blue: 107/255, alpha: 1), titleString: "Wallet"), at: 0)
//        }

        configureNavigationBar(vc: self)
        configureUI()
        setConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let address = Web3swiftService.currentAddress else {
            balanceCardView.balanceLabel.text = "No wallet"
            balanceCardView.walletAddressLabel?.text = ""
            return
        }
        
        DispatchQueue.global().async { [weak self] in
            do {
                let balance = try Web3swiftService.web3instance.eth.getBalance(address: address)
                if let balanceString = Web3.Utils.formatToEthereumUnits(balance, toUnits: .eth, decimals: 4) {
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        self.balanceCardView.balanceLabel.text = "\(self.transactionService.stripZeros(balanceString)) ETH"
                    }
                }
            } catch {
                self?.balanceCardView.balanceLabel.text = "Failed to fetch the balance"
            }
        }
        
        balanceCardView.walletAddressLabel?.text = address.address
    }
}

extension AccountViewController: TableViewConfigurable {
    func configureUI() {
        scrollView = UIScrollView()
        scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentSize = CGSize(
            width: self.view.bounds.size.width,
            height: CARD_HEIGHT + CELL_HEIGHT * CGFloat(data.count) + 200
        )
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        balanceCardView.tag = 7
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        balanceCardView.addGestureRecognizer(tap)
        balanceCardView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(balanceCardView)
        
        tableView = configureTableView(
            delegate: self,
            dataSource: self,
            height: CELL_HEIGHT,
            cellType: AccountCell.self,
            identifier: AccountCell.identifier
        )
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        scrollView.addSubview(tableView)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            balanceCardView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 30),
            balanceCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            balanceCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            balanceCardView.heightAnchor.constraint(equalToConstant: CARD_HEIGHT),
            
            tableView.topAnchor.constraint(equalTo: balanceCardView.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tableView.heightAnchor.constraint(equalToConstant: CELL_HEIGHT * CGFloat(data.count) + 50)
        ])
    }
}

extension AccountViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = AccountCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: AccountCell.identifier)
        cell.selectionStyle = .none
        let datum = data[indexPath.row]
        cell.set(data: datum)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
            case 0:
                didUpdateProfile()
            case 1:
                didRequestPasswordReset()
            case 2:
                let purchasesVC = PurchasesViewController()
                self.navigationController?.pushViewController(purchasesVC, animated: true)
            case 3:
                didLogout()
            case 4:
                review()
            case 5:
                print("feedback")
            case 6:
                didDeleteUser()
            default:
                break
        }
    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer) {
        guard let v = sender.view else { return }
        switch v.tag {
            case 7:
                let walletVC = WalletViewController()
                walletVC.modalPresentationStyle = .fullScreen
                self.present(walletVC, animated: true)
            default:
                break
        }
    }
}

extension AccountViewController {
    //MARK: - didRequestPasswordReset
    func didRequestPasswordReset() {
        let content = [
            StandardAlertContent(
                titleString: AlertModalDictionary.emailSubtitle,
                
                body: ["": ""],
                isEditable: true,
                fieldViewHeight: 50,
                messageTextAlignment: .left,
                alertStyle: .withCancelButton
            )
        ]
        
        let alertVC = AlertViewController(height: 400, standardAlertContent: content)
        alertVC.action = { [weak self] (modal, mainVC) in
            // responses to the main vc's button
            mainVC.buttonAction = { _ in
                guard let email = modal.dataDict[AlertModalDictionary.emailSubtitle],
                      !email.isEmpty else {
                    self?.alert.fading(text: "Email cannot be empty!", controller: mainVC, toBePasted: nil, width: 200)
                    return
                }
                
                self?.dismiss(animated: true) {
                    self?.showSpinner {
                        Auth.auth().sendPasswordReset(withEmail: email) { error in
                            // [START_EXCLUDE]
                            self?.hideSpinner {
                                if let error = error {
                                    self?.alert.showDetail("Error resetting the password", with: error.localizedDescription, for: self)
                                    return
                                }
                                self?.alert.showDetail("Success!", with: "An email has been sent to reset the password", height: 300, for: self)
                            }
                            // [END_EXCLUDE]
                        }
                    }
                }
            } // mainVC
        } // alertVC
        self.present(alertVC, animated: true, completion: nil)
    }
    
    // MARK: - didLogout
    func didLogout() {
        alert.showDetail("Logout", with: "Logging out will also delete your wallet from the local storage. Please make sure to remember your password and the private key.", for: self, alertStyle: .withCancelButton) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
            self?.showSpinner({
                self?.localDatabase.deleteWallet { (error) in
                    if let error = error {
                        self?.hideSpinner {}
                        self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                    } else {
                        let firebaseAuth = Auth.auth()
                        do {
                            try firebaseAuth.signOut()
                            self?.hideSpinner {}
                        } catch let signOutError as NSError {
                            self?.hideSpinner {}
                            self?.alert.showDetail("Error", with: "Error signing out: \(signOutError)", for: self)
                        }
                    }
                }
            })
        } completion: {}
    }
    
    // MARK: - didDeleteUser
    func didDeleteUser() {
        alert.showDetail("Delete Account", with: "Are you sure you want to delete your account? Any transaction records on the blockchain will remain intact.", for: self, alertStyle: .withCancelButton) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
            self?.showSpinner({
                self?.localDatabase.deleteWallet { (error) in
                    if let error = error {
                        self?.hideSpinner {}
                        self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                    } else {
                        self?.hideSpinner {}
                        let user = Auth.auth().currentUser
                        user?.delete { error in
                            if let error = error {
                                self?.alert.showDetail("Error resetting the user", with: error.localizedDescription, for: self)
                            } else {
                                self?.alert.showDetail("Success!", with: "You account has been successfully deleted.", for: self)
                            }
                        }
                    }
                }
            })
        } completion: {}
    }
    
    // MARK: - didUpdateProfile
    func didUpdateProfile() {
        let profileVC = ProfileViewController()
        profileVC.modalPresentationStyle = .fullScreen
        present(profileVC, animated: true, completion: nil)
    }
    
    func review() {
        let reviewVC = ReviewViewController()
        self.navigationController?.pushViewController(reviewVC, animated: true)
    }
}
