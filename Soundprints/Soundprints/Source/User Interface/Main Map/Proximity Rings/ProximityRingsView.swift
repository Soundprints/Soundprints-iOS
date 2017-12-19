//
//  ProximityRingsView.swift
//  Soundprints
//
//  Created by Svit Zebec on 05/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

class ProximityRingsView: UIView {
    
    // MARK: - Properties
    
    var innerRingDistanceInMeters: Int = 500 {
        didSet {
            innerArcTextView?.text = innerArcText
            middleArcTextView?.text = middleArcText
        }
    }
    
    private var innerArcText: String {
        return "\(innerRingDistanceInMeters)m"
    }
    private var middleArcText: String {
        return "\(2*innerRingDistanceInMeters)m"
    }
    
    private var proximityRingOuterView: UIView?
    private var proximityRingMiddleView: UIView?
    private var proximityRingInnerView: UIView?
    
    private var innerArcTextView: CoreTextArcView?
    private var middleArcTextView: CoreTextArcView?
    
    // MARK: - Constants
    
    private static let proximityRingsColor = ColorPalette.mainMap.proximityRings.blue
    
    // MARK: - Initializers
    
    convenience init() {
        self.init(frame: .zero)
        
        initializeProximityRings()
    }
    
    // MARK: - View lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateProximityRingsFrames()
    }
    
    // MARK: - Initialization
    
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
        innerArcTextView?.text = innerArcText
        
        middleArcTextView = CoreTextArcView(frame: .zero)
        middleArcTextView?.font = UIFont.systemFont(ofSize: 14)
        middleArcTextView?.color = .white
        middleArcTextView?.backgroundColor = .clear
        middleArcTextView?.text = middleArcText
        
        addSubview(proximityRingOuterView!)
        addSubview(proximityRingMiddleView!)
        addSubview(proximityRingInnerView!)
        
        addSubview(innerArcTextView!)
        addSubview(middleArcTextView!)
        
        updateProximityRingsFrames()
    }
    
    // MARK: - Frames updating
    
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
        
        // The arc text views are positioned in the following way:
        // - frame: Simply take the frame of the bigger ring so we have enough space
        // - center: Center of the superview
        // - radius: Half of the ring (coincident to the arc text view) size
        // - arcSize: Inner arc size is arbitrarily set and the middle arc size is computed as (innerArcSize/2) * (middleText.length/innerText.length)
        // - shiftV: It turns out that the text is not properly positioned without the vertical shift, so we have to shift it for half of the radius
        // - transform: Since the angle of where in the circle should the text be displayed can't be set, we simply apply a rotating transform for -PI/2 
        
        let innerArcSize: CGFloat = 40
        let arcTextOffsetFromRing: CGFloat = 2
        
        innerArcTextView?.frame.size = CGSize(width: middleViewDimension, height: middleViewDimension)
        innerArcTextView?.center = center
        innerArcTextView?.radius = innerViewDimension/2
        innerArcTextView?.arcSize = innerArcSize
        innerArcTextView?.shiftV = innerViewDimension/4 + arcTextOffsetFromRing        
        innerArcTextView?.transform = CGAffineTransform(rotationAngle: -.pi/2)
        
        middleArcTextView?.frame.size = CGSize(width: outerViewDimension, height: outerViewDimension)
        middleArcTextView?.center = center
        middleArcTextView?.radius = middleViewDimension/2
        middleArcTextView?.arcSize = (innerArcSize/2) * (CGFloat(middleArcText.count)/CGFloat(innerArcText.count))
        middleArcTextView?.shiftV = middleViewDimension/4 + arcTextOffsetFromRing
        middleArcTextView?.transform = CGAffineTransform(rotationAngle: -.pi/2)
    } 
    
}
