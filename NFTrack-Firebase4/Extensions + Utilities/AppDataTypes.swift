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
//struct Post {
//    let documentId: String
//    let title: String
//    let description: String
//    let date: Date
//    let images: [String]?
//    let price: String
//    let mintHash: String
//    let escrowHash: String
//    let id: String
//    let status: String
//    let sellerUserId: String
//    let sellerHash: String
//    let buyerHash: String?
//    let confirmPurchaseHash: String?
//    let confirmPurchaseDate: Date?
//    let transferHash: String?
//    let transferDate: Date?
//    let confirmReceivedHash: String?
//    let confirmReceivedDate: Date?
//    let savedBy: [String]?
//}

class PostCoreModel {
    var documentId: String!
    var buyerUserId: String?
    var sellerUserId: String!
    
    init(documentId: String, buyerUserId: String?, sellerUserId: String) {
        self.documentId = documentId
        self.buyerUserId = buyerUserId
        self.sellerUserId = sellerUserId
    }
}

class Post: PostCoreModel, MediaConfigurable, DateConfigurable {
    var title: String!
    var description: String!
    var date: Date!
    var files: [String]?
    var price: String!
    var mintHash: String!
    var escrowHash: String!
    var id: String!
    var status: String!
    var sellerHash: String!
    var buyerHash: String?
    var confirmPurchaseHash: String?
    var confirmPurchaseDate: Date?
    var transferHash: String?
    var transferDate: Date?
    var confirmReceivedHash: String?
    var confirmReceivedDate: Date?
    var savedBy: [String]?
    var type: String!
    
    init(documentId: String, title: String, description: String, date: Date, files: [String]?, price: String, mintHash: String, escrowHash: String, id: String, status: String, sellerUserId: String, buyerUserId: String?,sellerHash: String, buyerHash: String?, confirmPurchaseHash: String?, confirmPurchaseDate: Date?, transferHash: String?, transferDate: Date?, confirmReceivedHash: String?, confirmReceivedDate: Date?, savedBy: [String]?, type: String) {
        super.init(documentId: documentId, buyerUserId: buyerUserId, sellerUserId: sellerUserId)
        
        self.title = title
        self.description = description
        self.date = date
        self.files = files
        self.price = price
        self.mintHash = mintHash
        self.escrowHash = escrowHash
        self.id = id
        self.status = status
        self.sellerHash = sellerHash
        self.buyerHash = buyerHash
        self.confirmPurchaseHash = confirmPurchaseHash
        self.confirmPurchaseDate = confirmPurchaseDate
        self.transferHash = transferHash
        self.transferDate = transferDate
        self.confirmReceivedHash = confirmReceivedHash
        self.confirmReceivedDate = confirmReceivedDate
        self.savedBy = savedBy
        self.type = type
    }
}

// MARK: - ChatListModel
class ChatListModel: PostCoreModel {
    var latestMessage: String!
    var date: Date!
    var buyerDisplayName: String!
    var buyerPhotoURL: String!
    var sellerDisplayName: String!
    var sellerPhotoURL: String!
    
    init(documentId: String, latestMessage: String, date: Date, buyerDisplayName: String, buyerPhotoURL: String, buyerUserId: String?, sellerDisplayName: String, sellerPhotoURL: String, sellerUserId: String) {
        super.init(documentId: documentId, buyerUserId: buyerUserId, sellerUserId: sellerUserId)
        self.latestMessage = latestMessage
        self.date = date
        self.buyerDisplayName = buyerDisplayName
        self.buyerPhotoURL = buyerPhotoURL
        self.sellerDisplayName = sellerDisplayName
        self.sellerPhotoURL = sellerPhotoURL
    }
}
// MARK: - UILabelPadding
/// ListDetailVC
class UILabelPadding: UILabel {
    var top: CGFloat = 10
    var extraInternalHeight: CGFloat = 0 {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    lazy var padding = UIEdgeInsets(top: top, left: 10, bottom: 10, right: 10)
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }
    
    override var intrinsicContentSize : CGSize {
        let superContentSize = super.intrinsicContentSize
        let width = superContentSize.width + padding.left + padding.right
        let height = superContentSize.height + padding.top + padding.bottom + extraInternalHeight
        return CGSize(width: width, height: height)
    }
}

// MARK: - TopAlignedLabel
class TopAlignedLabel: UILabel {
    var top: CGFloat = 10
    lazy var padding = UIEdgeInsets(top: top, left: 10, bottom: 10, right: 10)
    override func drawText(in rect: CGRect) {
        let textRect = super.textRect(forBounds: bounds.inset(by: padding), limitedToNumberOfLines: numberOfLines)
        super.drawText(in: textRect)
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

// MARK: - AccountMenu
struct AccountMenu {
    let imageTitle: String
    let imageColor: UIColor
    let titleString: String
}

// MARK: - UserInfo
struct UserInfo {
    let email: String?
    let displayName: String
    let photoURL: String?
    let uid: String?
}

struct UserDefaultKeys {
    static let userId: String = "userId"
    static let displayName: String = "displayName"
    static let photoURL: String = "photoURL"
}


// MARK: - Message
struct Message {
    let id: String
    let content: String
    let displayName: String
    let sentAt: String
    let imageURL: String?
}

// MARK: - Review
struct Review: MediaConfigurable, DateConfigurable {
    let revieweeUserId: String
    let reviewerDisplayName: String
    let reviewerPhotoURL: String
    let reviewerUserId: String
    let starRating: Int
    let review: String
    var files: [String]?
    let confirmReceivedHash: String
    /// receivedDate
    var date: Date!
}

// MARK: - ProfileDetailMenu
enum ProfileDetailMenu: Int, CaseIterable {
    case postings, reviews
    
    func asString() -> String {
        switch self {
            case .postings:
                return "Postings"
            case .reviews:
                return "Reviews"
        }
    }
    
    static func getSegmentText() -> [String] {
        let segmentArr = ProfileDetailMenu.allCases
        var segmentTextArr = [String]()
        for segment in segmentArr {
            segmentTextArr.append(NSLocalizedString(segment.asString(), comment: ""))
        }
        return segmentTextArr
    }
    
    func viewController() -> UIViewController.Type {
        switch self {
            case .postings:
                return ProfilePostingsViewController.self
            case .reviews:
                return ProfileReviewListViewController.self
        }
    }
}

/// for creating button panels i.e., Media button panel
struct PanelButton {
    let imageName: String
    let imageConfig: UIImage.Configuration
    let tintColor: UIColor
    let tag: Int
}

enum PostType: Int, CaseIterable {
    case tangible, digital
    
    func asString() -> String {
        switch self {
            case .tangible:
                return NSLocalizedString("Tangible", comment: "")
            case .digital:
                return NSLocalizedString("Digital", comment: "")
        }
    }
    
    static func getSegmentText() -> [String] {
        let segmentArr = PostType.allCases
        var segmentTextArr = [String]()
        for segment in segmentArr {
            segmentTextArr.append(NSLocalizedString(segment.asString(), comment: ""))
        }
        return segmentTextArr
    }
}
