//
//  SoundsModel.swift
//  Soundprints
//
//  Created by Svit Zebec on 13/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - SoundsModelDelegate

protocol SoundsModelMapDelegate: class {
    
    func soundsModel(_ sender: SoundsModel, updatedMapSounds mapSounds: [Sound])
    
}

protocol SoundsModelDelegate: class {
    
    func soundsModel(_ sender: SoundsModel, updatedAndReplacedSounds sounds: [Sound])
    func soundsModel(_ sender: SoundsModel, addedSounds sounds: [Sound])
    
}

// MARK: - SoundsModel

class SoundsModel {
    
    // MARK: - Variables
    
    weak var delegate: SoundsModelDelegate?
    weak var mapDelegate: SoundsModelMapDelegate?
    
    private(set) var state: State
    
    private var activeParameters: Parameters?
    private var latestReceivedParamaters: Parameters?
    
    private(set) var sounds: [Sound] = [] 
    private(set) var mapSounds: [Sound] = []
    
    private var currentFartherstSoundDistance: CLLocationDistance?
    
    private var refreshTimer: Timer?
    
    private lazy var newPageThrottle = Throttle(delay: 5, maxLimit: 0)
    
    private var fetchSoundsFromOnlyLastDay: Bool {
        return FilterManager.filters.age == .lastDay
    }
    private var soundTypeToFetch: Sound.SoundType {
        return Sound.SoundType.fromFilter(FilterManager.filters.type)
    }
    
    // MARK: - Constants
    
    private let maximumFetchRadius: CLLocationDistance = 10000
    private let itemsPerPage: Int = 20
    
    private let distanceChangeTreshold: CLLocationDistance = 100
    private let radiusChangeTreshold: Double = 100
    
    // MARK: - Initialization
    
    init(state: State) {
        self.state = state
    }
    
    // MARK: - State manipulation
    
    func setState(_ state: State) {
        guard self.state != state else {
            return
        }
        
        self.state = state
        
        if shouldInvalidate(onStateChange: true) {
            fetchAndReplaceSounds()
        }
    }
    
    // MARK: - Updating of latest parameters
    
    func updateLatestParameters(_ parameters: Parameters) {
        let firstUpdate = latestReceivedParamaters == nil
        latestReceivedParamaters = parameters
        if firstUpdate {
            initializeTimer()
            fetchAndReplaceSounds()
        }
    }
    
    // MARK: - Timer
    
    private func initializeTimer() {
        refreshTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(refreshTimerFired), userInfo: nil, repeats: true)
    }
    
    @objc private func refreshTimerFired() {
        if shouldInvalidate() {
            fetchAndReplaceSounds()
        }
    }
    
    // MARK: - Invalidation
    
    private func invalidate() {
        fetchAndReplaceSounds()
    }
    
    private func shouldInvalidate(onStateChange: Bool = false) -> Bool {
        // When the model is in list state, it should not be invalidated, except if the state was just changed.
        if onStateChange == false && state == .list {
            return false
        }
        guard let latestParameters = latestReceivedParamaters else {
            return false
        }
        guard let activeParameters = activeParameters else {
            return true
        }
        
        return latestParameters.location.distance(from: latestParameters.location) > distanceChangeTreshold || latestParameters.radius - activeParameters.radius > radiusChangeTreshold
    }
    
    // MARK: - Sounds fetching
    
    private func fetchAndReplaceSounds() {
        guard let latestParameters = latestReceivedParamaters else {
            return
        }
        
        // TODO: Integrate the type filter
        Sound.fetchSounds(around: latestParameters.location.coordinate.latitude, and: latestParameters.location.coordinate.longitude, withMinDistance: 0, andMaxDistance: latestParameters.radius, withSoundType: soundTypeToFetch, fromOnlyLastDay: fetchSoundsFromOnlyLastDay) { sounds, error in
            if error == nil, let sounds = sounds {
                self.sounds = sounds
                DispatchQueue.main.async {
                    self.delegate?.soundsModel(self, updatedAndReplacedSounds: sounds)
                }
                switch self.state {
                case .map: 
                    self.mapSounds = sounds
                    DispatchQueue.main.async {
                        self.mapDelegate?.soundsModel(self, updatedMapSounds: sounds)
                    }
                case .list: break
                }
                
                self.currentFartherstSoundDistance = sounds.last?.initialDistance?.distanceInMeters
                self.activeParameters = latestParameters
            } else {
                // TODO: Handle error
            }
        }
    }
    
    func fetchAndAppendNewSoundsPage() {
        newPageThrottle.run {
            self.fetchAndAppendNewSoundsPageInternal()
        }
    }
    
    private func fetchAndAppendNewSoundsPageInternal() {
        guard state == .list, let activeParameters = activeParameters, let minRadius = currentFartherstSoundDistance else {
            return
        }
        
        Sound.fetchSounds(around: activeParameters.location.coordinate.latitude, and: activeParameters.location.coordinate.longitude, withMinDistance: minRadius, andMaxDistance: maximumFetchRadius, withSoundType: soundTypeToFetch, fromOnlyLastDay: fetchSoundsFromOnlyLastDay, limit: itemsPerPage) { sounds, error in
            if error == nil, let sounds = sounds {
                self.sounds.append(contentsOf: sounds)
                DispatchQueue.main.async {
                    self.delegate?.soundsModel(self, addedSounds: sounds)
                }
                
                if let newFarthestDistance = sounds.last?.initialDistance?.distanceInMeters {
                    self.currentFartherstSoundDistance = newFarthestDistance
                    self.activeParameters?.radius = newFarthestDistance
                }
            }
        }
    }
    
}

// MARK: - State

extension SoundsModel {
    
    enum State {
        case map
        case list
    }
    
}

// MARK: - Parameters

extension SoundsModel {
    
    struct Parameters {
        
        fileprivate(set) var location: CLLocation
        fileprivate(set) var radius: CLLocationDistance
        
    }
    
}

// MARK: - FilterManagerDelegate

extension SoundsModel: FilterManagerDelegate {
    
    func filterManagerUpdatedFilter(_ filter: Filter) {
        // For now just invalidate the whole model
        invalidate()
    }
    
}
