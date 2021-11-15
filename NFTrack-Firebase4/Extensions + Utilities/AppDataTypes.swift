//
//  AppDataTypes.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-11.
//

import UIKit
import web3swift
import BigInt

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

enum SaleType: String {
    case newSale, resale
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
    var simplePaymentId: String?
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
    var bidDate: Date?
    var auctionEndDate: Date?
    var auctionTransferredDate: Date?
    var address: String?
    var shippingInfo: ShippingInfo?
    var saleType: String!
    var tokenID: String?
    var category: String!
    var contractFormat: String!
    var solireyUid: String? // For the integral contracts (auction, escrow, simple payment) that require a key for mapping
    var bidderWalletAddress: [String: String]? // For the integral auction. The buyerUserId needs to fetched with the wallet address as the key
    
    init(
        documentId: String,
        title: String,
        description: String,
        date: Date,
        files: [String]?,
        price: String,
        mintHash: String,
        escrowHash: String? = "N/A",
        auctionHash: String? = "N/A",
        simplePaymentId: String? = "N/A",
        id: String,
        status: String,
        sellerUserId: String,
        buyerUserId: String?,
        sellerHash: String,
        buyerHash: String?,
        confirmPurchaseHash: String?,
        confirmPurchaseDate: Date?,
        transferHash: String?,
        transferDate: Date?,
        confirmReceivedHash: String?,
        confirmReceivedDate: Date?,
        savedBy: [String]?,
        type: String,
        deliveryMethod: String,
        paymentMethod: String,
        saleFormat: String,
        bidDate: Date?,
        auctionEndDate: Date?,
        auctionTransferredDate: Date?,
        address: String?,
        shippingInfo: ShippingInfo?,
        saleType: String!,
        tokenId: String?,
        category: String,
        contractFormat: String,
        solireyUid: String?,
        bidderWalletAddress: [String: String]? = nil
    ) {
        super.init(documentId: documentId, buyerUserId: buyerUserId, sellerUserId: sellerUserId)
        
        self.title = title
        self.description = description
        self.date = date
        self.files = files
        self.price = price
        self.mintHash = mintHash
        self.escrowHash = escrowHash
        self.auctionHash = auctionHash
        self.simplePaymentId = simplePaymentId
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
        self.bidDate = bidDate
        self.auctionEndDate = auctionEndDate
        self.auctionTransferredDate = auctionTransferredDate
        self.address = address
        self.shippingInfo = shippingInfo
        self.saleType = saleType
        self.tokenID = tokenId
        self.category = category
        self.contractFormat = contractFormat
        self.solireyUid = solireyUid
        self.bidderWalletAddress = bidderWalletAddress
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
    var members: [String]!
    var postingId: String!
    var sellerMemberSince: Date!
    var buyerMemberSince: Date!
    var itemName: String!
    
    init(
        documentId: String,
        latestMessage: String,
        date: Date,
        buyerDisplayName: String,
        buyerPhotoURL: String,
        buyerUserId: String?,
        sellerDisplayName: String,
        sellerPhotoURL: String,
        sellerUserId: String,
        members:[String],
        postingId: String,
        sellerMemberSince: Date,
        buyerMemberSince: Date,
        itemName: String
    ) {
        super.init(documentId: documentId, buyerUserId: buyerUserId, sellerUserId: sellerUserId)
        self.latestMessage = latestMessage
        self.date = date
        self.buyerDisplayName = buyerDisplayName
        self.buyerPhotoURL = buyerPhotoURL
        self.sellerDisplayName = sellerDisplayName
        self.sellerPhotoURL = sellerPhotoURL
        self.members = members
        self.postingId = postingId
        self.sellerMemberSince = sellerMemberSince
        self.buyerMemberSince = buyerMemberSince
        self.itemName = itemName
    }
}

struct SectionedChatList {
    var pinned: [ChatListModel]
    var unpinned: [ChatListModel]
}

// MARK: - UILabelPadding
/// ListDetailVC
class UILabelPadding: UILabel {
    var top: CGFloat = 10
    var left: CGFloat = 10
    var right: CGFloat = 10
    var extraInternalHeight: CGFloat = 0 {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    lazy var padding = UIEdgeInsets(top: top, left: left, bottom: 10, right: right)
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
    
    static func getTangibleResaleOptions() -> [String] {
        let filteredList = Category.allCases.filter { $0.asString() != Category.digital.asString() }
        return filteredList.map { $0.asString() }
    }
}

extension Category: RawRepresentable {
    typealias RawValue = Int
    
    var rawValue: RawValue {
        switch self {
            case .electronics:
                return 0
            case .vehicle:
                return 1
            case .realEstate:
                return 2
            case .digital:
                return 3
            case .other:
                return 4
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
            case "Electronics":
                self = .electronics
            case "Vehicle":
                self = .vehicle
            case "Real Estate":
                self = .realEstate
            case "Digital":
                self = .digital
            case "Other":
                self = .other
            default:
                return nil
        }
    }
    
    init?(rawValue: Int) {
        switch rawValue {
            case 0:
                self = .electronics
            case 1:
                self = .vehicle
            case 2:
                self = .realEstate
            case 3:
                self = .digital
            case 4:
                self = .other
            default:
                return nil
        }
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

// MARK: - ChatListCategory
enum ChatListCategory: String, CaseIterable {
    case seller = "Seller"
    case buyer = "Buyer"
    case item = "Item"
    
//    static func getCategory(num: Int) -> ChatListCategory? {
//        guard num >= 0, num < ChatListCategory.allCases.count else { return nil }
//        switch num {
//            case 0:
//                return .seller
//            case 1:
//                return .buyer
//            case 2:
//                return .item
//            default:
//                return .none
//        }
//    }
    
    static func getCategory(num: Int) -> String? {
        guard num >= 0, num < ChatListCategory.allCases.count else { return nil }
        switch num {
            case 0:
                return "searchableSellerDisplayName"
            case 1:
                return "searchableBuyerDisplayName"
            case 2:
                return "searchableItemName"
            default:
                return .none
        }
    }
    
    static func getAll() -> [String] {
        return ChatListCategory.allCases.map { $0.rawValue }
    }
}

enum ShippingRestriction: String, CaseIterable {
    case cities = "Cities"
    case state = "State"
    case country = "Country"
    case distance = "Distance"
    
    static func getCategory(num: Int) -> ShippingRestriction? {
        guard num >= 0, num < ShippingRestriction.allCases.count else { return nil }
        switch num {
            case 0:
                return .cities
            case 1:
                return .state
            case 2:
                return .country
            case 3:
                return .distance
            default:
                return .none
        }
    }
}

extension ShippingRestriction: RawRepresentable, CaseCountable {
    typealias RawValue = Int
    
    var rawValue: RawValue {
        switch self {
            case .cities:
                return 0
            case .state:
                return 1
            case .country:
                return 2
            case .distance:
                return 3
        }
    }
    
    var stringValue: String {
        switch self {
            case .cities:
                return "Cities"
            case .state:
                return "State"
            case .country:
                return "Country"
            case .distance:
                return "Distance"
        }
    }
    
    init?(rawValue: Int) {
        switch rawValue {
            case 0:
                self = .cities
            case 1:
                self = .state
            case 2:
                self = .country
            case 3:
                self = .distance
            default:
                return nil
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
            case ShippingRestriction.cities.stringValue:
                self = .cities
            case ShippingRestriction.state.stringValue:
                self = .state
            case ShippingRestriction.country.stringValue:
                self = .country
            case ShippingRestriction.distance.stringValue:
                self = .distance
            default:
                return nil
        }
    }
    
    static func getAll() -> [String] {
        return ShippingRestriction.allCases.map { $0.stringValue }
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
    let memberSince: Date?
    var shippingAddress: ShippingAddress? = nil
}

struct ShippingAddress {
    var address: String
    var longitude: Double? = nil
    var latitude: Double? = nil
}

struct UserDefaultKeys {
    static let userId: String = "userId"
    static let displayName: String = "displayName"
    static let photoURL: String = "photoURL"
    static let memberSince: String = "memberSince"
    static let filterSettings: String = "filterSettings"
    static let fcmToken: String = "fcmToken"
    static let address: String = "address"
    static let longitude: String = "longitude"
    static let latitude: String = "latitude"
}

// MARK: - Message
struct Message {
    let id: String
    let content: String
    let sentAt: String
    let sentAtFull: Date
    let imageURL: String?
    let location: ShippingAddress?
    let type: MessageType
    let senderDisplayName: String
    let recipientDisplayName: String
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
    let itemDocId: String
    let uniqueIdentifier: String
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

enum PostType {
    case tangible
    case digital
    
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
    
//    var paymentMethod: [PaymentMethod] {
//        switch self {
//            case .tangible:
//                return [.escrow, .directTransfer]
//            case .digital(.onlineDirect):
//                return [.escrow]
//            case .digital(.openAuction):
//                return [.auctionBeneficiary]
//        }
//    }
}

extension PostType: RawRepresentable, CaseCountable {
    typealias RawValue = Int
    
    var rawValue: RawValue {
        switch self {
            case .tangible:
                return 0
            case .digital:
                return 1
        }
    }
    
    init?(rawValue: Int) {
        switch rawValue {
            case 0:
                self = .tangible
            case 1:
                self = .digital
            default:
                return nil
        }
    }
    
    init?(rawValue: String) {
        let formattedValue = rawValue.lowercased()
        switch formattedValue {
            case "tangible":
                self = .tangible
            case "digital":
                self = .digital
            default:
                return nil
        }
    }
}

// No need to distinguish different payment methods within digital on PostType because PaymentMethod does it separately.
// The initial need for the subdivision was for the Progress view controller, which have switched over to using PaymentMethod
//enum PostType {
//    case tangible
//    case digital(_ saleFormat: SaleFormat)
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
//        let segmentArr = PostType.allValues
//        var segmentTextArr = [String]()
//        for segment in segmentArr {
//            segmentTextArr.append(NSLocalizedString(segment.asString(), comment: ""))
//        }
//        return segmentTextArr
//    }
//
//    var paymentMethod: [PaymentMethod] {
//        switch self {
//            case .tangible:
//                return [.escrow, .directTransfer]
//            case .digital(.onlineDirect):
//                return [.escrow]
//            case .digital(.openAuction):
//                return [.auctionBeneficiary]
//        }
//    }
//}
//
//extension PostType: RawRepresentable, CaseCountable {
//    typealias RawValue = Int
//
//    var rawValue: RawValue {
//        switch self {
//            case .tangible:
//                return 0
//            case .digital(.onlineDirect):
//                return 1
//            case .digital(.openAuction):
//                return 2
//        }
//    }
//
//    init?(rawValue: Int) {
//        switch rawValue {
//            case 0:
//                self = .tangible
//            case 1:
//                self = .digital(.onlineDirect)
//            default:
//                return nil
//        }
//    }
//}

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
    case onlineTransfer = "Online Transfer"
}

enum PaymentMethod: String {
    case escrow = "Escrow"
    case integralEscrow = "Default Escrow"
    case directTransfer = "Direct Transfer" // Simple Payment smart contract
    case integralSimplePayment = "Default Simple Payment"
    case auctionBeneficiary = "Auction Beneficiary"
    case integralAuction = "Default Auction"
}

enum ContractFormat: String, CaseIterable {
    case integral = "Default" // uses the contract pre-launched by the admin
    case individual = "Individual" // deploys a brand new contract just for this particular transaction
    
    static func getAll() -> [String] {
        return ContractFormat.allCases.map { $0.rawValue }
    }
}

// Configures how to post an item depending on the status of its delivery method, payment method, new/resale.
enum SaleConfig {
    case hybridMethod(postType: PostType, saleType: SaleType, delivery: DeliveryMethod, payment: PaymentMethod, contractFormat: ContractFormat)

    var value: DeliveryAndPaymentMethod? {
        switch self {
            case .hybridMethod(postType: .tangible, saleType: .newSale, delivery: .inPerson, payment: .escrow, contractFormat: .integral):
                return .tangibleNewSaleInPersonEscrowIntegral
            case .hybridMethod(postType: .tangible, saleType: .newSale, delivery: .inPerson, payment: .escrow, contractFormat: .individual):
                return .tangibleNewSaleInPersonEscrowIndividual
            case .hybridMethod(postType: .tangible, saleType: .newSale, delivery: .inPerson, payment: .directTransfer, contractFormat: .integral):
                return .tangibleNewSaleInPersonDirectPaymentIntegral
            case .hybridMethod(postType: .tangible, saleType: .newSale, delivery: .inPerson, payment: .directTransfer, contractFormat: .individual):
                return .tangibleNewSaleInPersonDirectPaymentIndividual
            case .hybridMethod(postType: .tangible, saleType: .newSale, delivery: .shipping, payment: .escrow, contractFormat: .integral):
                return .tangibleNewSaleShippingEscrowIntegral
            case .hybridMethod(postType: .tangible, saleType: .newSale, delivery: .shipping, payment: .escrow, contractFormat: .individual):
                return .tangibleNewSaleShippingEscrowIndividual
            case .hybridMethod(postType: .tangible, saleType: .resale, delivery: .inPerson, payment: .escrow, contractFormat: .integral):
                return .tangibleResaleInPersonEscrowIntegral
            case .hybridMethod(postType: .tangible, saleType: .resale, delivery: .inPerson, payment: .escrow, contractFormat: .individual):
                return .tangibleResaleInPersonEscrowIndividual
            case .hybridMethod(postType: .tangible, saleType: .resale, delivery: .inPerson, payment: .directTransfer, contractFormat: .integral):
                return .tangibleResaleInPersonDirectPaymentIntegral
            case .hybridMethod(postType: .tangible, saleType: .resale, delivery: .inPerson, payment: .directTransfer, contractFormat: .individual):
                return .tangibleResaleInPersonDirectPaymentIndividual
            case .hybridMethod(postType: .tangible, saleType: .resale, delivery: .shipping, payment: .escrow, contractFormat: .integral):
                return .tangibleResaleShippingEscrowIntegral
            case .hybridMethod(postType: .tangible, saleType: .resale, delivery: .shipping, payment: .escrow, contractFormat: .individual):
                return .tangibleResaleShippingEscrowIndividual
            case .hybridMethod(postType: .digital, saleType: .newSale, delivery: .onlineTransfer, payment: .directTransfer, contractFormat: .integral):
                return .digitalNewSaleOnlineDirectPaymentIntegral
            case .hybridMethod(postType: .digital, saleType: .newSale, delivery: .onlineTransfer, payment: .directTransfer, contractFormat: .individual):
                return .digitalNewSaleOnlineDirectPaymentIndividual
            case .hybridMethod(postType: .digital, saleType: .newSale, delivery: .onlineTransfer, payment: .auctionBeneficiary, contractFormat: .integral):
                return .digitalNewSaleAuctionBeneficiaryIntegral
            case .hybridMethod(postType: .digital, saleType: .newSale, delivery: .onlineTransfer, payment: .auctionBeneficiary, contractFormat: .individual):
                return .digitalNewSaleAuctionBeneficiaryIndividual
            case .hybridMethod(postType: .digital, saleType: .resale, delivery: .onlineTransfer, payment: .directTransfer, contractFormat: .integral):
                return .digitalResaleOnlineDirectPaymentIntegral
            case .hybridMethod(postType: .digital, saleType: .resale, delivery: .onlineTransfer, payment: .directTransfer, contractFormat: .individual):
                return .digitalResaleOnlineDirectPaymentIndividual
            case .hybridMethod(postType: .digital, saleType: .resale, delivery: .onlineTransfer, payment: .auctionBeneficiary, contractFormat: .integral):
                return .digitalResaleAuctionBeneficiaryIntegral
            case .hybridMethod(postType: .digital, saleType: .resale, delivery: .onlineTransfer, payment: .auctionBeneficiary, contractFormat: .individual):
                return .digitalResaleAuctionBeneficiaryIndividual
            default:
                return nil
        }
    }
}

enum DeliveryAndPaymentMethod {
    case tangibleNewSaleInPersonEscrowIntegral // solirey escrow
    case tangibleNewSaleInPersonEscrowIndividual // escrow
    case tangibleNewSaleInPersonDirectPaymentIntegral // solirey simple payment
    case tangibleNewSaleInPersonDirectPaymentIndividual // simple payment
    case tangibleNewSaleShippingEscrowIntegral // solirey escrow
    case tangibleNewSaleShippingEscrowIndividual // escrow
    case tangibleResaleInPersonEscrowIntegral // solirey escrow
    case tangibleResaleInPersonEscrowIndividual // escrow
    case tangibleResaleInPersonDirectPaymentIntegral // solirey simple payment
    case tangibleResaleInPersonDirectPaymentIndividual // simple payment
    case tangibleResaleShippingEscrowIntegral // solirey escrow
    case tangibleResaleShippingEscrowIndividual // escrow
    case digitalNewSaleOnlineDirectPaymentIntegral // solirey simple payment
    case digitalNewSaleOnlineDirectPaymentIndividual  // simple payment
    case digitalNewSaleAuctionBeneficiaryIntegral // auction
    case digitalNewSaleAuctionBeneficiaryIndividual // solirey auction
    case digitalResaleOnlineDirectPaymentIntegral // solirey simple payment
    case digitalResaleOnlineDirectPaymentIndividual // simple payment
    case digitalResaleAuctionBeneficiaryIntegral // solirey auction
    case digitalResaleAuctionBeneficiaryIndividual // auction
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
    
    static let pending = """
    Pending could mean: \n\n1. There is a bid transaction from a user that is either waiting or in the process of being mined. \n\n2. The app has requested the auction details from the block chain. \n\n3. You have withdrawn the previous bid and the transaction is in the process of being mined \n\nThe relevant information will be updated on your screen soon after the transaction is added to the blockchain.
    """
    
    static let pendingEscrow = """
    Pending could mean either that there are transactions such as the confirmation of the purchase, transfer of the asset, confirmation of the receipt are being mined and added to the blockchain or the app is fetching certain information from the smart contract.
    """
    
    static let withdraw = """
    You have been outbid by a higher bid. The previous bid made by you has to be withdrawn BY YOU to be transferred back to your wallet. It will not be done automatically.
    """
    static let withdrawPrior = """
    Once you have been outbid by a higher bid, the previous bid made by you has to be withdrawn BY YOU for the fund to be transferred back to your wallet. It will not be done automatically. This is the safest way for your fund to be withdrawn in Ethereum.\n\nThe button to withdraw will be presented on the app once you are outbid.
    """
    static let auctionStatus = """
    The auction status is either "active" or "ended". When the auction's time expires, you will no longer be able to bid, but you will have to officially end the auction by pressing the "End Auction" button, which will be presented after the expiration. The auction can be ended by anyone as long as the time has expired and is required prior to either transferring the asset or receiving the winning bid as a beneficiary.
    """
    static let receiptPending = """
    The buyer will update the status when they receive the item, after which the transaction is completed.  You will be able to withdraw your fund from the escrow after the confirmation of the receipt by the buyer.
    """
    static let transferCompleted = """
    Congratulations! You have successfully completed the selling process.
    """
    
    static let pricing = """
    The price value has to be an even number.
    """
    
    static let created = """
    The item is available for a potential buyer to purchase by sending the price * 2 to the escrow contract. Requiring double the amount of the price for both the buyer and the seller is to incentivize both parties to complete the transaction in an efficient manner.  The buyer is also required to the disclose the shipping address to the seller.
    """
    
    static let locked = """
    The buyer has sent the required ETH to the escrow contract and secured the right to purchase the item.  The seller is in the process of transferring the ownership of the item on the blockchain as well as shipping the actual item to the buyer.
    """
    
    static let inactive = """
    The buyer has confirmed the receipt of the item and the related funds distributed to the rightful owners.
    """
    
    static let shippingInfo = """
    Important: Write out the address of your scope in full (i.e. "British Columbia Canada") even if the autocomplete doesn't complete the address for you.\n\n
    Specify which areas you are willing to ship your item to by cities, states/provinces, countries or by distance from your location.  You can specify multiple areas of the same scope, such as Toronto (a city) and Mississauga (a city), but you cannot combine localities of different scopes, such as Toronto (a city) and Manitoba (a province).  \n\nIt's the seller's sole responsibility to ensure that the logistics of shipping is properly implemented, therefore it is very important to research how much the shipping cost is going to be and if it's within how much you're willing to pay for since once the purchase is made by a buyer, you are obligated to carry out the shipping or risk losing of the deposit. \n\nThere is no way to dynamically change the shipping limitation according to the location of the buyer since the escrow smart contract and the deposit is created prior to a buyer's purchase.  No buyers outside of your shipping limitation can purchase your item.\n\nThe order of the transaction is as follows:\n\n1. The seller posts the item along with the escrow smart contract and the deposit.\n\n2. The buyer purchases the item by sending the required amount of ether to the smart contract.\n\n3. The seller ships the item by bearing the cost of the shipping and transfers the ownership on the blockchain.\n\n4. The buyer confirms the receipt of the item and the smart contract allows each party to withdraw the deposits.\n\nNote that if you want to specify a greater city area such as the Greater Toronto Area, you will have to include all the relevant cities individually such as York, North York, etc. 
    """

    static let shippingUnavailable = """
    The seller has specified that the shipping is unavailable to your area.
    """
    
    static let quickUICheck = """
    The Unique Identifier (UI) is given to each registered item to fasciliate the tracking of the resale history.  If an item with the same UI already exists, it cannot be posted as a new item, but has to be resold from the section of your purchased items called Purchases.  If an item was not initially purchased from the app, but is already listed (i.e. a gift), please contact the support.
    """
    
    static let simplePaymentComplete = """
    You have successfully purchased the item. Check the "Purchases" menu in the "Accounts" tab to see your item.
    """
    
    static let fundsToCollect = """
    Certain smart contracts such as "Direct Transfer" requires the seller to withdraw the fund paid by the buyer, instead of the fund automatically being transferred into the seller's account.  This is the safest way to move the fund into the seller's account. The fund will safely reside in the smart contract used in the transaction indefinitely and only the seller is authorized to withdraw the it into his or her account at their convenience.
    """
    
    static let profileInfo = """
    Your email and the address are not publicly visible. The address is used to provide optimal search results when a user is looking for a tangible item to purchase in his/her vicinity or to determine whether a buyer meets the seller's shipping condition.  \n\nWhen purchasing a tangible item that requires shipping, you will be prompted to provide a permission to disclose your shipping address to the seller.
    """
    
    static let ownerOf = """
    Prior to the resale of your item, it is recommended that you confirm the ownership of the current item on the blockchain. This is ensure that you're using the same wallet used to purchase the current item or the ownership has not been transferred to another wallet.
    """
    
    static let contractFormatInfo = """
    The individual smart contract option will deploy a brand new smart contract to the blockchain specifically designated to your transaction.
    """
    
    static let auctionEnded = """
    The auction has already ended!
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
    static let emailSubtitle = "Please enter the email of your account"
    static let passwordSubtitle = "Please Enter Your Password"
    static let gasLimit = "Gas Limit"
    static let gasPrice = "Gas Price"
    static let nonce = "Nonce"
    static let walletPasswordRequired = "Wallet Password Required"
}

enum TxType {
    case mint
    case deploy
    case transferToken
    case bid
    case endAuction
    case auctionContract
    case simplePayment
    case NFTrack
    case resell
}

struct TxResult {
    let senderAddress: String
    let txHash: String
    let txType: TxType
}

struct TxResult2 {
    let senderAddress: String
    let txResult: TransactionSendingResult
    let txType: TxType
}

struct TxPackage {
    let transaction: WriteTransaction
    let gasEstimate: BigUInt
    let price: String?
    let type: TxType
    var nonce: BigUInt? = nil
}

// MARK: - Topics
struct Topics {
    static let HighestBidIncreased = "0xf4757a49b326036464bec6fe419a4ae38c8a02ce3e68bf0809674f6aab8ad300"
    static let Transfer = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
    static let Transfer2 = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
    static let PurchaseConfirmed = "0xd5d55c8a68912e9a110618df8d5e2e83b8d83211c57a8ddd1203df92885dc881"
    static let ItemReceived = "0xe89152acd703c9d8c7d28829d443260b411454d45394e7995815140c8cbcbcf7"
    static let Aborted = ""
    static let SimplePaymentPurchased = "0x3a2d0e41c506b136330c6e5e0295ccbf0966daece99bfe7c89020cc01dbfb8d6"
    static let SimplePaymentMint = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
    
    struct IntegralAuction {
        static let auctionCreated = "0x5d551e2a2cc977fd8c530317059b4f2d9f504fb82f7dfad736f8d56679bcdfd0"
        static let transfer = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
        static let bid = "0xda0a18da71d8ebd145966339a728fc0d8ccc07c22870d561890d823c515dda6b"
        static let auctionEnd = "0x45806e512b1f4f10e33e8b3cb64d1d11d998d8c554a95e0841fc1c701278bd5d"
    }
    
    struct IndividualAuction {
        static let mintNft = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
    }
}

struct ContractAddresses {
    static let NFTrackABIRevisedAddress = EthereumAddress("0xd3F95b3292Cbc7543228B6edEDFA42b474651e8D")
    static let integralAuctionAddress = EthereumAddress("0x6d23ebe8d9ff75fe79fc0f4ae4b75b811cad2daa")
    static let solireyMintContractAddress = EthereumAddress("0x7714F9D47cb475fE1F8041c8CE60b6B98487a454")
//    static let solireyMintContractAddress = EthereumAddress("0x0b7964f34699bf1db6642d34bb10226aaa47fff2")
}

struct ShippingInfo {
    let scope: ShippingRestriction
    let addresses: [String]
    let radius: Double
    let longitude: Double?
    let latitude: Double?
}


enum MessageType: String {
    case text = "Text"
    case image = "Image"
    case location = "Location"
}

struct ProgressMeterNode {
    let statusLabelText: String
    var dateLabelText: String? = ""
}

class MintParameters: NSObject {
    let price: String?
    let itemTitle: String
    let desc: String
    let category: String
    let convertedId: String
    let tokensArr: Set<String>
    let userId: String
    let deliveryMethod: String
    let saleFormat: String
    let paymentMethod: String
    let contractFormat: String
    let postType: String
    let saleConfigValue: DeliveryAndPaymentMethod?
    var biddingTime: Int? = nil
    var startingBid: NSNumber? = nil
    
    init(
        price: String?,
        itemTitle: String,
        desc: String,
        category: String,
        convertedId: String,
        tokensArr: Set<String>,
        userId: String,
        deliveryMethod: String,
        saleFormat: String,
        paymentMethod: String,
        contractFormat: String,
        postType: String,
        saleConfigValue: DeliveryAndPaymentMethod?
    ) {
        self.price = price
        self.itemTitle = itemTitle
        self.desc = desc
        self.category = category
        self.convertedId = convertedId
        self.tokensArr = tokensArr
        self.userId = userId
        self.deliveryMethod = deliveryMethod
        self.saleFormat = saleFormat
        self.paymentMethod = paymentMethod
        self.contractFormat = contractFormat
        self.postType = postType
        self.saleConfigValue = saleConfigValue
    }
}
