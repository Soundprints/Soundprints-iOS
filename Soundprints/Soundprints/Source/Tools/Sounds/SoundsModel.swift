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
    func soundModelCouldNotUploadSound(sender: SoundsModel)
    func soundModel(_ sender: SoundsModel, uploadedSound: Sound, whichWasInsertedAtIndex insertedAtIndex: Int)
    
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
    
    weak private var refreshTimer: Timer?
    
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
        activeParameters = latestReceivedParamaters
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
        let isReload = currentFartherstSoundDistance <= 0 && sounds.isEmpty
        
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
    
    // MARK: - Sound uploading
    
    func uploadSound(atFilePath filePath: String) {
        guard let latestReceivedParamaters = latestReceivedParamaters else {
            DispatchQueue.main.async {
                self.mainDelegate?.soundModelCouldNotUploadSound(sender: self)
                self.listDelegate?.soundModelCouldNotUploadSound(sender: self)
            }
            return
        } 
        
        Sound.uploadSound(filePath: filePath, location: latestReceivedParamaters.location.coordinate) { uploadedSound, error in
            if error == nil, let uploadedSound = uploadedSound {
                // The uploaded sound is currently inserted at the beginning of the sounds array, since it is assumed that it is
                // at a distance of 0 meters. In the future think about calculating the distance and inserting the uploaded sound
                // into an appropriate (sounds are sorted by distance) place. User could be at a different location when the upload
                // stops, than he was when the upload wes started.
                let insertAtIndex = 0
                self.sounds.insert(uploadedSound, at: insertAtIndex)
                DispatchQueue.main.async {
                    self.mainDelegate?.soundModel(self, uploadedSound: uploadedSound, whichWasInsertedAtIndex: insertAtIndex)
                    self.listDelegate?.soundModel(self, uploadedSound: uploadedSound, whichWasInsertedAtIndex: insertAtIndex)
                }
            } else {
                DispatchQueue.main.async {
                    self.mainDelegate?.soundModelCouldNotUploadSound(sender: self)
                    self.listDelegate?.soundModelCouldNotUploadSound(sender: self)
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
        
    }
    
}

// MARK: - FilterManagerDelegate

extension SoundsModel: FilterManagerDelegate {
    
    func filterManagerUpdatedFilter(_ filter: Filter) {
        // For now just invalidate the whole model
        invalidate()
    }
    
}
