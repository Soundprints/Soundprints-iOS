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

protocol RecorderDelegate: class {
    
    func recorderStoppedPlaying(sender: Recorder)
    func recorderStoppedRecording(sender: Recorder)
    
}

// MARK: - Recorder

class Recorder: NSObject {
    
    // MARK: - Static
    
    static let shared = Recorder()
    
    // MARK: - Properties
    
    weak var delegate: RecorderDelegate?
    
    private let session = AVAudioSession.sharedInstance()
    
    private let folderManager = FolderManager(folder: .recordings)
    
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    
    private(set) var isRecording: Bool = false
    private(set) var isPlaying: Bool = false
    
    // MARK: - Init
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(forName: .AVAudioSessionInterruption, object: nil, queue: nil) { [unowned self] notification in
            print("Audio session interrupted!")
            self.stop()
            if self.isRecording { self.delegate?.recorderStoppedPlaying(sender: self) }
            if self.isPlaying { self.delegate?.recorderStoppedRecording(sender: self) }
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
    
    func playFile(path: String) {
        stop()
        
        isPlaying = true
        initializePlayer(path: path)
        player?.play()
    }
    
    func stopPlaying() {
        isPlaying = false
        player?.stop()
        player = nil
        try? session.setActive(false)
    }
    
    private func initializePlayer(path: String) {
        let url = URL(fileURLWithPath: path)
        
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
            try session.setActive(true)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp4.rawValue)
            player?.prepareToPlay()
            player?.delegate = self
            
        } catch {
            print(error.localizedDescription)
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

// MARK: - AVAudioPlayerDelegate

extension Recorder: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlaying()
        delegate?.recorderStoppedPlaying(sender: self)
    }
    
}

// MARK: - AVAudioRecorderDelegate

extension Recorder: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        stopRecording()
        delegate?.recorderStoppedRecording(sender: self)
    }
    
}
