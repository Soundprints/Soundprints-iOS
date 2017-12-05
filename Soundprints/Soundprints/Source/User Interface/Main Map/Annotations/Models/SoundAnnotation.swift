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
    /// Distance in kilometers
    var distance: Double?
    /// Distance represented in string. If closer than 50 meters it will be in meters, otherwise in kilometers.
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
    
    // MARK: - Initializers
    
    convenience init?(sound: Sound) {
        guard let latitude = sound.latitude, let longitude = sound.longitude else {
            return nil
        }
        
        self.init()
        
        self.sound = sound
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
}
