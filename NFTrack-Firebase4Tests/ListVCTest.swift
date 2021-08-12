//
//  ListVCTest.swift
//  NFTrack-Firebase4Tests
//
//  Created by J C on 2021-08-07.
//

import XCTest

class ListVCTest: XCTestCase {
    enum ItemStatus {
        enum PostStatus: String {
            case ready, pending, transferred, complete
        }
        
        enum AuctionStatus: String {
            case bid, ended, transferred
        }
    }
    
    struct PostingDate {
        
    }
    
    override class func setUp() {
        super.setUp()
    }
    
    func test_progress_cell_display() {
 
    }

    func progressCellClone(status: String, date: String) {
//        let statusLabel1 = UILabel()
//        let statusColor1 = UILabel()
//        let dateLabel1 = UILabel()
//        let dateColor1 = UILabel()
//        
//        let statusLabel2 = UILabel()
//        let statusColor2 = UILabel()
//        let dateLabel2 = UILabel()
//        let dateColor2 = UILabel()
//        
//        let statusLabel3 = UILabel()
//        let statusColor3 = UILabel()
//        let dateLabel3 = UILabel()
//        let dateColor3 = UILabel()
//        
//        switch status {
//            case ItemStatus.PostStatus.ready.rawValue:
//                statusLabel1.text = "ready"
//                dateLabel1.text = "none"
//                statusColor1.text = "lightGray"
//            // first node
//            case ItemStatus.PostStatus.pending.rawValue, ItemStatus.AuctionStatus.bid.rawValue:
//                statusColor1.text = "green"
//                
//                if date == "confirmPurchaseDate" {
//                    dateLabel1.text = "confirmPurchaseDate"
//                } else if date == "bidDate"  {
//                    dateLabel1.text = "bidDate"
//                }
//                
//                dateColor1.text = "green"
//            // second node
//            case ItemStatus.PostStatus.transferred.rawValue, ItemStatus.AuctionStatus.ended.rawValue:
//                statusColor1.text = "green"
//                
//                if date == "confirmPurchaseDate" {
//                    dateLabel1.text = "confirmPurchaseDate"
//                } else if date == "auctionEndDate" {
//                    dateLabel1.text = "auctionEndDate"
//                }
//                dateColor1.text = "green"
//                
//                statusColor2.text = "green"
//                if date == "transferDate" {
//                    dateLabel2.text = "transferDate"
//                } else if date == "auctionEndDate" {
//                    dateLabel2.text = "auctionEndDate"
//                }
//                dateColor2.text = "green"
//            case ItemStatus.PostStatus.complete.rawValue, ItemStatus.AuctionStatus.transferred.rawValue:
//                statusColor1.text = "green"
//                
//                if date == "confirmPurchaseDate" {
//                    dateLabel1.text = "confirmPurchaseDate"
//                } else if date == "auctionEndDate" {
//                    dateLabel1.text = "auctionEndDate"
//                }
//                dateColor1.text = "green"
//                
//                statusColor2.text = "green"
//                if date == "transferDate" {
//                    dateLabel2.text = "transferDate"
//                } else if date == "auctionEndDate" {
//                    dateLabel2.text = "auctionEndDate"
//                }
//                dateColor2.text = "green"
//                
//                if date =
//            default:
//                circleShapeLayer.fillColor = UIColor.white.cgColor
//                circleShapeLayer.strokeColor = UIColor.lightGray.cgColor
//                statusLabel1.textColor = .lightGray
//                
//                dateLabel1.text = ""
//                dateLabel1.textColor = .lightGray
//        }
    }
}
