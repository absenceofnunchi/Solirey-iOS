//
//  AppDataTypes.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-11.
//

import UIKit

// MARK: - WalletCreationType
enum WalletCreationType {
    case importKey
    case createKey
    
    func title() -> String {
        switch self {
            case .importKey:
                return "Import Wallet"
            case .createKey:
                return "Create Wallet"
        }
    }
}

// MARK: - BorderStyle
struct BorderStyle {
    static func customShadowBorder<T: UIView>(for object: T) {
        let borderColor = UIColor.gray
        object.layer.masksToBounds = false
        object.layer.cornerRadius = 7.0;
        object.layer.borderColor = borderColor.withAlphaComponent(0.3).cgColor
        object.layer.shadowColor = UIColor.black.cgColor
        object.layer.shadowOffset = CGSize(width: 0, height: 0)
        object.layer.shadowOpacity = 0.2
        object.layer.shadowRadius = 4.0
        object.layer.backgroundColor = UIColor.white.cgColor
    }
}

// MARK: - Post
/// ListViewController
/// txHash is either for minting for the very first time or transferring the ownership afterwards
struct Post {
    let documentId: String
    let postId: String
    let sellerUserId: String
    let sellerHash: String
    let title: String
    let description: String
    let date: Date
    let images: [String]?
    let price: String
    let mintHash: String
    let escrowHash: String
    let id: String
    let buyerHash: String? = nil
    let transferHash: String?
}

// MARK: - UILabelPadding
/// ListDetailVC
class UILabelPadding: UILabel {
    let padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }
    
    override var intrinsicContentSize : CGSize {
        let superContentSize = super.intrinsicContentSize
        let width = superContentSize.width + padding.left + padding.right
        let heigth = superContentSize.height + padding.top + padding.bottom
        return CGSize(width: width, height: heigth)
    }
}

// MARK: - UnderlineView
/// ListDetailVC
class UnderlineView: UIView {
    override func draw(_ rect: CGRect) {
        let y: CGFloat = self.bounds.size.height
        let x: CGFloat = self.bounds.size.width
        let aPath = UIBezierPath()
        
        aPath.move(to: CGPoint(x:0, y:y/2))
        aPath.addLine(to: CGPoint(x: x, y: y/2))
        
        // Keep using the method addLine until you get to the one where about to close the path
        aPath.close()
        
        // If you want to stroke it with a red color
        UIColor.lightGray.set()
        aPath.lineWidth = 0.1
        aPath.stroke()
    }
}

// MARK: - Cell
struct Cell {
    static let mainCell = "MainCell"
    static let listCell = "ListCell"
    static let categoryCell = "CategoryCell"
    static let mainDetailCell = "MainDetailCell"
    static let historyCell = "HistoryCell"
}

// MARK: - PurchaseMethods
enum PurchaseMethods: String {
    case abort, confirmPurchase, confirmReceived
}

// MARK: - PurchaseStatus
enum PurchaseStatus: String {
    case created = "Created"
    case locked = "Locked"
    case inactive = "Inactive"
}

// MARK: - PostStatus
/// determines whether to show the post or not
/// when the seller first posts: ready
/// when the seller aborts: ready
/// when the buyer buys: pending
/// when the seller transfers the token: transferred
/// when the transaction is complete: complete
enum PostStatus: String {
    case ready, pending, complete, aborted, resold, transferred
}

// MARK:- PositionStatus
/// when a seller posts an item, it registers its own hash under userId
enum PositionStatus: String {
    case buyerUserId, sellerUserId
}

// MARK: - ViewControllerIdentifiers
struct ViewControllerIdentifiers {
    static let purchaseVC = "purchaseVC"
    static let listVC = "listVC"
}

// MARK: - Category
enum Category: String {
    case electronics = "Electronics"
    case vehicle = "Vehicle"
    case realEstate = "Real Estate"
    case other = "Other"
    
    static func getCategory(num: Int) -> Category? {
        guard num >= 0, num < 4 else { return nil }
        switch num {
            case 0:
                return .electronics
            case 1:
                return .vehicle
            case 2:
                return .realEstate
            case 3:
                return .other
            default:
                return .other
        }
    }
}

// MARK: - CellPosition
/// ListDetailViewController + History
enum CellPosition {
    case first, middle, last
}
