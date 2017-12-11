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
    
    // MARK: - Variables
    
    weak var delegate: SoundsListCellDelegate?
    
    var sound: Sound? {
        didSet {
            updateContent(withSound: sound)
        }
    }
    
    // MARK: - UIView lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateFramesAndBorders()
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
        delegate?.soundListCell(self, requestsToPlaySound: sound)
    }

}
