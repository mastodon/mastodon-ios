//
//  FileManager.swift
//  
//
//  Created by MainasuK on 2022-1-15.
//

import Foundation

extension FileManager {

    public func createTemporaryFileURL(
        filename: String,
        pathExtension: String
    ) throws -> URL {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = tempDirectoryURL
            .appendingPathComponent(filename)
            .appendingPathExtension(pathExtension)
        try FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        
        return fileURL
    }
}
