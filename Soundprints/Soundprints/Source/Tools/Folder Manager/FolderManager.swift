//
//  FolderManager.swift
//  OpusDemo
//
//  Created by Peter Korosec on 01/12/2017.
//  Copyright © 2017 Kamino. All rights reserved.
//

import Foundation

class FolderManager {
    
    // MARK: - Properties
    
    private(set) var folder: Folder
    
    private var folderPath: URL? {
        guard let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return nil
        }
        
        let url = URL(fileURLWithPath: documents)
        return url.appendingPathComponent(folder.rawValue)
    }
    
    // MARK: - Init
    
    init(folder: Folder) {
        self.folder = folder
        createFolder()
    }
    
    // MARK: - Paths
    
    private func directoryExistsAt(path: String) -> Bool {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        
        if fileManager.fileExists(atPath: path, isDirectory:&isDir) {
            if isDir.boolValue {
                return true
            } else {
                return false
            }
            
        } else {
            return false
        }
    }
    
    func fileExistsAt(path: String) -> Bool {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        
        if fileManager.fileExists(atPath: path, isDirectory:&isDir) {
            return true
            
        } else {
            return false
        }
    }
    
    // MARK: - Folder creation
    
    private func createFolder() {
        guard let folderPath = folderPath else {
            print("Error creating folder path.")
            return
        }
        
        guard !directoryExistsAt(path: folderPath.path) else {
            return
        }

        do {
            try FileManager.default.createDirectory(atPath: folderPath.path, withIntermediateDirectories: false, attributes: nil)
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Files in folder
    
    func numberOfFilesInFolder() -> Int {
        guard let folderPath = folderPath else {
            print("Error locating folder.")
            return 0
        }
        
        do  {
            let contents = try FileManager.default.contentsOfDirectory(atPath: folderPath.path)
            return contents.count
            
        } catch {
            print("Error getting contents.")
            return 0
        }
    }
    
    func getNewFilePath() -> String? {
        guard let folderPath = folderPath else {
            return nil
        }
        
        switch folder {
        case .recordings: return folderPath.appendingPathComponent(folder.fileName + String(numberOfFilesInFolder() + 1)).path
        }
        
    }
    
    func filePathNumber(_ number: Int) -> String? {
        guard let folderPath = folderPath else {
            return nil
        }
        return folderPath.appendingPathComponent(folder.fileName + String(number)).path
    }
    
    // MARK: - Clear folder
    
    func clearFolder() {
        guard let folderPath = folderPath else {
            return
        }
        
        let manager = FileManager.default
        
        do  {
            let contents = try manager.contentsOfDirectory(atPath: folderPath.path)
            for path in contents {
                let fullPath = folderPath.appendingPathComponent(path)
                try manager.removeItem(atPath: fullPath.path)
            }
            
        } catch {
            print("Error clearing folder.")
        }
    }
    
}

// MARK: - Folder

extension FolderManager {
    
    enum Folder: String {
        case recordings = "recordings"
        
        var fileName: String {
            switch self {
            case .recordings: return "recording"
            }
        }
    }
    
}
