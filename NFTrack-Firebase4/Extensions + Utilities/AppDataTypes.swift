//
//  AppDataTypes.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-11.
//

import UIKit
import web3swift

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
    var escrowHash: String?
    var auctionHash: String?
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
    var deliveryMethod: String!
    var paymentMethod: String!
    var saleFormat: String!
    
    init(documentId: String, title: String, description: String, date: Date, files: [String]?, price: String, mintHash: String, escrowHash: String? = "N/A", auctionHash: String? = "N/A", id: String, status: String, sellerUserId: String, buyerUserId: String?,sellerHash: String, buyerHash: String?, confirmPurchaseHash: String?, confirmPurchaseDate: Date?, transferHash: String?, transferDate: Date?, confirmReceivedHash: String?, confirmReceivedDate: Date?, savedBy: [String]?, type: String, deliveryMethod: String, paymentMethod: String, saleFormat: String) {
        super.init(documentId: documentId, buyerUserId: buyerUserId, sellerUserId: sellerUserId)
        
        self.title = title
        self.description = description
        self.date = date
        self.files = files
        self.price = price
        self.mintHash = mintHash
        self.escrowHash = escrowHash
        self.auctionHash = auctionHash
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
        self.deliveryMethod = deliveryMethod
        self.paymentMethod = paymentMethod
        self.saleFormat = saleFormat
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
//enum Category: String {
//    case electronics = "Electronics"
//    case vehicle = "Vehicle"
//    case realEstate = "Real Estate"
//    case digital = "Digital"
//    case other = "Other"
//}

enum Category: Int, CaseIterable {
    case electronics
    case vehicle
    case digital
    case realEstate
    case other
    
    func asString() -> String {
        switch self {
            case .electronics:
                return "Electronics"
            case .vehicle:
                return "Vehicle"
            case .realEstate:
                return "Real Estate"
            case .digital:
                return "Digital"
            case .other:
                return "Other"
        }
    }
    
    static func getAll() -> [String] {
        return Category.allCases.map { $0.asString() }
    }
}

// MARK: - ScopeButtonCategory
enum ScopeButtonCategory: String, CaseIterable {
    case latest = "Latest"
    case categoryFilter = "Filtered Search"
    
    static func getCategory(num: Int) -> ScopeButtonCategory? {
        guard num >= 0, num < ScopeButtonCategory.allCases.count else { return nil }
        switch num {
            case 0:
                return .latest
            case 1:
                return .categoryFilter
            default:
                return .none
        }
    }
    
    static func getAll() -> [String] {
        return ScopeButtonCategory.allCases.map { $0.rawValue }
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
    static let filterSettings: String = "filterSettings"
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

//enum PostType: Int, CaseIterable {
//    case tangible
//    case digital
//
//    func asString() -> String {
//        switch self {
//            case .tangible:
//                return NSLocalizedString("Tangible", comment: "")
//            case .digital:
//                return NSLocalizedString("Digital", comment: "")
//        }
//    }
//
//    static func getSegmentText() -> [String] {
//        let segmentArr = PostType.allCases
//        var segmentTextArr = [String]()
//        for segment in segmentArr {
//            segmentTextArr.append(NSLocalizedString(segment.asString(), comment: ""))
//        }
//        return segmentTextArr
//    }
//}

enum PostType {
    case tangible
    case digital(_ saleFormat: SaleFormat)
    
    func asString() -> String {
        switch self {
            case .tangible:
                return NSLocalizedString("Tangible", comment: "")
            case .digital:
                return NSLocalizedString("Digital", comment: "")
        }
    }
    
    static func getSegmentText() -> [String] {
        let segmentArr = PostType.allValues
        var segmentTextArr = [String]()
        for segment in segmentArr {
            segmentTextArr.append(NSLocalizedString(segment.asString(), comment: ""))
        }
        return segmentTextArr
    }
}

extension PostType: RawRepresentable, CaseCountable {
    typealias RawValue = Int

    var rawValue: RawValue {
        switch self {
            case .tangible:
                return 0
            case .digital(.onlineDirect):
                return 1
            case .digital(.openAuction):
                return 2
        }
    }
    
    init?(rawValue: Int) {
        switch rawValue {
            case 0:
                self = .tangible
            case 1:
                self = .digital(.onlineDirect)
            default:
                return nil
        }
    }
}

protocol CaseCountable {
    static var caseCount: Int { get }
    static var allValues: [Self] { get }
}

extension CaseCountable where Self: RawRepresentable, Self.RawValue == Int {
    internal static var caseCount: Int {
        var count = 0
        while let _ = Self(rawValue: count) {
            count += 1
        }
        return count
    }
    
    internal static var allValues: [Self] {
        var allValuesArr = [Self]()
        var count = 0
        while let rawValue = Self(rawValue: count) {
            allValuesArr.append(rawValue)
            count += 1
        }
        return allValuesArr
    }
}


enum SaleFormat: String {
    case onlineDirect = "Online Direct"
    case openAuction = "Open Auction"
}


// MARK: - Delivery method
enum DeliveryMethod: String {
    case shipping = "Shipping"
    case inPerson = "In Person Pickup"
}

enum PaymentMethod: String {
    case escrow = "Escrow"
    case directTransfer = "Direct Transfer"
    case auctionBeneficiary = "Auction Beneficiary"
}

// MARK: - FilterSettings
struct FilterSettings: Codable {
    let priceLimit: Float
    var itemIndexPath: IndexPath?
    var priceIsDescending: Bool = false
    var dateIsDescending: Bool = false
}


struct InfoText {
    static let deliveryMethod = """
    The method of payment is escrow for shipping and a direct account-to-account transfer for the in-person pickup. The method cannot be modified after the item has been posted.
    """
    static let transferPending = """
    You're almost there! Currently waiting for the owner to transfer the ownership on the blockchain so hang tight!
    """
    
    static let escrow = """
    Leveraging the smart contracts' ability to facilitate two trustless parties to easily exchange goods/services without an intermediary, escrow is the designated payment method for shipping a non-digital product. How does it work?
    
    When you post your item, an escrow smart contract gets deployed to the blockchain. Along with the contract is required a deposit for the item you're selling. Why do you need to make a deposit if you're the seller?  It's so that the buyer and the seller both have the incentive to complete the transaction in a timely manner.

    The deposit amount required is two times the price of the item. For example, if you are pricing your item at 1 ETH, the deposit is 2 x 1 = 2 ETH. The deposit is fully refunded upon the buyer's acceptence of your item. The buyer also makes a deposit on top of the price of the item which means if your item is priced at 1 ETH, the total amount required to purchase your item is 3 ETH.  Upon the buyer's acceptence of your item, the price of your item gets paid to your account and the deposit gets refunded back to the buyer.  If the buyer does not receive your item, your deposit as well as the buyer's deposit gets locked up in the escrow's contract indefinitely.

    To sum up, following is the order of purchasing a non-digital good through an escrow contract:

    1. First, you post your item along with the escrow contract and the deposit.

    2. The buyer purchases the item by paying the price of the item along with the deposit into the escrow account.

    3. You ship your item to the buyer's address and press "Transfer Ownership" on the app.

    4. The buyer confirms the arrival of your item and the item is in a condition as represented.

    5. The deposit gets paid out to both parties.
    """
    static let directTransfer = """
    Direct transfer is the designated payment method for in-person pickup. The wallet on the app has to be used to send the ether in order for the item's corresponding token on the blockchain to be transferred to your ownership.
    """
    
    static let onlineDirect = """
    Direct sale is the designated format for tangible items, as opposed to the auction format available to the digital items.
    """
    
    static let onlineDigital = """
    A P2P transfer using the escrow payment method.  See "Escrow" from the information button of "Payment Method"
    """
    
    static let auctionBeneficiary = """
    As the beneficiary of the auction, you get to withdraw the final bidding amount from the auction smart contract after the auction has ended.
    """
    
    static let auction = """
    An auction smart contract gets deployed to the blockchain when you post your item.  You set the bidding time limit. The starting price is from zero.  When the auction is finished, the token gets transferred to the buyer and you get to withdraw the final bid amount as a beneficiary. If no bid exists, you get to withdraw the token.
    """
}

// MARK: - SmartContractProperty
struct SmartContractProperty {
    let propertyName: String
    var propertyDesc: Any? = nil
    var transaction: ReadTransaction? = nil
}

// MARK: - AlertModalDictionary
/// the keys of the dictionary for displaying the alert modal as well as parsing the user input from the modal
struct AlertModalDictionary {
    static let passwordTitle = "Password"
    static let emailSubtitle = "Please Enter the email of your account"
    static let passwordSubtitle = "Please Enter Your Password"
    static let gasLimit = "Gas Limit"
    static let gasPrice = "Gas Price"
    static let nonce = "Nonce"
}
