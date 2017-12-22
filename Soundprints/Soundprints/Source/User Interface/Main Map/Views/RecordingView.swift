//
//  RecordingView.swift
//  Soundprints
//
//  Created by Svit Zebec on 22/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation

class RecordingView: UIView {
    
    // MARK: - Properties
    
    private var maxRadius: CGFloat = 0
    private var boundsCenter: CGPoint = .zero
    
    private var trailLifeSpan: TimeInterval {
        return animationDuration/3
    }
    
    private var circlingAnimationActive: Bool = false
    
    private var endAngle: CGFloat {
        return startAngle + CGFloat.pi*2
    }
    
    // MARK: - Constants
    
    private let startAngle: CGFloat = -.pi/2
    private let animationDuration: TimeInterval = 1
    
    private let strokeWidth: CGFloat = 5
    private let strokeColor: UIColor = .white
    
    // MARK: - UIView lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        maxRadius = min(bounds.width, bounds.height)/2.0 - strokeWidth/2
        boundsCenter = CGPoint(x: bounds.width/2, y: bounds.height/2)
    }
    
    // MARK: - Trail
    
    private var trailAnimator: ValueAnimator?
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
            
            if circlingAnimationActive {
                startCirclingAnimation()
            }
            
            return
        }
        setNeedsDisplay()
    }
    
    // MARK: - Drawing
    
    private func drawTrail() {
        trailPoints = trailPoints.filter { $0.hasExpired == false }
        var previousPoint: TrailPoint?
        trailPoints.forEach { point in
            guard !point.hasExpired else {
                return
            }
            
            if let previous = previousPoint, previous.angle < point.angle {
                let path = UIBezierPath()
                path.addArc(withCenter: boundsCenter,
                            radius: maxRadius,
                            startAngle: previous.angle,
                            endAngle: point.angle,
                            clockwise: true)
                path.lineWidth = strokeWidth
                
                // get correct color from the dots presentation layer
                strokeColor.withAlphaComponent(point.intensity).setStroke()
                
                
                path.stroke()
            }
            
            previousPoint = point
        }
    }
    
    private func addTrailPoint() {
        let point = TrailPoint(angle: trailAnimator?.currentValue ?? 0.0, lifeSpan: trailLifeSpan)
        trailPoints.append(point)
    }
    
    override func draw(_ rect: CGRect) {
        
        // place dot
        if circlingAnimationActive {
            let center = pointOnCircleWith(radius: maxRadius, center: self.boundsCenter, atAngle: trailAnimator?.currentValue ?? startAngle)
            let path = UIBezierPath(arcCenter: center, radius: strokeWidth/2, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            strokeColor.setFill()
            path.fill()
            
            drawTrail()
        }
    }
    
    // MARK: - State
    
    func setState(_ state: State) {
        // TODO: Set images etc.
        
        switch state {
        case .notRecording:
            stopCirclingAnimation()
        case .recording:
            startCirclingAnimation()
        }
    }
    
    // MARK: - Loading Animation
    
    func startCirclingAnimation() {
        circlingAnimationActive = true
        
        trailAnimator = ValueAnimator(startValue: startAngle)
        trailAnimator?.animate(to: endAngle, duration: animationDuration, interpolation: .easeInOut(strength: 1.0)) { (_, finished) in
            self.addTrailPoint()
            self.setNeedsDisplay()
            if finished {
                self.startDisplayLink()
            }
        }
    }
    
    func stopCirclingAnimation() {
        circlingAnimationActive = false
    }
    
    // MARK: - Helpers
    
    private func pointOnCircleWith(radius: CGFloat, center: CGPoint, atAngle angle: CGFloat) -> CGPoint {
        return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }
    
    private func pathFor(size: CGFloat) -> CGPath {
        let rect = CGRect(x: -size/2, y: -size/2, width: size, height: size)
        return UIBezierPath(ovalIn: rect).cgPath
    }
    
}

// MARK: - State

extension RecordingView {
    
    enum State {
        case notRecording
        case recording
    }
    
}

// MARK: - TrailPoint

private extension RecordingView {
    
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

