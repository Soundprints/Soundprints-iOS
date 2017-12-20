//
//  SoundsModel.swift
//  Soundprints
//
//  Created by Svit Zebec on 13/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - SoundsLocationBasedModelDelegate

protocol SoundsLocationBasedModelDelegate: class {
    
    func soundsLocationBasedModel(_ sender: SoundsLocationBasedModel, fetchedNewSoundsPage newSoundsPage: [Sound], isReload: Bool)
    func soundsLocationBasedModelCouldNotUploadSound(sender: SoundsLocationBasedModel)
    func soundsLocationBasedModel(_ sender: SoundsLocationBasedModel, uploadedSound: Sound, whichWasInsertedAtIndex insertedAtIndex: Int?)
    
}

// MARK: - SoundsLocationBasedModel

class SoundsLocationBasedModel {
    
    // MARK: - Variables
    
    weak var mainDelegate: SoundsLocationBasedModelDelegate?
    weak var listDelegate: SoundsLocationBasedModelDelegate?
    
    private(set) var state: State
    
    private var activeParameters: Parameters?
    private var latestReceivedParamaters: Parameters?
    
    private(set) var sounds: [Sound] = [] 
    
    private(set) var currentFartherstSoundDistance: CLLocationDistance = 0
    
    weak private var refreshTimer: Timer?
    
    private var fetchSoundsFromOnlyLastDay: Bool {
        return FilterManager.filters.age == .lastDay
    }
    private var soundTypeToFetch: Sound.SoundType {
        return Sound.SoundType.fromFilter(FilterManager.filters.type)
    }
    
    private var fetchNextPageLocked = false
    
    private var lastInvalidationDate: Date?
    private var fetchInvalidated = false
    
    // MARK: - Constants
    
    private let maximumFetchRadius: CLLocationDistance = 10000
    private let itemsPerPage: Int = 20
    
    private let distanceChangeTreshold: CLLocationDistance = 100
    private let timeIntervalInvalidationTreshold: TimeInterval = 60
    
    // MARK: - Initialization
    
    init(state: State) {
        self.state = state
    }
    
    // MARK: - Deinitialization
    
    deinit {
        refreshTimer?.invalidate()
        refreshTimer = nil
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
            lastInvalidationDate = Date()
            activeParameters = parameters
            initializeTimer()
            fetchAndAppendNewSoundsPage()
        }
    }
    
    // MARK: - Timer
    
    private func initializeTimer() {
        refreshTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(refreshTimerFired), userInfo: nil, repeats: true)
        if let refreshTimer = refreshTimer {
            RunLoop.current.add(refreshTimer, forMode: .commonModes)
        }
    }
    
    @objc private func refreshTimerFired() {
        if shouldInvalidate() {
            invalidate()
        }
    }
    
    // MARK: - Invalidation
    
    private func invalidate() {
        lastInvalidationDate = Date()
        sounds = []
        currentFartherstSoundDistance = 0
        activeParameters = latestReceivedParamaters
        fetchNextPageLocked = false
        fetchInvalidated = true
        fetchAndAppendNewSoundsPage(afterInvalidation: true)
    }
    
    private func shouldInvalidate(onStateChange: Bool = false) -> Bool {
        
        // When the model is in list state, it should not be invalidated, except if the state was just changed.
        if onStateChange == false && state == .list {
            return false
        }
        
        // If the model hasn't been invalidated in last 'timeIntervalInvalidationTreshold' seconds, it should be.
        guard let lastInvalidationDate = lastInvalidationDate, Date().timeIntervalSince(lastInvalidationDate) < timeIntervalInvalidationTreshold else {
            return true
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
    
    func fetchAndAppendNewSoundsPage(afterInvalidation: Bool = false) {
        guard fetchNextPageLocked == false, let activeParameters = activeParameters else {
            return
        }
        
        fetchNextPageLocked = true
        let isReload = (currentFartherstSoundDistance <= 0 && sounds.isEmpty) || afterInvalidation
        
        Sound.fetchLocationBasedSounds(around: activeParameters.location.coordinate.latitude, and: activeParameters.location.coordinate.longitude, withMinDistance: currentFartherstSoundDistance, andMaxDistance: maximumFetchRadius, withSoundType: soundTypeToFetch, fromOnlyLastDay: fetchSoundsFromOnlyLastDay, limit: itemsPerPage) { sounds, error in
            guard self.fetchInvalidated == false || afterInvalidation else {
                return
            }
            
            if error == nil, let sounds = sounds {
                
                let reversedExistingSounds = self.sounds.reversed()
                let filteredSounds = sounds.filter({ newSound in
                    return !reversedExistingSounds.contains(where: { existingSound in
                        return newSound.id == existingSound.id
                    })
                })
                
                if afterInvalidation {
                    self.sounds = sounds
                } else {
                    self.sounds.append(contentsOf: filteredSounds)
                }
                
                if let newFarthestDistance = filteredSounds.last?.initialDistance?.distanceInMeters {
                    self.currentFartherstSoundDistance = newFarthestDistance
                }
                
                DispatchQueue.main.async {
                    self.mainDelegate?.soundsLocationBasedModel(self, fetchedNewSoundsPage: filteredSounds, isReload: isReload)
                    self.listDelegate?.soundsLocationBasedModel(self, fetchedNewSoundsPage: filteredSounds, isReload: isReload)
                }
            }
            self.fetchInvalidated = false
            self.fetchNextPageLocked = false
        }
    }
    
    // MARK: - Sound uploading
    
    func uploadSound(atFilePath filePath: String) {
        guard let latestReceivedParamaters = latestReceivedParamaters else {
            DispatchQueue.main.async {
                self.mainDelegate?.soundsLocationBasedModelCouldNotUploadSound(sender: self)
                self.listDelegate?.soundsLocationBasedModelCouldNotUploadSound(sender: self)
            }
            return
        } 
        
        Sound.uploadSound(filePath: filePath, location: latestReceivedParamaters.location.coordinate) { uploadedSound, error in
            if error == nil, let uploadedSound = uploadedSound {
                
                // Modify the sounds model only if the uploaded sound has the same type as the current filter. 
                // The uploaded sound will be present in the sounds model when the filter is changed to the appropriate type.
                if uploadedSound.soundType == Sound.SoundType.fromFilter(FilterManager.filters.type) {
                    
                    // The uploaded sound is currently inserted at the beginning of the sounds array, since it is assumed that it is
                    // at a distance of 0 meters. In the future think about calculating the distance and inserting the uploaded sound
                    // into an appropriate (sounds are sorted by distance) place. User could be at a different location when the upload
                    // stops, than he was when the upload wes started.
                    let insertAtIndex = 0
                    self.sounds.insert(uploadedSound, at: insertAtIndex)
                    
                    DispatchQueue.main.async {
                        self.mainDelegate?.soundsLocationBasedModel(self, uploadedSound: uploadedSound, whichWasInsertedAtIndex: insertAtIndex)
                        self.listDelegate?.soundsLocationBasedModel(self, uploadedSound: uploadedSound, whichWasInsertedAtIndex: insertAtIndex)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.mainDelegate?.soundsLocationBasedModel(self, uploadedSound: uploadedSound, whichWasInsertedAtIndex: nil)
                        self.listDelegate?.soundsLocationBasedModel(self, uploadedSound: uploadedSound, whichWasInsertedAtIndex: nil)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.mainDelegate?.soundsLocationBasedModelCouldNotUploadSound(sender: self)
                    self.listDelegate?.soundsLocationBasedModelCouldNotUploadSound(sender: self)
                }
            }
        }
    }
    
}

// MARK: - State

extension SoundsLocationBasedModel {
    
    enum State {
        case map
        case list
    }
    
}

// MARK: - Parameters

extension SoundsLocationBasedModel {
    
    struct Parameters {
        
        fileprivate(set) var location: CLLocation
        
    }
    
}

// MARK: - FilterManagerDelegate

extension SoundsLocationBasedModel: FilterManagerDelegate {
    
    func filterManagerUpdatedFilter(_ filter: Filter) {
        // For now just invalidate the whole model
        invalidate()
    }
    
}
