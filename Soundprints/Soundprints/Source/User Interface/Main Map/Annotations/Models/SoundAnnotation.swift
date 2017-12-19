//
//  SoundAnnotation.swift
//  Soundprints
//
//  Created by Svit Zebec on 05/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation
import Mapbox

class SoundAnnotation: MGLPointAnnotation {
    
    // MARK: - Variables
    
    weak var sound: Sound?
    /// Distance in meters
    private(set) var distance: Double?
    /// Distance represented in string. If closer than 50 meters it will be in meters, otherwise in kilometers.
    var distanceString: String? {
        guard let distance = distance else {
            return nil
        }
        let distanceInKilometers = distance/1000.0
        let roundedKilometers = Double(round(distanceInKilometers*10)/10)
        if roundedKilometers < 0.1 {
            let metersToDisplay = Int(max(1,round(distance/10))*10)
            return String(format: "%dm", metersToDisplay)
        } else {
            return String(format: "%.1fkm", roundedKilometers)
        }
    }
    private(set) var inRange: Bool = false
    
    // MARK: - Initializers
    
    convenience init?(sound: Sound) {
        guard let latitude = sound.latitude, let longitude = sound.longitude else {
            return nil
        }
        
        self.init()
        
        self.sound = sound
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        if let distanceInMeters = sound.initialDistance?.distanceInMeters {
            self.distance = distanceInMeters
        }
    }
    
    // MARK: - Distance info updating
    
    func updateDistanceInfo(withUserLocation userLocation: CLLocation, andInRangeTreshold inRangeTreshold: Double) {
        guard let latitude = sound?.latitude, let longitude = sound?.longitude else {
            return
        }
        let newDistance = CLLocation(latitude: latitude, longitude: longitude).distance(from: userLocation)
        inRange = newDistance <= inRangeTreshold
        distance = newDistance
    }
    
}
