//
//  Sound.swift
//  Soundprints
//
//  Created by Svit Zebec on 30/11/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation

class Sound {
    
    // MARK: - Properties
    
    private(set) var id: String?
    private(set) var name: String?
    private(set) var description: String?
    private(set) var latitude: Double?
    private(set) var longitude: Double?
    private(set) var userId: String?
    private(set) var userDisplayName: String?
    private var userProfileImageUrlString: String?
    private(set) var duration: TimeInterval?
    private(set) var initialDistance: SingleDistanceValue?
    private(set) var submissionDate: Date?
    private var resourceURL: ResourceURL?
    
    var userProfileImageUrl: URL? {
        guard let userProfileImageUrlString = userProfileImageUrlString else {
            return nil
        }
        return URL(string: userProfileImageUrlString)
    }
    
    // MARK: - Initializers
    
    convenience init(descriptor: [String: Any]?) {
        self.init()
        
        injectProperties(from: descriptor)
    }
    
    // MARK: - Resource URL
    
    func timeSinceSubmissionDisplayString() -> String? {
        guard let submissionDate = submissionDate else {
            return nil
        }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.year, .month, .day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 1
        
        return formatter.string(from: Date().timeIntervalSince(submissionDate))
    }
    
    // MARK: - Display strings
    
    func durationAndDistanceDisplayString() -> String? {
        guard let distanceValue = initialDistance else {
            return durationDisplayString(forceShortUnitStyle: false)
        }
        guard let durationString = durationDisplayString(forceShortUnitStyle: true) else {
            return initialDistance?.displayString()
        }
        return "\(durationString), \(distanceValue.displayString())"
    }
    
    func durationDisplayString(forceShortUnitStyle: Bool) -> String? {
        guard let duration = duration else {
            return nil
        }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.maximumUnitCount = 3
        formatter.unitsStyle = (forceShortUnitStyle || duration >= 60) ? .abbreviated : .full
        
        return formatter.string(from: duration)
    }
    
    func getResourceURL(callback: @escaping ((_ url: URL?, _ error: APIError?) -> Void)) {
        if let resourceURL = resourceURL, resourceURL.isValid {
            callback(resourceURL.url, nil)
            return
        }
        
        fetchResourceUrl { resourceURL, error in
            self.resourceURL = resourceURL
            callback(resourceURL?.url, error)
        }
    }
    
    // MARK: - Properties injection
    
    private func injectProperties(from descriptor: [String: Any]?) {
        let wrapper = APIJSONTools.DictionaryWrapper(dictionary: descriptor)
        
        id = wrapper.string(key: "id")
        name = wrapper.string(key: "name")
        description = wrapper.string(key: "description")
        if let locationDescriptor = wrapper.descriptor(key: "location") {
            let locationWrapper = APIJSONTools.DictionaryWrapper(dictionary: locationDescriptor)
            latitude = locationWrapper.double(key: "lat")
            longitude = locationWrapper.double(key: "lon")
        }
        if let userDescriptor = wrapper.descriptor(key: "user") {
            let userWrapper = APIJSONTools.DictionaryWrapper(dictionary: userDescriptor)
            userId = userWrapper.string(key: "id")
            userDisplayName = userWrapper.string(key: "displayName")
            userProfileImageUrlString = userWrapper.string(key: "profileImageUrl")
        }
        duration = wrapper.double(key: "duration")
        if let distanceMeters = wrapper.double(key: "distance") {
            initialDistance = SingleDistanceValue.from(meters: distanceMeters)
        } else {
            initialDistance = nil
        }
        if let submissionDateInterval = wrapper.double(key: "submissionDate") {
            submissionDate = Date(timeIntervalSince1970: submissionDateInterval)
        } else {
            submissionDate = nil
        }
    }
    
}

// MARK: - Request functions

extension Sound {
    
    static func fetchSounds(around latitude: Double, and longitude: Double, withMinDistance minDistance: Double? = nil, andMaxDistance maxDistance: Double, fromOnlyLastDay onlyLastDay: Bool = false, limit: Int? = nil, callback: @escaping ((_ sounds: [Sound]?, _ error: APIError?) -> Void)) {
        let request = APIRequest(endpoint: .sound, method: .GET)
        request.queryParameters["lat"] = latitude
        request.queryParameters["lon"] = longitude
        request.queryParameters["maxDistance"] = maxDistance
        if let minDistance = minDistance {
            request.queryParameters["minDistance"] = minDistance
        }
        request.queryParameters["onlyLastDay"] = onlyLastDay ? "true" : "false"
        if let limit = limit {
            request.queryParameters["limit"] = limit
        }
        
        APIManager.performRequest(request: request) { response, error in
            let sounds: [Sound]? = ((response as? [String: Any])?["sounds"] as? [[String: Any]])?.flatMap { Sound(descriptor: $0) }
            callback(sounds, error)
        }
    }
    
    private func fetchResourceUrl(callback: @escaping ((_ url: ResourceURL?, _ error: APIError?) -> Void)) {
        guard let soundId = id else {
            callback(nil, APIError(localError: .generalError))
            return
        }
        
        let request = APIRequest(endpoint: .soundResourceURL(id: soundId), method: .GET)
        if let duration = duration {
            let expirationDuration = Int(floor(3*duration))
            request.queryParameters["minutes"] = expirationDuration
        }
        
        APIManager.performRequest(request: request) { response, error in
            if let data = response as? [String: Any] {
                let wrapper = APIJSONTools.DictionaryWrapper(dictionary: data)
                if let urlString = wrapper.string(key: "url"), let url = URL(string: urlString), let unixDate: TimeInterval = wrapper.double(key: "expirationDate") {
                    let expirationDate = Date(timeIntervalSince1970: unixDate)
                    let resourceURL = ResourceURL(url: url, expirationDate: expirationDate)
                    callback(resourceURL, nil)
                } else {
                    callback(nil, APIError(localError: .generalError))
                }
            } else {
                callback(nil, error)
            }
        }
    }
    
}

// MARK: - ResourceURL

extension Sound {
    
    struct ResourceURL {
        var url: URL
        var expirationDate: Date
        
        var isValid: Bool {
            return expirationDate < Date()
        }
    }
    
}
