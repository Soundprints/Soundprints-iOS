//
//  RecordButtonView.swift
//  Soundprints
//
//  Created by Peter Korosec on 15/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

protocol RecordButtonViewDelegate: class {
    func recordButtonViewChangedState(sender: RecordButtonView, recording: Bool)
}

class RecordButtonView: UIView {

    // MARK: - Properties
    
    weak var delegate: RecordButtonViewDelegate?
    
    private(set) var recording: Bool = false
    
    var recordingColor: UIColor = .red
    var defaultColor: UIColor = .blue
    var trailColor: UIColor = .white
    
    var animationDuration: TimeInterval = 1.2
    
    private var trailLifeSpan: TimeInterval {
        return animationDuration/3
    }
    
    private var boundsCenter: CGPoint {
        return CGPoint(x: bounds.width/2, y: bounds.height/2)
    }
    
    private var maxRadius: CGFloat {
        return min(bounds.width, bounds.height)/2.0 - 1.0
    }
    
    var startAngle: CGFloat = 0.0
    
    var endAngle: CGFloat {
        return startAngle + CGFloat.pi*2
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        //backgroundColor = .clear
        
        let imageView = UIImageView(image: #imageLiteral(resourceName: "record-button-icon"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        let multiplier: CGFloat = 0.5
        imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: multiplier).isActive = true
        imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: multiplier).isActive = true
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.addGestureRecognizer(recognizer)
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setNeedsDisplay()
    }
    
    // MARK: - Trail
    
    private var dotAnimator: ValueAnimator?
    private var trailPoints: [TrailPoint] = []
    
    private var displayLink: CADisplayLink?
    
    private func startDisplayLink() {
        stopDisplayLink()
        displayLink = CADisplayLink(target: self, selector: #selector(onDisplayLink))
        displayLink?.add(to: .main, forMode: .commonModes)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func onDisplayLink() {
        guard trailPoints.count > 0 else {
            stopDisplayLink()
            trailPoints = []
            return
        }
        setNeedsDisplay()
    }
    
    // MARK: - Drawing
    
    private func drawTrail() {
//        trailPoints = trailPoints.filter { $0.hasExpired == false }
//        var previousPoint: TrailPoint?
//        trailPoints.forEach { point in
//            guard !point.hasExpired else {
//                return
//            }
//
//            if let previous = previousPoint, locked ? previous.angle < point.angle : previous.angle > point.angle {
//                let path = UIBezierPath()
//                path.addArc(withCenter: boundsCenter,
//                            radius: dotPathRadius,
//                            startAngle: previous.angle,
//                            endAngle: point.angle,
//                            clockwise: locked)
//                path.lineWidth = 3.0
//
//                // get correct color from the dots presentation layer
//                dot.color.withAlphaComponent(point.intensity).setStroke()
//
//                path.stroke()
//            }
//
//            previousPoint = point
//        }
    }
    
    private func addTrailPoint() {
        let point = TrailPoint(angle: dotAnimator?.currentValue ?? 0.0, lifeSpan: trailLifeSpan)
        trailPoints.append(point)
    }
    
    override func draw(_ rect: CGRect) {
//        // draw circle
        let rect = CGRect(x: boundsCenter.x-maxRadius, y: boundsCenter.y-maxRadius, width: maxRadius*2, height: maxRadius*2)
        let path = UIBezierPath(ovalIn: rect)
        recording ? recordingColor.setFill() : defaultColor.setFill()
        path.fill()

        // place dot
        //dot.position = pointOnCircleWith(radius: dotPathRadius, center: boundsCenter, atAngle: dotAnimator?.currentValue ?? startAngle)

        drawTrail()
    }
    
    // MARK: - Actions
    
    @objc private func onTap() {
        setRecording(!recording)
    }
    
    // MARK: - Recording
    
    func setRecording(_ recording: Bool, animated: Bool = true) {
        self.recording = recording
        setNeedsDisplay()
        delegate?.recordButtonViewChangedState(sender: self, recording: recording)
    }
    
    // MARK: - Helpers
    
    private func pointOnCircleWith(radius: CGFloat, center: CGPoint, atAngle angle: CGFloat) -> CGPoint {
        return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }

}

// MARK: - Dot

private extension RecordButtonView {
    
    class Dot {
        
        // MARK: - Properties
        
        var position: CGPoint {
            get {
                return shape.position
            }
            set {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                shape.position = newValue
                CATransaction.commit()
            }
        }
        
        var color: UIColor {
            get {
                return UIColor(cgColor: topLayer.fillColor ?? UIColor.white.cgColor)
            }
            set {
                set(color: newValue)
            }
        }
        
        var shadowHidden: Bool = false {
            didSet {
                shape.shadowOpacity = shadowHidden ? 0.0 : 1.0
            }
        }
        
        // MARK: - Layers
        
        private let shape: CAShapeLayer
        private let middleLayer: CAShapeLayer
        private let topLayer: CAShapeLayer
        
        // MARK: - Init
        
        init(radius: CGFloat, dotColor: UIColor, view: UIView) {
            let dotLayer = CAShapeLayer()
            dotLayer.path = Dot.pathFor(size: radius*2)
            
            dotLayer.shadowOffset = CGSize.zero
            dotLayer.shadowRadius = radius*2.5
            dotLayer.shadowOpacity = 1.0
            dotLayer.shadowPath = Dot.pathFor(size: radius*2.5)
            
            middleLayer = CAShapeLayer()
            middleLayer.path = Dot.pathFor(size: radius*1.2)
            dotLayer.addSublayer(middleLayer)
            
            topLayer = CAShapeLayer()
            topLayer.path = Dot.pathFor(size: radius*0.6)
            dotLayer.addSublayer(topLayer)
            
            shape = dotLayer
            self.color = dotColor
            
            view.layer.addSublayer(shape)
        }
        
        // MARK: - Animation
        
        private func set(color: UIColor) {
            shape.fillColor = color.withAlphaComponent(0.25).cgColor
            shape.shadowColor = color.cgColor
            middleLayer.fillColor = color.withAlphaComponent(0.5).cgColor
            topLayer.fillColor = color.cgColor
        }
        
        func animateColor(to color: UIColor, duration: CFTimeInterval) {
            let shadowColorPath = "shadowColor"
            
            animateFillColor(layer: shape, color: color.withAlphaComponent(0.25), duration: duration)
            animateFillColor(layer: middleLayer, color: color.withAlphaComponent(0.5), duration: duration)
            animateFillColor(layer: topLayer, color: color, duration: duration)
            
            let shadowAnimation = CABasicAnimation(keyPath: shadowColorPath)
            shadowAnimation.fromValue = shape.shadowColor
            shadowAnimation.toValue = color.cgColor
            shadowAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            shadowAnimation.duration = duration
            
            shape.shadowColor = color.cgColor
            shape.add(shadowAnimation, forKey: shadowColorPath)
        }
        
        // MARK: - Helpers
        
        private static func pathFor(size: CGFloat) -> CGPath {
            let rect = CGRect(x: -size/2, y: -size/2, width: size, height: size)
            return UIBezierPath(ovalIn: rect).cgPath
        }
        
        private func animateFillColor(layer: CAShapeLayer, color: UIColor, duration: CFTimeInterval) {
            let fillColorPath = "fillColor"
            
            let animation = CABasicAnimation(keyPath: fillColorPath)
            animation.isRemovedOnCompletion = false
            animation.fromValue = layer.fillColor
            animation.toValue = color.cgColor
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            animation.duration = duration
            
            layer.fillColor = color.cgColor
            layer.add(animation, forKey: fillColorPath)
        }
        
        func removeFromView() {
            shape.removeFromSuperlayer()
        }
    }
    
}

// MARK: - TrailPoint

private extension RecordButtonView {
    
    class TrailPoint {
        
        // MARK: - Properties
        
        private(set) var angle: CGFloat
        private let lifeSpan: TimeInterval
        private let creationDate: Date
        
        // MARK: - Init
        
        init(angle: CGFloat, lifeSpan: TimeInterval) {
            self.angle = angle
            self.lifeSpan = lifeSpan
            self.creationDate = Date()
        }
        
        // MARK: - Age
        
        var hasExpired: Bool {
            return age > lifeSpan
        }
        
        private var age: TimeInterval {
            return Date().timeIntervalSince(creationDate)
        }
        
        // MARK: - Alpha
        
        var intensity: CGFloat {
            return 1.0 - CGFloat(age/lifeSpan)
        }
    }
    
}
