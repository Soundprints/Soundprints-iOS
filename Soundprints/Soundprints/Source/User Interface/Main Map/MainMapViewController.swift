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
    static var inRangeMetersTreshold: Double = 1500
    
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
    
    // MARK: - Annotations
    
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
