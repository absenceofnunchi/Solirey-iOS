//
//  ProgressCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-06.
//

/*
 Abstract:
 Displays items that require displaying the progression of the purchase status
 1. Tangible, payment method: escrow, sale format: online direct, delivery method: shipping
 2. Digital, payment method: escrow, sale format: online direct, delivery method: online
 3. Digital, payment method: beneficiary, sale format: open auction, delivery method: online
 
 Node henceforth refers to "single step" in the purchase progress.  Each step consists of three things: the circle image, status name, and the date.
 */

import UIKit

struct ProgressMeterNode {
    let statusLabelText: String
    var dateLabelText: String? = ""
}

class ProgressCell: CardCell {
    class override var identifier: String {
        return "ProgressCell"
    }
    
    final var strokeColor: UIColor = .gray
    final var lineWidth: CGFloat = 0.5
    final let selectedColor = UIColor(red: 61/255, green: 156/255, blue: 133/255, alpha: 1)
    // contains the entire meter: the circle, line, node title, date
    final var meterContainer = UIView()
    // contains the node title and the date
    final var nodeStackView: UIStackView!
    final var nodeCount: CGFloat = 0
    
    override func configure(_ post: Post?) {
        super.configure(post)
        
        guard let post = post else { return }

        meterContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(meterContainer)
        
        nodeStackView = UIStackView()
        nodeStackView.axis = .horizontal
        nodeStackView.distribution = .fillEqually
        nodeStackView.translatesAutoresizingMaskIntoConstraints = false
        meterContainer.addSubview(nodeStackView)

        // constraints of the meter container depending on the existence of the thumb image
        var progressConstraints = [NSLayoutConstraint]()
        if let files = post.files, files.count > 0 {
            progressConstraints += [
                meterContainer.topAnchor.constraint(equalTo: thumbImageView.bottomAnchor, constant: 10),
            ]
        } else {
            progressConstraints += [
                meterContainer.topAnchor.constraint(equalTo: descContainer.bottomAnchor, constant: 10),
            ]            
        }

        progressConstraints += [
            meterContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            meterContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            meterContainer.heightAnchor.constraint(equalToConstant: 100),
            
            nodeStackView.leadingAnchor.constraint(equalTo: meterContainer.leadingAnchor),
            nodeStackView.trailingAnchor.constraint(equalTo: meterContainer.trailingAnchor),
            nodeStackView.heightAnchor.constraint(equalTo: meterContainer.heightAnchor, multiplier: 0.5),
            nodeStackView.bottomAnchor.constraint(equalTo: meterContainer.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(progressConstraints)
        meterContainer.layoutIfNeeded()
        
        // parse Post so that the node title like "Bid" or "Purchase" is paired up with its own dates accordingly
        var progressMeterNodeArr = [ProgressMeterNode]()
        if post.saleFormat == SaleFormat.openAuction.rawValue {
            // auction
            
            // auction first node
            let bidNode = ProgressMeterNode(statusLabelText: AuctionStatus.bid.toDisplay, dateLabelText: processDate(date: post.bidDate))
            progressMeterNodeArr.append(bidNode)

            // auction second node
            let endedNode = ProgressMeterNode(statusLabelText: AuctionStatus.ended.toDisplay, dateLabelText: processDate(date: post.auctionEndDate))
            progressMeterNodeArr.append(endedNode)
            
            // auction third node
            let auctionTransferNode = ProgressMeterNode(statusLabelText: AuctionStatus.transferred.toDisplay, dateLabelText: processDate(date: post.auctionTransferredDate))
            progressMeterNodeArr.append(auctionTransferNode)
        } else {
            // tangible and digital escrow
            
            // first node
            let purchaseDateNode = ProgressMeterNode(statusLabelText: "Purchased", dateLabelText: processDate(date: post.confirmPurchaseDate))
            progressMeterNodeArr.append(purchaseDateNode)
            
            // second node
            let transferNode = ProgressMeterNode(statusLabelText: "Transferred", dateLabelText: processDate(date: post.transferDate))
            progressMeterNodeArr.append(transferNode)
            
            // third node
            let receivedNode = ProgressMeterNode(statusLabelText: "Received", dateLabelText: processDate(date: post.confirmReceivedDate))
            progressMeterNodeArr.append(receivedNode)
        }
        
        configureProgressMeter(nodeArray: progressMeterNodeArr)
    }
}

extension ProgressCell {
    // 2 points
    // (1 / 2) * (1 / 2) = 1 / 4
    // 1 / 4, 3 / 4
    
    // 3 points
    // (1 / 3) * (1 / 2) = 1 / 6
    // 1 / 6, 5 / 5
    
    // 4 points
    // (1 / 4) * (1 / 2) = 1 / 8
    // 1 / 8, 7 / 8
    
    func configureProgressMeter(
        nodeArray: [ProgressMeterNode],
        offset: CGFloat = -20
    ) {
        // multiplied by 2 because we're finding the middle point between the nodes
        // as specified in the above example calculations, the midpoint is always 1/2 of any number of nodes
        nodeCount = CGFloat(nodeArray.count) * 2
        
        // the horizontal line throught the circular nodes
        let path = UIBezierPath()
        path.move(to: CGPoint(x: meterContainer.bounds.width / (nodeCount), y: meterContainer.bounds.midY + offset))
        path.addLine(to: CGPoint(x: (meterContainer.bounds.width / (nodeCount)) * (nodeCount - 1), y: meterContainer.bounds.midY + offset))
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = lineWidth
        shapeLayer.strokeColor = strokeColor.cgColor
        meterContainer.layer.addSublayer(shapeLayer)
        
        // the circular nodes + node containers (status label + date label)
        for (i, element) in stride(from: 1, to: Int(nodeCount), by: 2).enumerated() {
            let circlePath = UIBezierPath(
                arcCenter: CGPoint(x: (meterContainer.bounds.width / (nodeCount)) * CGFloat(element),
                                   y: meterContainer.bounds.midY + offset),
                radius: 8, startAngle: CGFloat(0),
                endAngle: CGFloat.pi * 2,
                clockwise: true
            )
            circlePath.lineWidth = lineWidth
            
            let circleShapeLayer = CAShapeLayer()
            circleShapeLayer.strokeColor = strokeColor.cgColor
            circleShapeLayer.fillColor = UIColor.white.cgColor
            circleShapeLayer.lineWidth = lineWidth
            circleShapeLayer.path = circlePath.cgPath
            circleShapeLayer.lineWidth = lineWidth
            circleShapeLayer.name = "circle"
            meterContainer.layer.addSublayer(circleShapeLayer)
            
            let nodeContainer = UIView()
            nodeContainer.translatesAutoresizingMaskIntoConstraints = false
            nodeStackView.addArrangedSubview(nodeContainer)
            
            let progressMeterNode = nodeArray[i]
            
            let statusLabel = createStatusLabel(text: progressMeterNode.statusLabelText)
            statusLabel.textAlignment = .center
            statusLabel.tag = 500 + i
            statusLabel.translatesAutoresizingMaskIntoConstraints = false
            nodeContainer.addSubview(statusLabel)
            
            let dateLabel = createStatusLabel(text: progressMeterNode.dateLabelText ?? "")
            dateLabel.textAlignment = .center
            dateLabel.tag = 600 + i
            dateLabel.translatesAutoresizingMaskIntoConstraints = false
            nodeContainer.addSubview(dateLabel)
            
            // if the date isn't null, it means the execution happened on those dates, therefore change the color of the node accordingly
            if progressMeterNode.dateLabelText != nil {
                circleShapeLayer.fillColor = selectedColor.cgColor
                circleShapeLayer.strokeColor = selectedColor.cgColor
                statusLabel.textColor = selectedColor
                dateLabel.textColor = selectedColor
            }
            
            NSLayoutConstraint.activate([
                statusLabel.topAnchor.constraint(equalTo: nodeContainer.topAnchor),
                statusLabel.widthAnchor.constraint(equalTo: nodeContainer.widthAnchor),
                statusLabel.heightAnchor.constraint(equalTo: nodeContainer.heightAnchor, multiplier: 0.50),
                
                dateLabel.bottomAnchor.constraint(equalTo: nodeContainer.bottomAnchor),
                dateLabel.widthAnchor.constraint(equalTo: nodeContainer.widthAnchor),
                dateLabel.heightAnchor.constraint(equalTo: nodeContainer.heightAnchor, multiplier: 0.50)
            ])
        }
    }
}

extension ProgressCell {
    final func createStatusLabel(text: String) -> UILabel {
        let statusLabel = UILabel()
        statusLabel.text = text
        statusLabel.textColor = .lightGray
        statusLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        statusLabel.sizeToFit()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        return statusLabel
    }
    
    final func processDate(date: Date?) -> String? {
        guard let date = date else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let formattedDate = formatter.string(from: date)
        return formattedDate
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        let circleShapeLayerArr = meterContainer.layer.sublayers?.filter { $0.name == "circle" } as? [CAShapeLayer]
        circleShapeLayerArr?.forEach {
            $0.fillColor = UIColor.gray.cgColor;
            $0.strokeColor = UIColor.gray.cgColor
        }
        
        for i in 0..<Int(nodeCount) {
            if let statusLabel = viewWithTag(500 + i) as? UILabel {
                statusLabel.textColor = .gray
                statusLabel.text?.removeAll()
            }

            if let dateLabel = viewWithTag(600 + i) as? UILabel {
                dateLabel.textColor = .gray
                dateLabel.text?.removeAll()
            }
        }
    }
}
