//
//  ImageProgressCardCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-10-02.
//

/*
 Abstract:
 The tree of Card cell:
 1. ParentTableCell: Compatible with the asynchronous fetching of remote images using Operation and OperationQueue
    1. CardCell: A parent interface that shows the information regarding an item (without the progress meter)
        1. ImageCardCell: An interface with an image
            1. ImageProgressCard: An interface that shows an image and a progress meter
        2. NoImageCardCell: An interface without an image
            1. NoImageProgressCard: An interface that shows no image or a progress meter
 
 Displays items that require displaying the progression of the purchase status
 1. Tangible, payment method: escrow, sale format: online direct, delivery method: shipping
 2. Digital, payment method: escrow, sale format: online direct, delivery method: online
 3. Digital, payment method: beneficiary, sale format: open auction, delivery method: online
 
 Node henceforth refers to "single step" in the purchase progress.  Each step consists of three things: the circle image, status name, and the date.
 */

import UIKit

class ImageProgressCardCell: ImageCardCell, ProgressPanel {
    class override var identifier: String {
        return "ImageProgressCardCell"
    }
    
    var strokeColor: UIColor! = .gray
    var lineWidth: CGFloat! = 0.5
    var selectedColor: UIColor! = UIColor(red: 61/255, green: 156/255, blue: 133/255, alpha: 1)
    var meterContainer: UIView!
    var nodeStackView: UIStackView!
    var nodeCount: CGFloat! = 0
    var progressMeterNodeArr: [ProgressMeterNode]!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // meterContainer has to be initialized here otherwise it creates an odd duplicate in at the top of the cell
        // also cannot be initalized at the declaration in order to conform to the ProgressPanel protocol
        meterContainer = UIView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    override func configure(_ post: Post?) {
        super.configure(post)
        guard let post = post else { return }
        configureMeterContainer(post: post, topView: thumbImageView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        configurePrepareForeReuse()
    }
}
