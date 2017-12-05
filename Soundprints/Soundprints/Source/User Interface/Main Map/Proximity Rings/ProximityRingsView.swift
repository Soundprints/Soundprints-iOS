//
//  ProximityRingsView.swift
//  Soundprints
//
//  Created by Svit Zebec on 05/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

class ProximityRingsView: UIView {
    
    var innerRingDistanceInMeters: Int = 500 {
        didSet {
            innerArcTextView?.text = "\(innerRingDistanceInMeters)m"
            middleArcTextView?.text = "\(2*innerRingDistanceInMeters)m"
        }
    }
    
    private var proximityRingOuterView: UIView?
    private var proximityRingMiddleView: UIView?
    private var proximityRingInnerView: UIView?
    
    private var innerArcTextView: CoreTextArcView?
    private var middleArcTextView: CoreTextArcView?
    
    private static let proximityRingsColor = UIColor(red: 99/255, green: 182/255, blue: 255/255, alpha: 1)
    
    init() {
        super.init(frame: .zero)
        
        initializeProximityRings()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateProximityRingsFrames()
    }
    
    private func initializeProximityRings() {
        let borderWidth: CGFloat = 0.4
        
        proximityRingOuterView = UIView()
        proximityRingOuterView?.backgroundColor = ProximityRingsView.proximityRingsColor.withAlphaComponent(0.3)
        proximityRingOuterView?.layer.borderColor = UIColor.white.cgColor
        proximityRingOuterView?.layer.borderWidth = borderWidth
        
        proximityRingMiddleView = UIView()
        proximityRingMiddleView?.backgroundColor = ProximityRingsView.proximityRingsColor.withAlphaComponent(0.3)
        proximityRingMiddleView?.layer.borderColor = UIColor.white.cgColor
        proximityRingMiddleView?.layer.borderWidth = borderWidth
        
        proximityRingInnerView = UIView()
        proximityRingInnerView?.backgroundColor = ProximityRingsView.proximityRingsColor.withAlphaComponent(1)
        proximityRingInnerView?.layer.borderColor = UIColor.white.cgColor
        proximityRingInnerView?.layer.borderWidth = borderWidth
        
        innerArcTextView = CoreTextArcView(frame: .zero)
        innerArcTextView?.font = UIFont.systemFont(ofSize: 14)
        innerArcTextView?.color = .white
        innerArcTextView?.backgroundColor = .clear
        innerArcTextView?.text = "\(innerRingDistanceInMeters)m"
        
        middleArcTextView = CoreTextArcView(frame: .zero)
        middleArcTextView?.font = UIFont.systemFont(ofSize: 14)
        middleArcTextView?.color = .white
        middleArcTextView?.backgroundColor = .clear
        middleArcTextView?.text = "\(2*innerRingDistanceInMeters)m"
        
        addSubview(proximityRingOuterView!)
        addSubview(proximityRingMiddleView!)
        addSubview(proximityRingInnerView!)
        
        addSubview(innerArcTextView!)
        addSubview(middleArcTextView!)
        
        middleArcTextView?.setNeedsDisplay()
        
        updateProximityRingsFrames()
    }
    
    private func updateProximityRingsFrames() {
        let smallerDimensionValue = bounds.width <= bounds.height ? bounds.width : bounds.height
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        let outerViewDimension: CGFloat = 1 * smallerDimensionValue
        proximityRingOuterView?.frame.size = CGSize(width: outerViewDimension, height: outerViewDimension)
        proximityRingOuterView?.center = center
        proximityRingOuterView?.layer.cornerRadius = outerViewDimension/2
        
        let middleViewDimension: CGFloat = 2/3 * smallerDimensionValue
        proximityRingMiddleView?.frame.size = CGSize(width: middleViewDimension, height: middleViewDimension)
        proximityRingMiddleView?.center = center
        proximityRingMiddleView?.layer.cornerRadius = middleViewDimension/2
        
        let innerViewDimension: CGFloat = 1/3 * smallerDimensionValue
        proximityRingInnerView?.frame.size = CGSize(width: innerViewDimension, height: innerViewDimension)
        proximityRingInnerView?.center = center
        proximityRingInnerView?.layer.cornerRadius = innerViewDimension/2
        
        let innerArcSize: CGFloat = 40
        innerArcTextView?.frame.size = CGSize(width: middleViewDimension, height: middleViewDimension)
        innerArcTextView?.center = center
        innerArcTextView?.radius = innerViewDimension/2
        innerArcTextView?.arcSize = innerArcSize
        innerArcTextView?.shiftV = innerViewDimension/4 + 2        
        innerArcTextView?.transform = CGAffineTransform(rotationAngle: -.pi/2)
        
        middleArcTextView?.frame.size = CGSize(width: outerViewDimension, height: outerViewDimension)
        middleArcTextView?.center = center
        middleArcTextView?.radius = middleViewDimension/2
        middleArcTextView?.arcSize = (innerArcSize/2) * 1.25
        middleArcTextView?.shiftV = middleViewDimension/4 + 2        
        middleArcTextView?.transform = CGAffineTransform(rotationAngle: -.pi/2)
    } 
    
}
