//
//  MainMapViewController.swift
//  Soundprints
//
//  Created by Svit Zebec on 29/11/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit
import Mapbox

class MainMapViewController: BaseViewController {
    
    // MARK: - Outlets
    
    @IBOutlet private weak var mapView: MGLMapView?
    
    // MARK: - View controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeMap()
    }
    
    // MARK: - Map
    
    private func initializeMap() {
        mapView?.delegate = self
        mapView?.showsUserLocation = true
        
        // TODO: Remove these mocked annotations
        
        let annotation1 = MGLPointAnnotation()
        annotation1.coordinate = CLLocationCoordinate2D(latitude: 46.052577, longitude: 14.510292)
        
        let annotation2 = MGLPointAnnotation()
        annotation2.coordinate = CLLocationCoordinate2D(latitude: 46.052063, longitude: 14.512116)
        
        mapView?.addAnnotations([annotation1, annotation2])
    }

}

// MARK: - SoundAnnotation

private extension MainMapViewController {
    
    class SoundAnnotation: MGLPointAnnotation {
        
        // TODO: Add data that is needed here
        
    }
    
}

// MARK: - SoundAnnotationView

private extension MainMapViewController {
    
    class SoundAnnotationView: MGLAnnotationView {
        
        var backgroundImageView: UIImageView?
        var profileImageView: UIImageView?
        var playButtonImageView: UIImageView?
        var distanceLabel: UILabel?
        
        var profileImage: UIImage? {
            didSet {
                profileImageView?.image = profileImage
            }
        }
        
        /// Distance in kilometers
        var distance: Double = 0 {
            didSet {
                distanceLabel?.text = "\(distance)km"
            }
        }
        
        enum State {
            case notInRange
            case inRange
        }
        
        var state: State = .notInRange {
            didSet {
                updateContent(withState: state)
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        init(reuseIdentifier: String?, frame: CGRect) {
            super.init(reuseIdentifier: reuseIdentifier)
            
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
        
    }
    
}

// MARK: - MGLMapViewDelegate

extension MainMapViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        guard let userLocation = userLocation else {
            return
        }
        
        mapView.setCenter(userLocation.coordinate, animated: true)
        mapView.setZoomLevel(15, animated: true)
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        let annotationViewSize = CGSize(width: 100, height: 110)
        let reuseIdentifier = "reusableSoundprintsAnnotationView"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? SoundAnnotationView
        
        if annotationView == nil {
            annotationView = SoundAnnotationView(reuseIdentifier: reuseIdentifier, frame: CGRect(origin: .zero, size: annotationViewSize))
            annotationView?.state = .notInRange
        }
        
        annotationView?.distance = 0.5
        annotationView?.profileImage = R.image.sampleProfileImage()
        
        return annotationView
    }
    
}
