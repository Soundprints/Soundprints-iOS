//
//  SoundsListCell.swift
//  Soundprints
//
//  Created by Svit Zebec on 06/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import UIKit

// MARK: - SoundsListCellDelegate 

protocol SoundsListCellDelegate: class {
    
    func soundListCell(_ sender: SoundsListCell, requestsToPlaySound soundToPlay: Sound?)
    
}

// MARK: - SoundsListCell

class SoundsListCell: UITableViewCell {

    // MARK: - Outlets
    
    @IBOutlet private weak var contentContainerView: UIView?
    @IBOutlet private weak var profileImageView: UIImageView?
    @IBOutlet private weak var playButton: UIButton?
    @IBOutlet private weak var playButtonImageView: UIImageView?
    @IBOutlet private weak var userDisplayNameLabel: UILabel?
    @IBOutlet private weak var durationAndDistanceLabel: UILabel?
    @IBOutlet private weak var timestampLabel: UILabel?
    @IBOutlet private weak var listenView: ListenView?
    
    // MARK: - Variables
    
    weak var delegate: SoundsListCellDelegate?
    
    var sound: Sound? {
        didSet {
            updateContent(withSound: sound)
        }
    }
    
    private var soundPlaying = false
    
    // MARK: - Constants
    
    private let listenViewHiddenAnimationDuration: Double = 1
    
    // MARK: - UIView lifecycle
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        listenView?.delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateFramesAndBorders()
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        if soundPlaying {
            self.onStopPlaying()
            DispatchQueue.global().async {
                RecorderAndPlayer.shared.stopPlaying()
            }
        }
        if RecorderAndPlayer.shared.delegate === self {
            RecorderAndPlayer.shared.delegate = nil
        }
    }
    
    // MARK: - Content updating
    
    private func updateContent(withSound sound: Sound?) {
        if let profileImageUrl = sound?.userProfileImageUrl {
            profileImageView?.kf.setImage(with: profileImageUrl)
        } else {
            profileImageView?.image = nil
        }
        userDisplayNameLabel?.text = sound?.userDisplayName
        durationAndDistanceLabel?.text = sound?.durationAndDistanceDisplayString()
        timestampLabel?.text = {
            guard let submissionIntervalString = sound?.timeSinceSubmissionDisplayString() else {
                return nil
            }
            return "left \(submissionIntervalString) ago"
        }()
    }
    
    // MARK: - Frames and borders updating
    
    private func updateFramesAndBorders() {
        profileImageView?.clipsToBounds = true
        if let profileImageView = profileImageView {
            profileImageView.layer.cornerRadius = profileImageView.bounds.height/2
        }
        contentContainerView?.clipsToBounds = true
        contentContainerView?.layer.cornerRadius = 4
    }
    
    // MARK: - Actions
    
    @IBAction private func playButtonPressed(_ sender: Any) {
        playSound()
    }
    
    // MARK: - Listen View
    
    private func setListenViewHidden(_ hidden: Bool) {
        listenView?.kamino.animateHiden(hidden: hidden, duration: listenViewHiddenAnimationDuration)
    }
    
    // MARK: - Play button
    
    private func setPlayButtonEnabled(_ enabled: Bool) {
        playButton?.isEnabled = enabled
        UIView.animate(withDuration: listenViewHiddenAnimationDuration) { 
            self.playButtonImageView?.alpha = enabled ? 1 : 0.3
        }
    }
    
    // MARK: - Convenience
    
    private func onStopPlaying() {
        soundPlaying = false
        setListenViewHidden(true)
        setPlayButtonEnabled(true)
    }

}

// MARK: - Sound playing

private extension SoundsListCell {
    
    func playSound() {
        guard let sound = sound else {
            return
        }
        
        listenView?.progressColor = ColorPalette.soundsList.blue
        
        RecorderAndPlayer.shared.stopPlaying()
        
        listenView?.progress = 0
        
        setListenViewHidden(false)
        setPlayButtonEnabled(false)
        
        sound.getResourceURL { resourceURL, error in
            if let resourceURL = resourceURL {
                self.soundPlaying = true
                RecorderAndPlayer.shared.delegate = self
                RecorderAndPlayer.shared.playFile(withRemoteURL: resourceURL)
            } else {
                // TODO: Handle error
                self.setListenViewHidden(true)
                self.setPlayButtonEnabled(true)
            }
        }
    }
    
}


// MARK: - ListenViewDelegate

extension SoundsListCell: ListenViewDelegate {
    
    func listenViewShouldClose(sender: ListenView) {
        RecorderAndPlayer.shared.stopPlaying()
    }
    
}

// MARK: - RecorderAndPlayerDelegate

extension SoundsListCell: RecorderAndPlayerDelegate {
    
    func recorderAndPlayerStoppedPlaying(sender: RecorderAndPlayer) {
        onStopPlaying()
    }
    
    func recorderAndPlayerStoppedRecording(sender: RecorderAndPlayer) {
        // No recording here, so leave empty
    }
    
    func recorderAndPlayer(_ sender: RecorderAndPlayer, updatedPlayingProgress playingProgress: CGFloat) {
        listenView?.progress = playingProgress
    }
    
}
