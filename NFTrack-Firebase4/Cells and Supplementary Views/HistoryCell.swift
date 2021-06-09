//
//  HistoryCell.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-04.
//

import UIKit

class HistoryCell: UITableViewCell {
    var hashLabel: UILabel!
    var dateLabel: UILabel!
    var cellPosition: CellPosition!
    var strokeColor: UIColor = .black {
        didSet {
            shapeLayer.strokeColor = strokeColor.cgColor
        }
    }
    var lineWidth: CGFloat = 0.5 {
        didSet {
            updatePath()
        }
    }
    
    var cellLineView: CellLineView!
    lazy var shapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.lineWidth = lineWidth
        return shapeLayer
    }()
    
    lazy var circleShapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.lineWidth = lineWidth
        return shapeLayer
    }()
    
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

extension HistoryCell {
    func configure() {
        layer.addSublayer(shapeLayer)
        layer.addSublayer(circleShapeLayer)
        
        hashLabel = UILabel()
        hashLabel.adjustsFontForContentSizeCategory = true
        hashLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hashLabel)
        
        dateLabel = UILabel()
        dateLabel.font = UIFont.systemFont(ofSize: 15)
        dateLabel.textColor = .lightGray
        dateLabel.adjustsFontForContentSizeCategory = true
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            hashLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: self.bounds.midX / 5 + 50),
            hashLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            hashLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -10),
            hashLabel.heightAnchor.constraint(equalToConstant: 30),
            
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: self.bounds.midX / 5 + 50),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 10),
            dateLabel.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    
    func updatePath() {
        let path = UIBezierPath()
        switch cellPosition {
            case .first:
                path.move(to: CGPoint(x: self.bounds.midX / 5, y: self.bounds.midY))
                path.addLine(to: CGPoint(x: self.bounds.midX / 5, y: self.bounds.maxY))
            case .middle:
                path.move(to: CGPoint(x: self.bounds.midX / 5, y: self.bounds.maxY))
                path.addLine(to: CGPoint(x: self.bounds.midX / 5, y: self.bounds.minY))
            case .last:
                path.move(to: CGPoint(x: self.bounds.midX / 5, y: self.bounds.minY))
                path.addLine(to: CGPoint(x: self.bounds.midX / 5, y: self.bounds.midY))
            default:
                break
        }
        
        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = lineWidth
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: self.bounds.midX / 5, y: self.bounds.midY), radius: 8, startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
        circlePath.lineWidth = lineWidth
        circleShapeLayer.path = circlePath.cgPath
        circleShapeLayer.lineWidth = lineWidth
        circleShapeLayer.fillColor = UIColor.white.cgColor
    }
}

class CellLineView: UIView {
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        path.lineWidth = 1
        path.move(to: CGPoint(x: self.bounds.midX, y: self.bounds.maxY))
        path.addLine(to: CGPoint(x: self.bounds.midX, y: self.bounds.minY))
        UIColor.black.setStroke()
        path.stroke()
    }
}
