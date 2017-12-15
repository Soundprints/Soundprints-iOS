//
//  ValueAnimator.swift
//
//  Created by Matic Oblak on 3/3/17.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

class ValueAnimator {
    
    enum Interpolation {
        case linear, easeIn, easeOut, exponential(value: CGFloat), easeInOut(strength: CGFloat)
    }
    
    private static var displayLink: CADisplayLink?
    private static var animatables: [ValueAnimator] = [ValueAnimator]() {
        didSet {
            if animatables.count > 0 {
                if displayLink == nil {
                    displayLink = CADisplayLink(target: self, selector: #selector(onDisplayLink))
                    displayLink?.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
                }
            } else {
                displayLink?.invalidate()
                displayLink = nil
            }
        }
    }
    
    private var startDate: Date = Date()
    private var endDate: Date = Date()
    private var startValue: CGFloat = 0.0
    private var endValue: CGFloat = 0.0
    
    private var interpolation: Interpolation = .linear
    
    private var callbackBlock: ((_ newValue: CGFloat, _ isFinished: Bool) -> Void)?
    
    convenience init(startValue: CGFloat) {
        self.init()
        self.startValue = startValue
        self.endValue = startValue
    }
    
    var currentValue: CGFloat {
        let duration = endDate.timeIntervalSince(startDate)
        guard duration > 0.01 else {
            return endValue
        }
        
        let elapsedTime = Date().timeIntervalSince(startDate)
        
        let animationProgress = CGFloat(elapsedTime/duration)
        
        let scale: CGFloat = {
            
            
            switch interpolation {
            case .linear: return animationProgress
            case .easeIn: return pow(animationProgress, 1.2)
            case .easeOut: return pow(animationProgress, 1 / 1.2)
            case .exponential(let value): return pow(animationProgress, value)
            case .easeInOut(let strength): return animationProgress + ((sin(animationProgress*CGFloat.pi - CGFloat.pi/2) + 1)/2 - animationProgress)*strength
            }
        }()
        
        if animationProgress >= 1.0 {
            startValue = endValue
            return endValue
        } else {
            return startValue + (endValue - startValue)*scale
        }
    }
    
    func invalidate() {
        
        ValueAnimator.removeAnimator(animator: self)
        self.callbackBlock = nil
        self.startDate = Date()
        self.endDate = Date()
        self.startValue = self.currentValue
        self.endValue = self.startValue
        
    }
    
    func set(to value: CGFloat) {
        ValueAnimator.removeAnimator(animator: self)
        startValue = value
        endValue = value
    }
    
    func animate(to value: CGFloat, duration: TimeInterval, interpolation: Interpolation = Interpolation.linear, onFrame: @escaping ((_ newValue: CGFloat, _ isFinished: Bool) -> Void)) {
        
        self.callbackBlock = onFrame
        self.interpolation = interpolation
        
        startValue = currentValue
        endValue = value
        
        startDate = Date()
        endDate = Date().addingTimeInterval(duration)
        
        ValueAnimator.addAnimator(animator: self)
    }
    
    private static func removeAnimator(animator: ValueAnimator) {
        animator.callbackBlock = nil
        self.animatables = self.animatables.filter { $0 !== animator }
    }
    
    private static func addAnimator(animator: ValueAnimator) {
        self.animatables.append(animator)
    }
    
    @objc private static func onDisplayLink() {
        animatables.forEach { item in
            let isDone = item.endDate <= Date()
            let value = item.currentValue
            let block = item.callbackBlock
            if isDone {
                ValueAnimator.removeAnimator(animator: item)
                item.callbackBlock = nil
            }
            block?(value, isDone)
            
        }
    }
}
