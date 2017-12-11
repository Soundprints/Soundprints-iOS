//
//  SoundAnnotationView.swift
//  Soundprints
//
//  Created by Svit Zebec on 05/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit
import Mapbox

class SoundAnnotationView: MGLAnnotationView {
    
    // MARK: - Variables
    
    var backgroundImageView: UIImageView?
    var profileImageView: UIImageView?
    var playButtonImageView: UIImageView?
    var distanceLabel: UILabel?
    
    var profileImage: UIImage? {
        didSet {
            profileImageView?.image = profileImage
        }
    }
    
    var distanceString: String = "" {
        didSet {
            distanceLabel?.text = distanceString
        }
    }
    
    var state: State = .notInRange {
        didSet {
            updateContent(withState: state)
        }
    }
    
    // MARK: - Initializers
    
    convenience init(reuseIdentifier: String?, frame: CGRect) {
        self.init(reuseIdentifier: reuseIdentifier)
        
        let bounds = CGRect(origin: .zero, size: frame.size)
        
        self.frame = frame
        backgroundColor = .clear
        
        let backgroundImageView = UIImageView(frame: bounds)
        
        let profileImageInset = bounds.width * 0.3
        let profileImageWidth = bounds.width - 2*profileImageInset
        let profileImageView = UIImageView(frame: CGRect(x: profileImageInset, y: profileImageInset, width: profileImageWidth, height: profileImageWidth))
        profileImageView.layer.cornerRadius = profileImageWidth/2
        profileImageView.clipsToBounds = true
        
        let playButtonImageInset = bounds.width * 0.43
        let playButtonImageWidth = bounds.width - 2*playButtonImageInset
        let playButtonImageView = UIImageView(frame: CGRect(x: playButtonImageInset + playButtonImageWidth/6, y: playButtonImageInset, width: playButtonImageWidth, height: playButtonImageWidth))
        playButtonImageView.image = R.image.playIcon()
        
        let distanceLabelInset = bounds.width * 0.32
        let distanceLabelWidth = bounds.width - 2*distanceLabelInset
        let distanceLabelHeight: CGFloat = 20
        let distanceLabel = UILabel(frame: CGRect(x: distanceLabelInset, y: profileImageInset + profileImageWidth/2 - distanceLabelHeight/2, width: distanceLabelWidth, height: distanceLabelHeight))
        distanceLabel.minimumScaleFactor = 0.5
        distanceLabel.adjustsFontSizeToFitWidth = true
        distanceLabel.textAlignment = .center
        distanceLabel.baselineAdjustment = .alignCenters
        distanceLabel.font = UIFont.systemFont(ofSize: 13, weight: .black)
        distanceLabel.textColor = .white
        
        // TODO: Tweak this to be more accurate. This has to take into account the outer glow of the image.
        centerOffset = CGVector(dx: 0, dy: -bounds.height/3)
        
        addSubview(backgroundImageView)
        addSubview(profileImageView)
        addSubview(playButtonImageView)
        addSubview(distanceLabel)
        
        self.backgroundImageView = backgroundImageView
        self.profileImageView = profileImageView
        self.playButtonImageView = playButtonImageView
        self.distanceLabel = distanceLabel
        
        updateContent(withState: state)
    }
    
    // MARK: - Content updating
    
    private func updateContent(withState state: State) {
        switch state {
        case .notInRange:
            backgroundImageView?.image = R.image.annotationNotInRangeIcon()
            playButtonImageView?.isHidden = true
            distanceLabel?.isHidden = false
        case .inRange:
            backgroundImageView?.image = R.image.annotationInRangeIcon()
            playButtonImageView?.isHidden = false
            distanceLabel?.isHidden = true
        }
    }
    
    // MARK: - Properties injection from annotation model
    
    func injectProperties(fromSoundAnnotation soundAnnotation: SoundAnnotation) {
        guard let sound = soundAnnotation.sound else {
            return
        }
        
        if let profileImageUrl = sound.userProfileImageUrl {
            profileImageView?.kf.setImage(with: profileImageUrl)
        }
        state = soundAnnotation.inRange ? .inRange : .notInRange
        if let distanceString = soundAnnotation.distanceString {
            self.distanceString = distanceString
        }
    }
    
}

// MARK: - State

extension SoundAnnotationView {
    
    enum State {
        case notInRange
        case inRange
    }
    
}
