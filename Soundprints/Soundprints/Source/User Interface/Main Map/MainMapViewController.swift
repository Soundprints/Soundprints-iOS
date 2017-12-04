//
//  MainMapViewController.swift
//  Soundprints
//
//  Created by Svit Zebec on 29/11/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit
import Mapbox
import Kingfisher

class MainMapViewController: BaseViewController {
    
    // MARK: - Outlets
    
    @IBOutlet private weak var mapView: MGLMapView?
    
    // MARK: - Variables
    
    private var sounds: [Sound] = []
    
    private var lastSoundFetchLocation: CLLocation?
    
    private var shouldUpdateZoomLevel: Bool = false
    private var minimumVisibleMeters: Double = 3000
    
    // MARK: - Constants
    
    private static let soundFetchDistanceTreshold: Double = 100
    private static var inRangeMetersTreshold: Double = 1500
    
    // MARK: - View controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeMap()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let userLocation = mapView?.userLocation {
            setZoomLevelToMinimumVisibleMeters(minimumVisibleMeters, onLatitude: userLocation.coordinate.latitude, animated: false)
        } else {
            shouldUpdateZoomLevel = true
        }
    }
    
    // MARK: - Map
    
    private func initializeMap() {
        mapView?.delegate = self
        mapView?.showsUserLocation = true
    }
    
    private func setZoomLevelToMinimumVisibleMeters(_ meters: Double, onLatitude latitude: Double, animated: Bool) {
        guard let mapView = mapView else {
            return
        }
        
        // Now we have to calculate the zoom level so that at least 'meters' meters are in the smaller dimension of the map.
        // How to do this can be found here: http://wiki.openstreetmap.org/wiki/Zoom_levels
        let mapViewMinimumDimension = mapView.bounds.width < mapView.bounds.height ? Double(mapView.bounds.width) : Double(mapView.bounds.height)
        let distancePerPixel = meters/mapViewMinimumDimension
        let earthCircumference = 40075000.0
        let latitudeInRadians = latitude * (.pi/180)
        // Subtract 7 instead of 8, because Mapbox's implementation works with 512x512 pixel tiles and the zoom level from 
        // the link above is true for 256x256 pixel tiles. This means that the zoom level will be off by one and we simply subtract one more.
        let zoomLevel = log2((earthCircumference*cos(latitudeInRadians))/distancePerPixel) - 9
        
        mapView.setZoomLevel(zoomLevel, animated: animated)
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
        
        let newAnnotations: [SoundAnnotation] = sounds.flatMap { sound in
            let annotation = SoundAnnotation(sound: sound)
            if let latitude = sound.latitude, let longitude = sound.longitude {
                annotation?.distance = distanceInKilometers(fromLatitude: latitude, andLongitude: longitude, to: mapView?.userLocation?.location)
            }
            return annotation
        }
        mapView?.addAnnotations(newAnnotations)
    }
    
    private func updateVisibleAnnotationViewsIfNecessary() {
        guard let userCLLocation = mapView?.userLocation?.location else {
            return
        }
        
        var annotationsToRefresh: [SoundAnnotation] = []
        mapView?.visibleAnnotations?.forEach({ annotation in
            if let soundAnnotation = annotation as? SoundAnnotation {
                let oldDistanceString = soundAnnotation.distanceString
                let oldInRange = soundAnnotation.inRange
                
                let newDistance = distanceInKilometers(fromLatitude: soundAnnotation.coordinate.latitude, andLongitude: soundAnnotation.coordinate.longitude, to: userCLLocation)
                soundAnnotation.distance = newDistance
                
                if soundAnnotation.distanceString != oldDistanceString || soundAnnotation.inRange != oldInRange {
                    annotationsToRefresh.append(soundAnnotation)
                }
            }
        })
        
        print("refreshing annotations: \(annotationsToRefresh.debugDescription)")
        
        mapView?.removeAnnotations(annotationsToRefresh)
        mapView?.addAnnotations(annotationsToRefresh)
    }
    
    private func distanceInKilometers(from: CLLocation?, to: CLLocation?) -> Double? {
        guard let from = from, let to = to else {
            return nil
        }
        return to.distance(from: from)/1000.0
    }
    
    private func distanceInKilometers(fromLatitude latitude: Double, andLongitude longitude: Double, to: CLLocation?) -> Double? {
        guard let to = to else {
            return nil
        }
        return to.distance(from: CLLocation(latitude: latitude, longitude: longitude))/1000.0
    }

}

// MARK: - SoundAnnotation

private extension MainMapViewController {
    
    class SoundAnnotation: MGLPointAnnotation {
        
        weak var sound: Sound?
        /// Distance in kilometers
        var distance: Double?
        var distanceString: String? {
            guard let distance = distance else {
                return nil
            }
            let roundedKilometers = Double(round(distance*10)/10)
            if roundedKilometers < 0.1 {
                let meters = Int(round(distance*1000.0))
                return String(format: "%dm", meters)
            } else {
                return String(format: "%.1fkm", roundedKilometers)
            }
        }
        var inRange: Bool {
            guard let distance = distance else {
                return false
            }
            return distance*1000.0 <= MainMapViewController.inRangeMetersTreshold
        }
        
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

// MARK: - Custom annotation views

private extension MainMapViewController {
    
    class UserAnnotationView: MGLUserLocationAnnotationView {
        
        var userPositionImageView: UIImageView?
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        init(reuseIdentifier: String?, frame: CGRect) {
            super.init(reuseIdentifier: reuseIdentifier)
            
            let bounds = CGRect(origin: .zero, size: frame.size)
            
            self.frame = frame
            backgroundColor = .clear
            
            let userPositionImageView = UIImageView(frame: bounds)
            userPositionImageView.image = R.image.userLocationIcon()
            
            addSubview(userPositionImageView)
            
            self.userPositionImageView = userPositionImageView
        }
        
    }
    
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
        
        var distanceString: String = "" {
            didSet {
                distanceLabel?.text = distanceString
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
            
            if let profileImageUrl = sound.userProfileImageUrl {
                profileImageView?.kf.setImage(with: URL(string: profileImageUrl))
            }
            state = soundAnnotation.inRange ? .inRange : .notInRange
            if let distanceString = soundAnnotation.distanceString {
                self.distanceString = distanceString
            }
        }
        
    }
    
}

// MARK: - MGLMapViewDelegate

extension MainMapViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        guard let userLocation = userLocation, let userCLLocation = userLocation.location else {
            return
        }
        
        mapView.setCenter(userLocation.coordinate, animated: false)
        
        if shouldUpdateZoomLevel {
            setZoomLevelToMinimumVisibleMeters(minimumVisibleMeters, onLatitude: userLocation.coordinate.latitude, animated: false)
            shouldUpdateZoomLevel = false
        }
        
        if distanceInKilometers(from: userCLLocation, to: lastSoundFetchLocation) ?? CLLocationDistanceMax > MainMapViewController.soundFetchDistanceTreshold {
            lastSoundFetchLocation = userCLLocation
            // TODO: Change radius to real radius of the map. For now it is hardcoded to 1000m.
            updateSounds(arroundCoordinate: userCLLocation.coordinate, withRadius: 1000)
        } else {
            updateVisibleAnnotationViewsIfNecessary()
        }
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        if let soundAnnotation = annotation as? SoundAnnotation {
            let annotationViewSize = CGSize(width: 100, height: 110)
            let reuseIdentifier = "reusableSoundprintsAnnotationView"
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? SoundAnnotationView
            
            if annotationView == nil {
                annotationView = SoundAnnotationView(reuseIdentifier: reuseIdentifier, frame: CGRect(origin: .zero, size: annotationViewSize))
            }
            annotationView?.injectProperties(fromSoundAnnotation: soundAnnotation)
            
            print("in viewFor annotation")
            
            return annotationView
            
        } else if annotation is MGLUserLocation {
            let annotationViewSize = CGSize(width: 46, height: 53)
            let reuseIdentifier = "reusableUserAnnotationView"
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? UserAnnotationView
            
            if annotationView == nil {
                annotationView = UserAnnotationView(reuseIdentifier: reuseIdentifier, frame: CGRect(origin: .zero, size: annotationViewSize))
            }
            
            return annotationView
        }
        
        return nil
    }
    
}
