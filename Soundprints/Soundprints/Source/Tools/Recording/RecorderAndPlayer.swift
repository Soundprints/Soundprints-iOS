//
//  Recorder.swift
//  OpusDemo
//
//  Created by Peter Korosec on 01/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation
import AVFoundation

// MARK: - RecorderDelegate

protocol RecorderAndPlayerDelegate: class {
    
    func recorderAndPlayer(_ sender: RecorderAndPlayer, updatedPlayingProgress playingProgress: CGFloat)
    func recorderAndPlayerStoppedPlaying(sender: RecorderAndPlayer)
    func recorderAndPlayerStoppedRecording(sender: RecorderAndPlayer)
    
}

// MARK: - Recorder

class RecorderAndPlayer: NSObject {
    
    // MARK: - Static
    
    static let shared = RecorderAndPlayer()
    
    // MARK: - Properties
    
    weak var delegate: RecorderAndPlayerDelegate?
    
    private let session = AVAudioSession.sharedInstance()
    
    private let folderManager = FolderManager(folder: .recordings)
    
    private var recorder: AVAudioRecorder?
    private var player: AVPlayer?
    
    private(set) var isRecording: Bool = false
    private(set) var isPlaying: Bool = false
    
    private var progressTimer: Timer?
    
    // MARK: - Init
    
    override init() {
        super.init()
        
        // clear recordings folder
        FolderManager(folder: .recordings).clearFolder()
        
        NotificationCenter.default.addObserver(forName: .AVAudioSessionInterruption, object: nil, queue: nil) { [unowned self] notification in
            print("Audio session interrupted!")
            self.stop()
        }
    }
    
    // MARK: - Recording
    
    func startRecording() {
        stop()
        
        isRecording = true
        initializeRecorder()
        recorder?.record()
    }
    
    /// Stops audio recording, returns path to recorded audio file
    @discardableResult func stopRecording() -> String {
        guard isRecording else {
            return ""
        }
        
        let path = recorder?.url.path ?? ""
        isRecording = false
        recorder?.stop()
        recorder = nil
        
        if !isPlaying {
            try? session.setActive(false)
        }
        
        delegate?.recorderAndPlayerStoppedRecording(sender: self)
        return path
    }
    
    private func initializeRecorder() {
        guard let path = folderManager.getNewFilePath() else {
            print("Error creating file path.")
            return
        }
        
        let settings: [String: Any] = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                                       AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        
        do {
            try session.setCategory(AVAudioSessionCategoryRecord)
            try session.setActive(true)
            recorder = try AVAudioRecorder(url: URL(fileURLWithPath: path), settings: settings)
            recorder?.delegate = self
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Playback
    
    func playFile(withRemoteURL remoteURL: URL) {
        stop()
        
        progressTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(progressTimerFired), userInfo: nil, repeats: true)
        
        isPlaying = true
        initializePlayer(withRemoteURL: remoteURL)
        player?.play()
    }
    
    func stopPlaying() {
        guard isPlaying else {
            return
        }
        
        delegate?.recorderAndPlayerStoppedPlaying(sender: self)
        
        isPlaying = false
        player?.pause()
        player = nil
        
        progressTimer?.invalidate()
        progressTimer = nil
        
        if !isRecording {
            try? session.setActive(false)
        }
    }
    
    private func initializePlayer(withRemoteURL remoteURL: URL) {
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
            try session.setActive(true)
            let playerItem = AVPlayerItem(asset: AVAsset(url: remoteURL))
            player = AVPlayer(playerItem: playerItem)
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Progress Timer
    
    @objc private func progressTimerFired() {
        guard isPlaying, let player = player, let playerItem = player.currentItem else {
            stopPlaying()
            return
        }
        
        let progress = CGFloat(playerItem.currentTime().seconds/playerItem.duration.seconds)
        
        guard progress.isNaN == false else {
            return
        }
        
        delegate?.recorderAndPlayer(self, updatedPlayingProgress: progress)
        
        if progress >= 1 {
            stopPlaying()
        }
    }
    
    // MARK: - Permissions
    
    func requestPermission(callback: @escaping (_ granted: Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            callback(granted)
        }
    }
    
    // MARK: Helpers
    
    private func stop() {
        stopRecording()
        stopPlaying()
    }
    
}

// MARK: - AVAudioRecorderDelegate

extension RecorderAndPlayer: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        stopRecording()
    }
    
}
