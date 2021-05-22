//
//  TxDetailViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-18.
//

import UIKit
import web3swift

class TxDetailViewController: UIViewController {
    var txHash: String!
    var txHashTitleLabel: UILabel!
    var txHashLabel: UILabelPadding!
    var contractTitleLabel: UILabel!
    var contractAddressLabel: UILabelPadding!
    var nonceTitleLabel: UILabel!
    var nonceLabel: UILabel!
    var nonce: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        setConstraints()
    }
}

extension TxDetailViewController {
    func configure() {
        view.backgroundColor = .white
        title = "Transaction Detail"
        
        var receipt: TransactionReceipt!
        do {
            receipt = try Web3swiftService.web3instance.eth.getTransactionReceipt(txHash)
            print("receipt", receipt as Any)
        } catch {
            print(error.localizedDescription)
        }
        
        txHashTitleLabel = UILabel()
        txHashTitleLabel.text = "Transaction Hash"
        txHashTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(txHashTitleLabel)
        
        txHashLabel = UILabelPadding()
        txHashLabel.text = txHash
        txHashLabel.sizeToFit()
        txHashLabel.lineBreakMode = .byClipping
        txHashLabel.numberOfLines = 0
        txHashLabel.layer.borderColor = UIColor.lightGray.cgColor
        txHashLabel.layer.borderWidth = 0.5
        txHashLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(txHashLabel)
        
        contractTitleLabel = UILabel()
        contractTitleLabel.text = "Contract Address"
        contractTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contractTitleLabel)
        
        contractAddressLabel = UILabelPadding()
        contractAddressLabel.sizeToFit()
        contractAddressLabel.lineBreakMode = .byClipping
        contractAddressLabel.layer.borderColor = UIColor.lightGray.cgColor
        contractAddressLabel.numberOfLines = 0
        contractAddressLabel.layer.borderWidth = 0.5
        contractAddressLabel.text = receipt.contractAddress?.address
        contractAddressLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contractAddressLabel)
        
        nonceTitleLabel = UILabel()
        nonceTitleLabel.text = "Nonce"
        nonceTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nonceTitleLabel)
        
        nonceLabel = UILabelPadding()
        nonceLabel.sizeToFit()
        nonceLabel.layer.borderColor = UIColor.lightGray.cgColor
        nonceLabel.layer.borderWidth = 0.5
        nonceLabel.text = nonce
        nonceLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nonceLabel)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            txHashTitleLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 50),
            txHashTitleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            txHashTitleLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            txHashTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            txHashLabel.topAnchor.constraint(equalTo: txHashTitleLabel.bottomAnchor, constant: 0),
            txHashLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            txHashLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
//            txHashLabel.heightAnchor.constraint(equalToConstant: 50),
            
            contractTitleLabel.topAnchor.constraint(equalTo: txHashLabel.bottomAnchor, constant: 20),
            contractTitleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            contractTitleLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            contractTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            contractAddressLabel.topAnchor.constraint(equalTo: contractTitleLabel.bottomAnchor, constant: 0),
            contractAddressLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            contractAddressLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
//            contractAddressLabel.heightAnchor.constraint(equalToConstant: 50),
            
            nonceTitleLabel.topAnchor.constraint(equalTo: contractAddressLabel.bottomAnchor, constant: 20),
            nonceTitleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            nonceTitleLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            nonceTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            nonceLabel.topAnchor.constraint(equalTo: nonceTitleLabel.bottomAnchor, constant: 0),
            nonceLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            nonceLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
//            nonceLabel.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
}
