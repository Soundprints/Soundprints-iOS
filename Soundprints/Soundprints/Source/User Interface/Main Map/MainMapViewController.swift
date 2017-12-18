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
import GLKit

class MainMapViewController: BaseViewController {
    
    // MARK: - Outlets
    
    @IBOutlet private weak var mapView: MGLMapView?
    @IBOutlet private weak var menuContainerView: UIView?
    @IBOutlet private weak var contentControllerView: InteractionLockingContentControllerView?
    @IBOutlet private weak var listenView: ListenView?
    @IBOutlet private weak var recordImageView: UIImageView?
    @IBOutlet private weak var recordButton: UIButton?
    @IBOutlet private weak var progressBarView: ProgressBarView?
    
    // MARK: - Variables
    
    private var soundsModel: SoundsModel = SoundsModel(state: .map)
    
    static var inRangeMetersTreshold: Double = 450
    
    private var sounds: [Sound] = []
    
    private lazy var headingLocationManager: CLLocationManager = CLLocationManager()
    
    private var shouldUpdateZoomLevel: Bool = false
    private var minimumVisibleMeters: Double {
        // The proximity rings size is 3/4 of the smaller dimension and the proximity rings size is equivalent to 'inRangeMetersTreshold'.
        return MainMapViewController.inRangeMetersTreshold * (4/3) * 2
    }
    private var maximumVisibleRadius: Double? {
        guard let mapView = mapView else {
            return nil
        }
        let widthMeters = minimumVisibleMeters
        let heightMeters = Double(mapView.bounds.size.height/mapView.bounds.size.width) * minimumVisibleMeters 
        return sqrt(pow(widthMeters, 2) + pow(heightMeters, 2))
    }
    
    private var proximityRingsView: ProximityRingsView?
    
    /// Variable that extracts the subview of type GLKView from the mapView.
    private var mapGLKView: UIView? {
        return mapView?.subviews.first(where: { $0 is GLKView })
    }
    
    private var currentlyPlayedSoundAnnotation: SoundAnnotation?
    
    private var annotationsHidden = false {
        didSet {
            if oldValue != annotationsHidden {
                refreshSoundAnnotations()
            }
        }
    }
    
    private var maximumVisibleMapRadius: Double? {
        guard let visibleCoordinateBounds = mapView?.visibleCoordinateBounds, let currentLocation = mapView?.userLocation?.location else {
            return nil
        }
        
        let mapCornerLocation = CLLocation(latitude: visibleCoordinateBounds.ne.latitude, longitude: visibleCoordinateBounds.ne.longitude)
        return mapCornerLocation.distance(from: currentLocation)
    }

    // MARK: - Constants
    
    private let listenViewHiddenAnimationDuration: Double = 1
    
    // MARK: - View controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeMap()
        initializeProximityRingsView()
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        recognizer.minimumPressDuration = 0.1
        recordImageView?.addGestureRecognizer(recognizer)
        
        // TODO: decide what to use recognizer vs button
        recordButton?.isUserInteractionEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        soundsModel.mainDelegate = self
        FilterManager.delegate = soundsModel
        listenView?.delegate = self
        RecorderAndPlayer.shared.delegate = self
        
        startUpdatingHeading()
        
        RecorderAndPlayer.shared.requestPermission { granted in
            if !granted { // cant record
                // TODO: alert user
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopUpdatingHeading()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Zoom level should be set the the views are layed out, so try to do it here if we have the location.
        // If not, it should be done in the next 'didUpdate userLocation' function. We do this by setting shouldUpdateZoomLevel to true.
        // Along with the zoom level, the center should be also set, but it must be set after the initial zoom level is set, 
        // otherwise it wont work.
        if let mapView = mapView, let userLocation = mapView.userLocation, isCoordinateValid(userLocation.coordinate), let userCLLocation = userLocation.location {
            setZoomLevelToMinimumVisibleMeters(minimumVisibleMeters, onLatitude: userLocation.coordinate.latitude, animated: false)
            mapView.setCenter(userLocation.coordinate, zoomLevel: mapView.zoomLevel, direction: mapView.direction, animated: false)
            
            soundsModel.updateLatestParameters(SoundsModel.Parameters(location: userCLLocation))
        } else {
            shouldUpdateZoomLevel = true
        }
        
        updateProximityRingsFrames()
    }
    
    // MARK: - Map
    
    private func initializeMap() {
        mapView?.delegate = self
        mapView?.showsUserLocation = true
        mapView?.allowsRotating = false
        mapView?.allowsTilting = false
        mapView?.allowsZooming = false
        mapView?.allowsScrolling = false
        mapView?.showsUserHeadingIndicator = false
        mapView?.compassView.image = nil
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
    
    // MARK: - Annotations
    
    private func refreshSoundAnnotations() {
        addAnnotations(forSounds: sounds, removeExistingAnnotations: true)
    }
    
    private func addAnnotations(forSounds sounds: [Sound], removeExistingAnnotations: Bool ) {
        
        if removeExistingAnnotations, let existingAnnotations = mapView?.annotations {
            mapView?.removeAnnotations(existingAnnotations)
        }
        
        guard annotationsHidden == false else {
            return
        }
        
        let annotationsToAdd: [SoundAnnotation] = sounds.flatMap { sound in
            let annotation = SoundAnnotation(sound: sound)
            if let latitude = sound.latitude, let longitude = sound.longitude {
                annotation?.distance = distanceInKilometers(fromLatitude: latitude, andLongitude: longitude, to: mapView?.userLocation?.location)
            }
            return annotation
        }
        mapView?.addAnnotations(annotationsToAdd)
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
                
                if soundAnnotation.inRange == false && (soundAnnotation.distanceString != oldDistanceString || soundAnnotation.inRange != oldInRange) {
                    annotationsToRefresh.append(soundAnnotation)
                }
            }
        })
        
        mapView?.removeAnnotations(annotationsToRefresh)
        mapView?.addAnnotations(annotationsToRefresh)
    }
    
    // MARK: - Proximity rings
    
    private func initializeProximityRingsView() {
        proximityRingsView = ProximityRingsView()
        proximityRingsView?.innerRingDistanceInMeters = Int(MainMapViewController.inRangeMetersTreshold/3)
    }
    
    private func updateProximityRingsFrames() {
        guard let mapGLKView = mapGLKView else {
            return
        }
        
        // If the proximity rings view is not yet added to the view hierarchy add it.
        // It will be added to the subview of type GLKView of the mapView, since this is the only way
        // for the proximity rings view to be shown behind the map annotations.
        if let proximityRingsView = proximityRingsView, proximityRingsView.superview == nil {
            mapGLKView.insertSubview(proximityRingsView, at: 0)
        }
        
        let smallerDimensionValue = mapGLKView.bounds.width <= mapGLKView.bounds.height ? mapGLKView.bounds.width : mapGLKView.bounds.height
        let proximityRingsViewDimension = 3/4 * smallerDimensionValue
        
        proximityRingsView?.frame.size = CGSize(width: proximityRingsViewDimension, height: proximityRingsViewDimension)
        proximityRingsView?.center = mapGLKView.center

    }
    
    // MARK: - Heading updating
    
    private func startUpdatingHeading() {
        headingLocationManager.headingFilter = 0.1
        headingLocationManager.startUpdatingHeading()
        headingLocationManager.delegate = self
    }
    
    private func stopUpdatingHeading() {
        headingLocationManager.stopUpdatingHeading()
    }
    
    // MARK: - Actions
    
    @IBAction private func soundsListButtonPressed(_ sender: Any) {
        setContentControllerViewController(withMenuContent: .soundsList)
    }
    
    @IBAction private func filterButtonPressed(_ sender: Any) {
        setContentControllerViewController(withMenuContent: .filter)
    }
    
    // MARK: - Recording
    
    @objc private func onLongPress(recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .began: startRecording()
        case .cancelled, .ended: stopRecording()
        default: break
        }
    }
    
    @IBAction private func recordButtonPressed(_ sender: UIButton) {
        RecorderAndPlayer.shared.isRecording ? stopRecording() : startRecording()
    }
    
    private func startRecording() {
        print("💬 recording")
        updateRecordButton(recording: true)
        RecorderAndPlayer.shared.startRecording()
    }
    
    private func stopRecording() {
        print("💬 recording stopped")
        let path = RecorderAndPlayer.shared.stopRecording()
        progressBarView?.startProgress()
        soundsModel.uploadSound(atFilePath: path)
    }
    
    // MARK: - UI updates
    
    private func updateRecordButton(recording: Bool, animated: Bool = true) {
        guard let imageView = recordImageView else {
            return
        }
        
        let duration: TimeInterval = 0.25
        
        UIView.animate(withDuration: duration) {
            imageView.transform = recording ? CGAffineTransform(scaleX: 1.25, y: 1.25) : CGAffineTransform.identity
        }
        
        UIView.transition(with: imageView,
                          duration: animated ? duration : 0.0,
                          options: [.curveEaseInOut, .transitionCrossDissolve],
                          animations: {
                            self.recordImageView?.image = recording ? #imageLiteral(resourceName: "records-button-recording-icon") : #imageLiteral(resourceName: "record-button-icon")
                          },
                          completion: nil)
    }
    
    private func setListenViewHidden(_ hidden: Bool) {
        listenView?.kamino.animateHiden(hidden: hidden, duration: listenViewHiddenAnimationDuration)
    }
    
    // MARK: - Convenince
    
    private func isCoordinateValid(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.latitude >= -90 && coordinate.latitude <= 90 && coordinate.longitude >= -180 && coordinate.longitude <= 180
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
        guard let userLocation = userLocation, let userCLLocation = userLocation.location, isCoordinateValid(userLocation.coordinate) else {
            return
        }
        
        if shouldUpdateZoomLevel {
            // Zoom level could not be updated during 'viewDidLayoutSubviews' (indicated by the 'shouldUpdateZoomLevel' property), so we have to do it here
            setZoomLevelToMinimumVisibleMeters(minimumVisibleMeters, onLatitude: userLocation.coordinate.latitude, animated: false)
            shouldUpdateZoomLevel = false
            
            soundsModel.updateLatestParameters(SoundsModel.Parameters(location: userCLLocation))
        }
        mapView.setCenter(userLocation.coordinate, zoomLevel: mapView.zoomLevel, direction: mapView.direction, animated: false)
        
        updateVisibleAnnotationViewsIfNecessary()
    }
    
    func mapView(_ mapView: MGLMapView, didAdd annotationViews: [MGLAnnotationView]) {
        // Each time an annotation is added to the map, make sure that the proximity ring views are behind the annotations.
        // So simply send each proximity ring view to the back.
        if annotationViews.isEmpty == false, let mapGLKView = mapGLKView, let proximityRingsView = proximityRingsView {
            mapGLKView.sendSubview(toBack: proximityRingsView)
        }
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        if let soundAnnotation = annotation as? SoundAnnotation {
            
            // TODO: Change this so it wont be hardcoded. It should probably be relative to the map size.
            let annotationViewSize = CGSize(width: 100, height: 110)
            let reuseIdentifier = "reusableSoundprintsAnnotationView"
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? SoundAnnotationView
            
            if annotationView == nil {
                annotationView = SoundAnnotationView(reuseIdentifier: reuseIdentifier, frame: CGRect(origin: .zero, size: annotationViewSize))
            }
            annotationView?.injectProperties(fromSoundAnnotation: soundAnnotation)
            
            annotationView?.setContentHidden(false, animated: true)
            
            return annotationView
            
        } else if annotation is MGLUserLocation {
            
            // TODO: Change this so it wont be hardcoded. It should probably be relative to the map size.
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
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        guard let soundAnnotation = annotation as? SoundAnnotation, let sound = soundAnnotation.sound, soundAnnotation.inRange, !RecorderAndPlayer.shared.isPlaying, !RecorderAndPlayer.shared.isRecording else {
            return
        }
        
        playSound(sound)
    }
    
}

// MARK: - SoundsModelDelegate

extension MainMapViewController: SoundsModelDelegate {    
    
    func soundsModel(_ sender: SoundsModel, fetchedNewSoundsPage newSoundsPage: [Sound], isReload: Bool) {
        if isReload {
            sounds = newSoundsPage
            refreshSoundAnnotations()
        } else {
            sounds.append(contentsOf: newSoundsPage)
            addAnnotations(forSounds: newSoundsPage, removeExistingAnnotations: false)
        }
        
        // If we got some results and the farthest result distance is less than max map radius, try to fetch some more.
        if newSoundsPage.isEmpty == false && soundsModel.currentFartherstSoundDistance < maximumVisibleRadius ?? 0 {
            soundsModel.fetchAndAppendNewSoundsPage()
        }
    }
    
    func soundModelCouldNotUploadSound(sender: SoundsModel) {
        // TODO: alert user
        self.progressBarView?.cancelProgress()
    }
    
    func soundModel(_ sender: SoundsModel, uploadedSound: Sound, whichWasInsertedAtIndex insertedAtIndex: Int) {
        self.progressBarView?.finishProgress(nil)
        addAnnotations(forSounds: [uploadedSound], removeExistingAnnotations: false)
    }
    
}

// MARK: - Heading CLLocationManagerDelegate

extension MainMapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // We want the direction of the map to change based on the device heading. This means that the map will rotate with the user.
        // If possible use the true north heading (valid if positive), otherwise use the magnetic north heading, which should be good
        // enough, if the true heading is not available for some reason.
        mapView?.direction = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    }

    
}

// MARK: - SoundsListViewControllerDelegate

extension MainMapViewController: SoundsListViewControllerDelegate {
    
    func soundsListViewControllerShouldBeDismissed(sender: SoundsListViewController) {
        clearContentController()
    }
    
    func soundsListViewController(_ sender: SoundsListViewController, requestsToPlaySound soundToPlay: Sound) {
        clearContentController()
        playSound(soundToPlay)
    }
    
}

// MARK: - FilterViewControllerDelegate

extension MainMapViewController: FilterViewControllerDelegate {
    
    func filterViewControllerShouldBeDismissed(sender: FilterViewController) {
        clearContentController()
    }
    
}

// MARK: - ListenViewDelegate

extension MainMapViewController: ListenViewDelegate {
    
    func listenViewShouldClose(sender: ListenView) {
        RecorderAndPlayer.shared.stopPlaying()
    }
    
}

// MARK: - RecorderAndPlayerDelegate

extension MainMapViewController: RecorderAndPlayerDelegate {
    
    func recorderAndPlayerStoppedPlaying(sender: RecorderAndPlayer) {
        setListenViewHidden(true)
        
        if let currentlyPlayedSoundAnnotation = currentlyPlayedSoundAnnotation {
            mapView?.addAnnotation(currentlyPlayedSoundAnnotation)
        }
    }
    
    func recorderAndPlayerStoppedRecording(sender: RecorderAndPlayer) {
        updateRecordButton(recording: false)
    }
    
    func recorderAndPlayer(_ sender: RecorderAndPlayer, updatedPlayingProgress playingProgress: CGFloat) {
        listenView?.progress = playingProgress
    }
    
}

// MARK: - Menu controlls

private extension MainMapViewController {
    
    enum MenuContent {
        case soundsList
        case filter
    }
    
    static let contentHidingAnimationDuration: Double = 0.4
    
    func setContentControllerViewController(withMenuContent menuContent: MenuContent) {
        switch menuContent {
        case .soundsList:
            let soundsList = R.storyboard.soundsList.soundsListViewController()!
            soundsList.soundsModel = soundsModel
            soundsList.delegate = self
            contentControllerView?.setViewController(controller: soundsList, animationStyle: .fade)
        case .filter:
            let filter = R.storyboard.filter.filterViewController()!
            filter.delegate = self
            contentControllerView?.setViewController(controller: filter, animationStyle: .fade)
        }
        
        RecorderAndPlayer.shared.stopPlaying()
        setMainMapComponentsHidden(true)
    }
    
    func clearContentController() {
        soundsModel.setState(.map)
        
        contentControllerView?.setViewController(controller: nil, animationStyle: .fade)
        setMainMapComponentsHidden(false)
    }
    
    private func setMainMapComponentsHidden(_ hidden: Bool) {
        menuContainerView?.kamino.animateHiden(hidden: hidden, duration: MainMapViewController.contentHidingAnimationDuration)
        proximityRingsView?.kamino.animateHiden(hidden: hidden, duration: MainMapViewController.contentHidingAnimationDuration)
        
        // The listen view should be only hidden and not shown. So changing its hidden state will happen only when content controller view is shown.
        if hidden {
            listenView?.kamino.animateHiden(hidden: hidden, duration: MainMapViewController.contentHidingAnimationDuration)
        }
        annotationsHidden = hidden
    }
    
}

// MARK: - Sound playing

private extension MainMapViewController {
    
    func playSound(_ sound: Sound) {
        
        listenView?.progress = 0
        
        if let existingAnnotations = mapView?.annotations, let soundAnnotation = existingAnnotations.flatMap({ $0 as? SoundAnnotation }).first(where: { $0.sound === sound }) {
            currentlyPlayedSoundAnnotation = soundAnnotation
            mapView?.removeAnnotation(soundAnnotation)
        }
        
        listenView?.profileImageView?.image = nil
        listenView?.profileImageView?.kf.setImage(with: sound.userProfileImageUrl)
        setListenViewHidden(false)
        
        sound.getResourceURL { resourceURL, error in
            if let resourceURL = resourceURL {
                RecorderAndPlayer.shared.playFile(withRemoteURL: resourceURL)
            } else {
                // TODO: Handle error
                self.setListenViewHidden(true)
            }
        }
    }
    
}
