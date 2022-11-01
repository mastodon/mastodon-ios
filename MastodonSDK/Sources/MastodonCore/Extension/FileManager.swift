//
//  FileManager.swift
//  
//
//  Created by MainasuK on 2022-1-15.
//

import os.log
import Foundation

extension FileManager {
    static let logger = Logger(subsystem: "FileManager", category: "File")
    
    public func createTemporaryFileURL(
        filename: String,
        pathExtension: String
    ) throws -> URL {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = tempDirectoryURL
            .appendingPathComponent(filename)
            .appendingPathExtension(pathExtension)
        try FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)

        Self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): create temporary file at: \(fileURL.debugDescription)")
        
        return fileURL
    }
}
