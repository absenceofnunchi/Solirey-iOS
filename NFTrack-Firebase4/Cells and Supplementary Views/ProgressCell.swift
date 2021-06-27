//
//  ProgressCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-06.
//

import UIKit

class ProgressCell: CardCell {
    class override var identifier: String {
        return "ProgressCell"
    }
    final let selectedColor = UIColor(red: 61/255, green: 156/255, blue: 133/255, alpha: 1)

    final let INSET: CGFloat = 45
    final var strokeColor: UIColor = .gray {
        didSet {
            shapeLayer.strokeColor = strokeColor.cgColor
        }
    }
    final var lineWidth: CGFloat = 0.5 {
        didSet {
            updatePath()
        }
    }
    
    final lazy var shapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.lineWidth = lineWidth
        return shapeLayer
    }()
    
    final lazy var circleShapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.lineWidth = lineWidth
        return shapeLayer
    }()
    
    final lazy var circleShapeLayer2: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.lineWidth = lineWidth
        return shapeLayer
    }()
    
    final lazy var circleShapeLayer3: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.lineWidth = lineWidth
        return shapeLayer
    }()
    
    final var statusLabel1: UILabel!
    final var dateLabel1: UILabel!
    final var statusLabel2: UILabel!
    final var dateLabel2: UILabel!
    final var statusLabel3: UILabel!
    final var dateLabel3: UILabel!
    final var indicatorPanel: UIView!
    final var meterContainer: UIView!

    override func configure(_ post: Post?) {
        super.configure(post)
        guard let post = post else { return }

        meterContainer = UIView()
        meterContainer.layer.addSublayer(shapeLayer)
        meterContainer.layer.addSublayer(circleShapeLayer)
        meterContainer.layer.addSublayer(circleShapeLayer2)
        meterContainer.layer.addSublayer(circleShapeLayer3)
        meterContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(meterContainer)

        statusLabel1 = createStatusLabel(text: "Purchased")
        statusLabel1.textAlignment = .center
        meterContainer.addSubview(statusLabel1)
        
        dateLabel1 = createStatusLabel(text: "")
        dateLabel1.textAlignment = .center
        meterContainer.addSubview(dateLabel1)
        
        statusLabel2 = createStatusLabel(text: "Transferred")
        statusLabel2.textAlignment = .center
        meterContainer.addSubview(statusLabel2)
        
        dateLabel2 = createStatusLabel(text: "")
        dateLabel2.textAlignment = .center
        meterContainer.addSubview(dateLabel2)
        
        statusLabel3 = createStatusLabel(text: "Received")
        statusLabel3.textAlignment = .center
        meterContainer.addSubview(statusLabel3)
        
        dateLabel3 = createStatusLabel(text: "")
        dateLabel3.textAlignment = .center
        meterContainer.addSubview(dateLabel3)

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
            meterContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 5),
            meterContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -5),
            meterContainer.heightAnchor.constraint(equalToConstant: 100),
            
            dateLabel1.leadingAnchor.constraint(equalTo: meterContainer.leadingAnchor, constant: 20),
            dateLabel1.bottomAnchor.constraint(equalTo: meterContainer.bottomAnchor, constant: 5),
            dateLabel1.heightAnchor.constraint(equalToConstant: 30),
            
            statusLabel1.leadingAnchor.constraint(equalTo: meterContainer.leadingAnchor, constant: 20),
            statusLabel1.bottomAnchor.constraint(equalTo: dateLabel1.topAnchor, constant: 0),
            
            dateLabel2.centerXAnchor.constraint(equalTo: meterContainer.centerXAnchor, constant: 20),
            dateLabel2.bottomAnchor.constraint(equalTo: meterContainer.bottomAnchor, constant: 5),
            dateLabel2.heightAnchor.constraint(equalToConstant: 30),
            
            statusLabel2.centerXAnchor.constraint(equalTo: meterContainer.centerXAnchor),
            statusLabel2.bottomAnchor.constraint(equalTo: dateLabel2.topAnchor, constant: -0),
            
            dateLabel3.trailingAnchor.constraint(equalTo: meterContainer.trailingAnchor, constant: 20),
            dateLabel3.bottomAnchor.constraint(equalTo: meterContainer.bottomAnchor, constant: 5),
            dateLabel3.heightAnchor.constraint(equalToConstant: 30),
            
            statusLabel3.trailingAnchor.constraint(equalTo: meterContainer.trailingAnchor, constant: -20),
            statusLabel3.bottomAnchor.constraint(equalTo: dateLabel3.topAnchor, constant: 0),
        ]
        
        NSLayoutConstraint.activate(progressConstraints)
        meterContainer.layoutIfNeeded()
        dateLabel1.layoutIfNeeded()
        statusLabel1.layoutIfNeeded()
        updatePath()
        set(post: post)
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
    
    final func processDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let formattedDate = formatter.string(from: date)
        return formattedDate
    }
    
    final func set(post: Post) {                
        switch post.status {
            case PostStatus.ready.rawValue:
                circleShapeLayer.fillColor = UIColor.white.cgColor
                circleShapeLayer.strokeColor = UIColor.lightGray.cgColor
                statusLabel1.textColor = .lightGray
                
                dateLabel1.text = ""
                dateLabel1.textColor = .lightGray
            case PostStatus.pending.rawValue:
                circleShapeLayer.fillColor = selectedColor.cgColor
                circleShapeLayer.strokeColor = selectedColor.cgColor
                statusLabel1.textColor = selectedColor
                
                dateLabel1.text = processDate(date: post.confirmPurchaseDate!)
                dateLabel1.textColor = selectedColor
            case PostStatus.transferred.rawValue:
                circleShapeLayer.fillColor = selectedColor.cgColor
                circleShapeLayer.strokeColor = selectedColor.cgColor
                statusLabel1.textColor = selectedColor
                
                dateLabel1.text = processDate(date: post.confirmPurchaseDate!)
                dateLabel1.textColor = selectedColor
                
                circleShapeLayer2.fillColor = selectedColor.cgColor
                circleShapeLayer2.strokeColor = selectedColor.cgColor
                statusLabel2.textColor = selectedColor
                
                dateLabel1.text = processDate(date: post.transferDate!)
                dateLabel1.textColor = selectedColor
            case PostStatus.complete.rawValue:
                circleShapeLayer.fillColor = selectedColor.cgColor
                circleShapeLayer.strokeColor = selectedColor.cgColor
                statusLabel1.textColor = selectedColor
                
                dateLabel1.text = processDate(date: post.confirmPurchaseDate!)
                dateLabel1.textColor = selectedColor
                
                circleShapeLayer2.fillColor = selectedColor.cgColor
                circleShapeLayer2.strokeColor = selectedColor.cgColor
                statusLabel2.textColor = selectedColor
                
                dateLabel1.text = processDate(date: post.transferDate!)
                dateLabel1.textColor = selectedColor
                
                circleShapeLayer3.fillColor = selectedColor.cgColor
                circleShapeLayer3.strokeColor = selectedColor.cgColor
                statusLabel3.textColor = selectedColor
                
                dateLabel1.text = processDate(date: post.confirmReceivedDate!)
                dateLabel1.textColor = selectedColor
            default:
                circleShapeLayer.fillColor = UIColor.white.cgColor
                circleShapeLayer.strokeColor = UIColor.lightGray.cgColor
                statusLabel1.textColor = .lightGray
                
                dateLabel1.text = ""
                dateLabel1.textColor = .lightGray
        }
    }
    
    // MARK: - updatePath
    final func updatePath() {
        let offset: CGFloat = -20
        let path = UIBezierPath()
        path.move(to: CGPoint(x: meterContainer.bounds.minX + INSET, y: meterContainer.bounds.midY + offset))
        path.addLine(to: CGPoint(x: meterContainer.bounds.maxX - INSET, y: meterContainer.bounds.midY + offset))
        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = lineWidth
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: meterContainer.bounds.minX + INSET, y: meterContainer.bounds.midY + offset), radius: 8, startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
        circlePath.lineWidth = lineWidth
        circleShapeLayer.path = circlePath.cgPath
        circleShapeLayer.lineWidth = lineWidth
        
        let circlePath2 = UIBezierPath(arcCenter: CGPoint(x: meterContainer.bounds.midX, y: meterContainer.bounds.midY + offset), radius: 8, startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
        circlePath.lineWidth = lineWidth
        circleShapeLayer2.path = circlePath2.cgPath
        circleShapeLayer2.lineWidth = lineWidth
        
        let circlePath3 = UIBezierPath(arcCenter: CGPoint(x: meterContainer.bounds.maxX - INSET, y: meterContainer.bounds.midY + offset), radius: 8, startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
        circlePath.lineWidth = lineWidth
        circleShapeLayer3.path = circlePath3.cgPath
        circleShapeLayer3.lineWidth = lineWidth
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        circleShapeLayer.fillColor = UIColor.white.cgColor
        circleShapeLayer.strokeColor = UIColor.lightGray.cgColor
        statusLabel1.textColor = .lightGray
        
        dateLabel1.text = ""
        dateLabel1.textColor = .lightGray
        
        circleShapeLayer2.fillColor = UIColor.white.cgColor
        circleShapeLayer2.strokeColor = UIColor.lightGray.cgColor
        statusLabel2.textColor = selectedColor
        
        dateLabel1.text = ""
        dateLabel1.textColor = selectedColor
        
        circleShapeLayer3.fillColor = UIColor.white.cgColor
        circleShapeLayer3.strokeColor = UIColor.lightGray.cgColor
        statusLabel3.textColor = selectedColor
        
        dateLabel1.text = ""
        dateLabel1.textColor = selectedColor
    }
}
