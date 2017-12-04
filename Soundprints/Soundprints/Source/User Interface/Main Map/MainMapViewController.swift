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
    
    // MARK: - Variables
    
    private var sounds: [Sound] = []
    
    private var lastSoundFetchLocation: CLLocation?
    
    // MARK: - Constants
    
    private static let soundFetchDistanceTreshold: Double = 100
    
    // MARK: - View controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeMap()
    }
    
    // MARK: - Map
    
    private func initializeMap() {
        mapView?.delegate = self
        mapView?.showsUserLocation = true
        mapView?.setZoomLevel(15, animated: false)
    }
    
    // MARK: - Sounds
    
    private func updateSounds(arroundCoordinate coordinate: CLLocationCoordinate2D, withRadius radius: Double) {
        Sound.fetchSounds(around: coordinate.latitude, and: coordinate.longitude, andMaxDistance: radius) { sounds, error in
            if error == nil, let sounds = sounds {
                self.sounds = sounds
                self.refreshSoundAnnotations()
            } else {
                // TODO: Handle error
            }
        }
    }
    
    private func refreshSoundAnnotations() {
        if let existingAnnotations = mapView?.annotations {
            mapView?.removeAnnotations(existingAnnotations)
        }
        
        let newAnnotations = sounds.flatMap { SoundAnnotation(sound: $0) }
        mapView?.addAnnotations(newAnnotations)
    }

}

// MARK: - SoundAnnotation

private extension MainMapViewController {
    
    class SoundAnnotation: MGLPointAnnotation {
        
        weak var sound: Sound?
        
        init?(sound: Sound) {
            guard let latitude = sound.latitude, let longitude = sound.longitude else {
                return nil
            }
            
            super.init()
            
            self.sound = sound
            self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
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
        
        func updateContent(withState state: State) {
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
        
        func injectProperties(fromSoundAnnotation soundAnnotation: SoundAnnotation) {
            guard let sound = soundAnnotation.sound else {
                return
            }
            
            // TODO: Set profile image
        }
        
    }
    
}

// MARK: - MGLMapViewDelegate

extension MainMapViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        guard let userLocation = userLocation, let userCLLocation = userLocation.location else {
            return
        }
        
        print("updated user location: \(userCLLocation.coordinate)")
        print("self map view: \(self.mapView)")
        print("map view: \(mapView)")
        
        mapView.setCenter(userLocation.coordinate, animated: false)
        
        if lastSoundFetchLocation?.distance(from: userCLLocation) ?? CLLocationDistanceMax > MainMapViewController.soundFetchDistanceTreshold {
            // TODO: Change radius to real radius of the map. For now it is hardcoded to 1000m.
            updateSounds(arroundCoordinate: userCLLocation.coordinate, withRadius: 1000)
        }
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        guard let soundAnnotation = annotation as? SoundAnnotation else {
            return nil
        }
        
        let annotationViewSize = CGSize(width: 100, height: 110)
        let reuseIdentifier = "reusableSoundprintsAnnotationView"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? SoundAnnotationView
        
        if annotationView == nil {
            annotationView = SoundAnnotationView(reuseIdentifier: reuseIdentifier, frame: CGRect(origin: .zero, size: annotationViewSize))
            annotationView?.state = .notInRange
            annotationView?.injectProperties(fromSoundAnnotation: soundAnnotation)
        }
        
        return annotationView
    }
    
}
