//
//  ProgressCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-06.
//

import UIKit

class ProgressCell: UITableViewCell {
    let selectedColor = UIColor(red: 61/255, green: 156/255, blue: 133/255, alpha: 1)
    let containerView = UIView()
    let titleLabel = UILabel()
    let INSET: CGFloat = 60
    var strokeColor: UIColor = .gray {
        didSet {
            shapeLayer.strokeColor = strokeColor.cgColor
        }
    }
    var lineWidth: CGFloat = 0.5 {
        didSet {
            updatePath()
        }
    }
    
    lazy var shapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.lineWidth = lineWidth
        return shapeLayer
    }()
    
    lazy var circleShapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.lineWidth = lineWidth
        return shapeLayer
    }()
    
    lazy var circleShapeLayer2: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.lineWidth = lineWidth
        return shapeLayer
    }()
    
    lazy var circleShapeLayer3: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.lineWidth = lineWidth
        return shapeLayer
    }()
    
    var statusLabel1: UILabel!
    var dateLabel1: UILabel!
    var statusLabel2: UILabel!
    var dateLabel2: UILabel!
    var statusLabel3: UILabel!
    var dateLabel3: UILabel!
    var mandateLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePath()
    }
}

extension ProgressCell {
    func configure() {
        containerView.dropShadow()
        contentView.addSubview(containerView)
        containerView.fill(inset: 20)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.sizeToFit()
        titleLabel.font = .rounded(ofSize: titleLabel.font.pointSize, weight: .bold)
        titleLabel.textColor = .lightGray
        containerView.addSubview(titleLabel)
        
        layer.addSublayer(shapeLayer)
        layer.addSublayer(circleShapeLayer)
        layer.addSublayer(circleShapeLayer2)
        layer.addSublayer(circleShapeLayer3)
        
        statusLabel1 = createStatusLabel(text: "Purchased")
        contentView.addSubview(statusLabel1)
        
        dateLabel1 = createStatusLabel(text: "")
        contentView.addSubview(dateLabel1)
        
        statusLabel2 = createStatusLabel(text: "Transferred")
        contentView.addSubview(statusLabel2)
        
        dateLabel2 = createStatusLabel(text: "")
        contentView.addSubview(dateLabel2)
        
        statusLabel3 = createStatusLabel(text: "Received")
        contentView.addSubview(statusLabel3)
        
        dateLabel3 = createStatusLabel(text: "")
        contentView.addSubview(dateLabel3)
        
//        mandateLabel = createStatusLabel(text: "Status")
    }
    
    func createStatusLabel(text: String) -> UILabel {
        let statusLabel = UILabel()
        statusLabel.text = text
        statusLabel.textColor = .lightGray
        statusLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        statusLabel.sizeToFit()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        return statusLabel
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
            
            statusLabel1.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            statusLabel1.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 10),
            
            dateLabel1.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            dateLabel1.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 30),
            
            statusLabel2.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            statusLabel2.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 10),
            
            dateLabel2.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: 20),
            dateLabel2.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 30),
            
            statusLabel3.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            statusLabel3.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 10),
            
            dateLabel3.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 20),
            dateLabel3.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 30),
        ])
    }
    
    func processDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let formattedDate = formatter.string(from: date)
        return formattedDate
    }
    
    func set(post: Post) {
        titleLabel.text = post.title
                
        switch post.status {
            case PostStatus.ready.rawValue:
                break
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
                break
        }
    }
    
    // MARK: - updatePath
    func updatePath() {
        let offset: CGFloat = -20
        let path = UIBezierPath()
        path.move(to: CGPoint(x: contentView.bounds.minX + INSET, y: contentView.bounds.midY + offset))
        path.addLine(to: CGPoint(x: contentView.bounds.maxX - INSET, y: contentView.bounds.midY + offset))
        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = lineWidth
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: contentView.bounds.minX + INSET, y: contentView.bounds.midY + offset), radius: 8, startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
        circlePath.lineWidth = lineWidth
        circleShapeLayer.path = circlePath.cgPath
        circleShapeLayer.lineWidth = lineWidth
        
        let circlePath2 = UIBezierPath(arcCenter: CGPoint(x: contentView.bounds.midX, y: contentView.bounds.midY + offset), radius: 8, startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
        circlePath.lineWidth = lineWidth
        circleShapeLayer2.path = circlePath2.cgPath
        circleShapeLayer2.lineWidth = lineWidth
        
        let circlePath3 = UIBezierPath(arcCenter: CGPoint(x: contentView.bounds.maxX - INSET, y: contentView.bounds.midY + offset), radius: 8, startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
        circlePath.lineWidth = lineWidth
        circleShapeLayer3.path = circlePath3.cgPath
        circleShapeLayer3.lineWidth = lineWidth
    }
}
