//
//  ListenView.swift
//  Soundprints
//
//  Created by Svit Zebec on 11/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation

// MARK: - ListenViewDelegate

protocol ListenViewDelegate: class {
    
    func listenViewShouldClose(sender: ListenView)
    
}

// MARK: - ListeView

class ListenView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: ListenViewDelegate?
    
    /// Progress from 0 to 1
    var progress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    var progressColor: UIColor = .white {
        didSet {
            setNeedsDisplay()
        }
    }
    var progressLineWidth: CGFloat = 4 {
        didSet {
            setNeedsDisplay()
            layoutSubviews()
        }
    }
    
    var profileImageView: UIImageView?
    private var closeButtonImageView: UIImageView?
    private var closeButton: UIButton?
    
    private var progressBezierPath: UIBezierPath?
    
    private var progressToUse: CGFloat {
        return max(0.0, min(progress, 1.0))
    }
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    // MARK: - View lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateListenViewFrames()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = bounds.height/2 - progressLineWidth/2
        let startAngle: CGFloat = -.pi/2
        let endAngle: CGFloat = progressToUse*2*CGFloat.pi - .pi/2
        
        let progressBezierPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        progressBezierPath.lineWidth = progressLineWidth
        progressColor.setStroke()
        progressBezierPath.stroke()
    }
    
    // MARK: - Initialization
    
    private func commonInit() {
        clipsToBounds = false
        backgroundColor = .clear
        
        profileImageView = UIImageView()
        profileImageView?.clipsToBounds = true
        
        closeButtonImageView = UIImageView(image: R.image.listenCloseButtonIcon())
        
        closeButton = UIButton()
        closeButton?.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        
        addSubview(profileImageView!)
        addSubview(closeButtonImageView!)
        addSubview(closeButton!)
    }
    
    // MARK: - Frames updating
    
    private func updateListenViewFrames() {
        if let profileImageView = profileImageView {
            let profileImageViewInset = progressLineWidth
            profileImageView.frame = bounds.insetBy(dx: profileImageViewInset, dy: profileImageViewInset)
            profileImageView.layer.cornerRadius = profileImageView.bounds.height/2
        }
        
        closeButtonImageView?.frame.size = CGSize(width: bounds.width/2, height: bounds.height/2)
        closeButtonImageView?.center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        closeButton?.frame = bounds
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonPressed() {
        delegate?.listenViewShouldClose(sender: self)
    }
    
}
