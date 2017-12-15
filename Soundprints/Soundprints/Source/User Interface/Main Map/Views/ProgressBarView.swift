//
//  ProgressBarView.swift
//  Soundprints
//
//  Created by Peter Korošec on 15. 12. 17.
//  Copyright © 2016 Kamino. All rights reserved.
//

import UIKit

class ProgressBarView: CustomView {
    
    // MARK: - Outlets

    @IBOutlet private weak var progressView: UIProgressView?
    
    // MARK: - Properties
    
    private var progressDisplayLink: CADisplayLink?
    
    private var slowAnimationTreshold: Float = 0
    private var slowerAnimationTreshold: Float = 0
    private var stopAnimationTreshold: Float = 0
    
    var progress: CGFloat {
        return CGFloat(progressView?.progress ?? 0.0)
    }
    
    // MARK: - CustomView
    
    override func setup() {
        super.setup()
        progressView?.progress = 0
    }
    
    // MARK: - Progress update
    
    @objc private func updateProgress() {
        guard let progressView = progressView else {
            return
        }
        
        if progressView.progress < slowAnimationTreshold {
            progressView.progress += 0.005
            
        } else if progressView.progress < slowerAnimationTreshold {
            progressView.progress += 0.0025
            
        } else if progressView.progress < stopAnimationTreshold {
            progressView.progress += 0.001
        }
    }
    
    // MARK: - Public methods
    
    func startProgress() {
        progressDisplayLink?.invalidate()
        progressDisplayLink = nil

        progressView?.progress = 0

        slowAnimationTreshold = Float(arc4random_uniform(3) + 3) / 10.0
        slowerAnimationTreshold = slowAnimationTreshold + Float(arc4random_uniform(2) + 1) / 10.0
        stopAnimationTreshold = 0.9
        
        progressDisplayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        progressDisplayLink?.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
    }
    
    func finishProgress(_ completion: (() -> Void)?) {
        progressDisplayLink?.invalidate()
        progressDisplayLink = nil
        
        UIView.animate(withDuration: 0.25,
                       animations: { self.progressView?.progress = 1 },
                       completion: { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.progressView?.progress = 0
                        }
        })
    }
    
    func continueProgress(_ progress: CGFloat) {
        progressDisplayLink?.invalidate()
        progressDisplayLink = nil

        progressView?.progress = Float(progress)
        
        slowAnimationTreshold = Float(arc4random_uniform(3) + 3) / 10.0
        slowerAnimationTreshold = slowAnimationTreshold + Float(arc4random_uniform(2) + 1) / 10.0
        stopAnimationTreshold = 0.9
        
        progressDisplayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        progressDisplayLink?.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
    }
    
    func cancelProgress() {
        progressDisplayLink?.invalidate()
        progressDisplayLink = nil
        progressView?.progress = 0
    }
    
}
