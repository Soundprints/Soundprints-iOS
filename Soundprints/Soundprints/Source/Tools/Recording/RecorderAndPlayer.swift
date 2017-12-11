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
        
        NotificationCenter.default.addObserver(forName: .AVAudioSessionInterruption, object: nil, queue: nil) { [unowned self] notification in
            print("Audio session interrupted!")
            self.stop()
            if self.isRecording { self.delegate?.recorderAndPlayerStoppedPlaying(sender: self) }
            if self.isPlaying { self.delegate?.recorderAndPlayerStoppedRecording(sender: self) }
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
        let path = recorder?.url.absoluteString ?? ""
        isRecording = false
        recorder?.stop()
        recorder = nil
        try? session.setActive(false)
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
        if isPlaying {
            stop()
        }
        
        progressTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(progressTimerFired), userInfo: nil, repeats: true)
        
        isPlaying = true
        initializePlayer(withRemoteURL: remoteURL)
        player?.play()
    }
    
    func stopPlaying() {
        progressTimer?.invalidate()
        progressTimer = nil
        
        isPlaying = false
        player?.pause()
        player = nil
        try? session.setActive(false)
        
        delegate?.recorderAndPlayerStoppedPlaying(sender: self)
    }
    
    private func initializePlayer(withRemoteURL remoteURL: URL) {
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
            try session.setActive(true)
            
//            let playerItem = AVPlayerItem(asset: AVAsset(url: remoteURL))
            let playerItem = AVPlayerItem(asset: AVAsset(url: URL(string: "https://storage.googleapis.com/soundprints-sounds-development/recording2.aac")!))
            player = AVPlayer(playerItem: playerItem)
            player?.volume = 1
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Timer
    
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
        delegate?.recorderAndPlayerStoppedRecording(sender: self)
    }
    
}
