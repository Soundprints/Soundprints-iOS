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
    
    // TODO: in progress...

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
        backgroundColor = .clear
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.addGestureRecognizer(recognizer)
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setNeedsDisplay()
    }
    
    // MARK: - Circle
    
    private var circleAnimator: ValueAnimator?
    
    // TODO:
    
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
            return
        }
        setNeedsDisplay()
    }
    
    // MARK: - Drawing
    
    private func drawTrail() {
        guard recording else {
            return
        }
        
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
                path.lineWidth = 3.0

                trailColor.setStroke()
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
        // TODO: draw circle
        drawTrail()
    }
    
    // MARK: - Actions
    
    @objc private func onTap() {
        setRecording(!recording)
    }
    
    // MARK: - Recording
    
    func setRecording(_ recording: Bool, animated: Bool = false) {
        self.recording = recording
        
        if animated == false {
            setNeedsDisplay()
            return
        }
        
        // TODO: animation
    }
    
    // MARK: - Helpers
    
    private func pointOnCircleWith(radius: CGFloat, center: CGPoint, atAngle angle: CGFloat) -> CGPoint {
        return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
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
