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

protocol SoundsModelDelegate: class {
    
    func soundsModel(_ sender: SoundsModel, fetchedNewSoundsPage newSoundsPage: [Sound], isReload: Bool)
    
}

// MARK: - SoundsModel

class SoundsModel {
    
    // MARK: - Variables
    
    weak var mainDelegate: SoundsModelDelegate?
    weak var listDelegate: SoundsModelDelegate?
    
    private(set) var state: State
    
    private var activeParameters: Parameters?
    private var latestReceivedParamaters: Parameters?
    
    private(set) var sounds: [Sound] = [] 
    
    private(set) var currentFartherstSoundDistance: CLLocationDistance = 0
    
    private var refreshTimer: Timer?
    
    private var fetchSoundsFromOnlyLastDay: Bool {
        return FilterManager.filters.age == .lastDay
    }
    private var soundTypeToFetch: Sound.SoundType {
        return Sound.SoundType.fromFilter(FilterManager.filters.type)
    }
    
    private var fetchNextPageLocked = false
    
    // MARK: - Constants
    
    private let maximumFetchRadius: CLLocationDistance = 10000
    private let itemsPerPage: Int = 20
    
    private let distanceChangeTreshold: CLLocationDistance = 100
    
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
            invalidate()
        }
    }
    
    // MARK: - Updating of latest parameters
    
    func updateLatestParameters(_ parameters: Parameters) {
        let firstUpdate = latestReceivedParamaters == nil
        latestReceivedParamaters = parameters
        if firstUpdate {
            activeParameters = parameters
            initializeTimer()
            fetchAndAppendNewSoundsPage()
        }
    }
    
    // MARK: - Timer
    
    private func initializeTimer() {
        refreshTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(refreshTimerFired), userInfo: nil, repeats: true)
    }
    
    @objc private func refreshTimerFired() {
        if shouldInvalidate() {
            invalidate()
        }
    }
    
    // MARK: - Invalidation
    
    private func invalidate() {
        sounds = []
        currentFartherstSoundDistance = 0
        fetchAndAppendNewSoundsPage()
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
        
        return latestParameters.location.distance(from: activeParameters.location) > distanceChangeTreshold
    }
    
    // MARK: - Sounds fetching
    
    func fetchAndAppendNewSoundsPage() {
        guard fetchNextPageLocked == false, let activeParameters = activeParameters else {
            return
        }
        
        fetchNextPageLocked = true
        let isReload = currentFartherstSoundDistance <= 0
        
        Sound.fetchSounds(around: activeParameters.location.coordinate.latitude, and: activeParameters.location.coordinate.longitude, withMinDistance: currentFartherstSoundDistance, andMaxDistance: maximumFetchRadius, withSoundType: soundTypeToFetch, fromOnlyLastDay: fetchSoundsFromOnlyLastDay, limit: itemsPerPage) { sounds, error in
            if error == nil, let sounds = sounds {
                
                let reversedExistingSounds = self.sounds.reversed()
                let filteredSounds = sounds.filter({ newSound in
                    return !reversedExistingSounds.contains(where: { existingSound in
                        return newSound.id == existingSound.id
                    })
                })
                
                self.sounds.append(contentsOf: filteredSounds)
                
                if let newFarthestDistance = filteredSounds.last?.initialDistance?.distanceInMeters {
                    self.currentFartherstSoundDistance = newFarthestDistance
                }
                
                DispatchQueue.main.async {
                    self.mainDelegate?.soundsModel(self, fetchedNewSoundsPage: filteredSounds, isReload: isReload)
                    self.listDelegate?.soundsModel(self, fetchedNewSoundsPage: filteredSounds, isReload: isReload)
                }
            }
            self.fetchNextPageLocked = false
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
        
    }
    
}

// MARK: - FilterManagerDelegate

extension SoundsModel: FilterManagerDelegate {
    
    func filterManagerUpdatedFilter(_ filter: Filter) {
        // For now just invalidate the whole model
        invalidate()
    }
    
}
