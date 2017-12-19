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
    
    private lazy var inRangeMetersTreshold: Double = {
        self.initialMinimumVisibleMeters * (3/8)
    }()
    
    private var sounds: [Sound] = []
    
    private var currentMinimumVisibleMeters: Double? {
        guard let mapView = mapView, let latitude = mapView.userLocation?.coordinate.latitude else {
            return nil
        }
        
        return visibleMetersForZoomLevel(mapView.zoomLevel, onLatitude: latitude, forMapView: mapView)
    }
    private var maximumVisibleRadius: Double? {
        guard let mapView = mapView, let minimumVisibleMeters = currentMinimumVisibleMeters else {
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
    
    private var selectedUserTrackingMode: MGLUserTrackingMode = .followWithHeading
    
    private var initialZoomLevel: Double?
    private var initialCenterSet = false
    private var shouldInitializeZoom: Bool = false

    // MARK: - Constants
    
    private let listenViewHiddenAnimationDuration: Double = 1
    private let earthCircumference: Double = 40075000.0
    
    private let initialMinimumVisibleMeters: Double = 1200
    private let maximumVisibleMeters: Double? = 2400
    private let minimumVisibleMeters: Double? = nil
    
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
        
        RecorderAndPlayer.shared.requestPermission { granted in
            if !granted { // cant record
                // TODO: alert user
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Try to initialize zoom when layout is set. If it can't be initialized, 'shouldInitializeZoom' will
        // be marked with true and the zoom will be initialized in the next location update method in map view delegate.
        initializeZoom()
        updateProximityRingsFrames()
    }
    
    // MARK: - Map
    
    private func initializeMap() {
        mapView?.delegate = self
        mapView?.showsUserLocation = true
        mapView?.allowsRotating = false
        mapView?.allowsTilting = false
        mapView?.allowsZooming = true
        mapView?.allowsScrolling = false
        mapView?.showsUserHeadingIndicator = false
        mapView?.userTrackingMode = selectedUserTrackingMode
        mapView?.compassView.image = nil
    }
    
    /// Initializes zoom. 
    /// It does it by first setting the zoom level depending on the 'initialMinimumVisibleMeters' property.
    /// Then if 'maximalVisibleMeters' is set, it sets the minimum zoom level.
    /// Lastly if 'maximalVisibleMeters' is set, it sets the maximum zoom level.
    ///
    /// This function should be called after the layout is set, since the dimension of the map view is used.
    private func initializeZoom() {
        guard initialZoomLevel == nil else {
            return
        }
        guard let mapView = mapView, let latitude = mapView.userLocation?.coordinate.latitude else {
            shouldInitializeZoom = true
            return
        }
        
        if let maximumVisibleMeters = maximumVisibleMeters {
            let minimumZoomLevel = zoomLevelForMinimumVisibleMeters(maximumVisibleMeters, onLatitude: latitude, forMapView: mapView)
            mapView.minimumZoomLevel = minimumZoomLevel
        }
        if let minimumVisibleMeters = minimumVisibleMeters {
            let maximumZoomLevel = zoomLevelForMinimumVisibleMeters(minimumVisibleMeters, onLatitude: latitude, forMapView: mapView)
            mapView.maximumZoomLevel = maximumZoomLevel
        }
        
        let zoomLevel = zoomLevelForMinimumVisibleMeters(initialMinimumVisibleMeters, onLatitude: latitude, forMapView: mapView)
        mapView.setZoomLevel(zoomLevel, animated: false)
        
        self.initialZoomLevel = zoomLevel
        shouldInitializeZoom = false
        
        updateUserTrackingMode()
    }
    
    // MARK: - Zoom level calculation helpers
    
    private func zoomLevelForMinimumVisibleMeters(_ meters: Double, onLatitude latitude: Double, forMapView mapView: MGLMapView) -> Double {
        // Now we have to calculate the zoom level so that at least 'meters' meters are in the smaller dimension of the map.
        // How to do this can be found here: http://wiki.openstreetmap.org/wiki/Zoom_levels
        let mapViewMinimumDimension = mapView.bounds.width < mapView.bounds.height ? Double(mapView.bounds.width) : Double(mapView.bounds.height)
        let distancePerPixel = meters/mapViewMinimumDimension
        let latitudeInRadians = latitude * (.pi/180)
        // Subtract 9 instead of 8, because Mapbox's implementation works with 512x512 pixel tiles and the zoom level from 
        // the link above is true for 256x256 pixel tiles. This means that the zoom level will be off by one and we simply subtract one more.
        let zoomLevel = log2((earthCircumference*cos(latitudeInRadians))/distancePerPixel) - 9
        
        return zoomLevel
    }
    
    private func visibleMetersForZoomLevel(_ zoomLevel: Double, onLatitude latitude: Double, forMapView mapView: MGLMapView) -> Double {
        // This procedure is the same as the on in 'zoomLevelForMinimumVisibleMeters', just that it is the other way around.
        // Here we are trying to obtain the visible meters from zoom level.
        let mapViewMinimumDimension = mapView.bounds.width < mapView.bounds.height ? Double(mapView.bounds.width) : Double(mapView.bounds.height)
        let latitudeInRadians = latitude * (.pi/180)
        let distancePerPixel = earthCircumference*(cos(latitudeInRadians)) / (pow(2, mapView.zoomLevel+9))
        
        return distancePerPixel*mapViewMinimumDimension
    }
    
    // MARK: - User tracking
    
    private func updateUserTrackingMode() {
        if mapView?.userTrackingMode != selectedUserTrackingMode {
            mapView?.userTrackingMode = selectedUserTrackingMode
        }
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
            if let userCLLocation = mapView?.userLocation?.location {
                annotation?.updateDistanceInfo(withUserLocation: userCLLocation, andInRangeTreshold: inRangeMetersTreshold)
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
                
                soundAnnotation.updateDistanceInfo(withUserLocation: userCLLocation, andInRangeTreshold: inRangeMetersTreshold)
                
                let newDistanceString = soundAnnotation.distanceString
                let newInRange = soundAnnotation.inRange
                
                if (oldInRange != newInRange) || (newInRange == false && oldDistanceString != newDistanceString) {
                    annotationsToRefresh.append(soundAnnotation)
                }
            }
        })
        
        if annotationsToRefresh.isEmpty == false {
            mapView?.removeAnnotations(annotationsToRefresh)
            mapView?.addAnnotations(annotationsToRefresh)
        }
    }
    
    // MARK: - Proximity rings
    
    private func initializeProximityRingsView() {
        proximityRingsView = ProximityRingsView()
        proximityRingsView?.innerRingDistanceInMeters = Int(inRangeMetersTreshold/3)
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
        let (path, error) = RecorderAndPlayer.shared.stopRecording()
        
        if let path = path, error == nil {
            progressBarView?.startProgress()
            soundsModel.uploadSound(atFilePath: path)
        } else if let error = error {
            switch error {
            case .notRecording: Alert.showAlert(title: "Cannot stop recording", message: "Recording not in progress.", inController: self)
            case .recordingTooShort: Alert.showAlert(title: "Cannot process sound", message: "Recording is too short. It has to be at lease 1 second long.", inController: self) 
            }
        } else {
            Alert.showAlert(title: "Cannot stop recording", inController: self)
        }
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
    
    private func roundTo(multipleOf: Int, value: Double) -> Int {
        let fractionNum = Double(value) / Double(multipleOf)
        let roundedNum = max(1, Int(round(fractionNum)))
        return roundedNum * multipleOf
    }

}

// MARK: - MGLMapViewDelegate

extension MainMapViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        guard let userLocation = userLocation, let userCLLocation = userLocation.location, isCoordinateValid(userLocation.coordinate) else {
            return
        }
        
        soundsModel.updateLatestParameters(SoundsModel.Parameters(location: userCLLocation))
        
        if shouldInitializeZoom {
            initializeZoom()
        }
        
        // Center should be set only once and only after the initial zoom has been set (there are problems otherwise).
        if let initialZoomLevel = initialZoomLevel, initialCenterSet == false {
            mapView.setCenter(userLocation.coordinate, zoomLevel: initialZoomLevel, direction: mapView.direction, animated: false)
            initialCenterSet = true
        }
        updateUserTrackingMode()
        
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
    
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        if let minimumVisibleMeters = currentMinimumVisibleMeters {
            inRangeMetersTreshold = minimumVisibleMeters * (3/8)
            proximityRingsView?.innerRingDistanceInMeters = roundTo(multipleOf: 5, value: minimumVisibleMeters/8)
        }
        updateVisibleAnnotationViewsIfNecessary()
        updateUserTrackingMode()
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
    
    func soundModel(_ sender: SoundsModel, uploadedSound: Sound, whichWasInsertedAtIndex insertedAtIndex: Int?) {
        if let insertedAtIndex = insertedAtIndex {
            sounds.insert(uploadedSound, at: insertedAtIndex)
            addAnnotations(forSounds: [uploadedSound], removeExistingAnnotations: false)
        }
        
        self.progressBarView?.finishProgress(nil)
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
        
        // Set the RecorderAndPlayer delegate here because it could be set in SoundsListViewController
        RecorderAndPlayer.shared.delegate = self
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
