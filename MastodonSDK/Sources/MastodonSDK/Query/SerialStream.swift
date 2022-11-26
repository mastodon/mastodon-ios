//
//  SerialStream.swift
//  
//
//  Created by MainasuK Cirno on 2021-5-28.
//

import os.log
import Foundation
import Combine

// ref:
// - https://developer.apple.com/documentation/foundation/url_loading_system/uploading_streams_of_data#3037342
// - https://forums.swift.org/t/extension-write-to-outputstream/42817/4
// - https://gist.github.com/khanlou/b5e07f963bedcb6e0fcc5387b46991c3

final class SerialStream: NSObject {
    
    let logger = Logger(subsystem: "SerialStream", category: "Stream")
    
    public let progress = Progress()
    var writingTimerSubscriber: AnyCancellable?

    // serial stream source
    private var streams: [InputStream]
    private var currentStreamIndex = 0
    
    private static let bufferSize = 5 * 1024 * 1024    // 5MiB
    
    private var buffer: UnsafeMutablePointer<UInt8>
    private var canWrite = false
    
    private let workingQueue = DispatchQueue(label: "org.joinmastodon.app.SerialStream.\(UUID().uuidString)")

    // bound pair stream
    private(set) lazy var boundStreams: Streams = {
        var inputStream: InputStream?
        var outputStream: OutputStream?
        Stream.getBoundStreams(withBufferSize: SerialStream.bufferSize, inputStream: &inputStream, outputStream: &outputStream)
        guard let input = inputStream, let output = outputStream else {
            fatalError()
        }
        
        output.delegate = self
        output.schedule(in: .current, forMode: .default)
        output.open()
        
        return Streams(input: input, output: output)
    }()

    init(streams: [InputStream]) {
        self.streams = streams
        self.buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: SerialStream.bufferSize)
        self.buffer.initialize(repeating: 0, count: SerialStream.bufferSize)
        super.init()
        
        // Stream worker
        writingTimerSubscriber = Timer.publish(every: 0.5, on: .current, in: .default)
            .autoconnect()
            .receive(on: workingQueue)
            .sink { [weak self] timer in
                guard let self = self else { return }
                guard self.canWrite else { return }
                os_log(.debug, "%{public}s[%{public}ld], %{public}s: writing…", ((#file as NSString).lastPathComponent), #line, #function)
                
                guard self.currentStreamIndex < self.streams.count else {
                    self.boundStreams.output.close()
                    self.writingTimerSubscriber = nil   // cancel timer after task completed
                    return
                }
                
                var readBytesCount = 0
                defer {
                    var baseAddress = 0
                    var remainsBytes = readBytesCount
                    while remainsBytes > 0 {
                        let writeResult = self.boundStreams.output.write(&self.buffer[baseAddress], maxLength: remainsBytes)
                        baseAddress += writeResult
                        remainsBytes -= writeResult
                        
                        os_log(.debug, "%{public}s[%{public}ld], %{public}s: write %ld/%ld bytes. write result: %ld", ((#file as NSString).lastPathComponent), #line, #function, baseAddress, readBytesCount, writeResult)
                        
                        self.progress.completedUnitCount += Int64(writeResult)
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): estimate progress: \(self.progress.completedUnitCount)/\(self.progress.totalUnitCount)")
                        
                        if writeResult == -1 {
                            break
                        }
                    }
                }
                
                while readBytesCount < SerialStream.bufferSize {
                    // close when no more source streams
                    guard self.currentStreamIndex < self.streams.count else {
                        break
                    }
                    
                    let inputStream = self.streams[self.currentStreamIndex]
                    // open input if needs
                    if inputStream.streamStatus != .open {
                        inputStream.open()
                    }
                    // read next source stream when current drain
                    guard inputStream.hasBytesAvailable else {
                        self.currentStreamIndex += 1
                        continue
                    }
                    
                    let reaminsCount = SerialStream.bufferSize - readBytesCount
                    let readCount = inputStream.read(&self.buffer[readBytesCount], maxLength: reaminsCount)
                    os_log(.debug, "%{public}s[%{public}ld], %{public}s: read source %ld bytes", ((#file as NSString).lastPathComponent), #line, #function, readCount)

                    switch readCount {
                    case 0:
                        self.currentStreamIndex += 1
                        continue
                    case -1:
                        self.boundStreams.output.close()
                        return
                    default:
                        self.canWrite = false
                        readBytesCount += readCount
                    }
                }
            }
    }
    
    deinit {
        os_log(.debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension SerialStream {
    struct Streams {
        let input: InputStream
        let output: OutputStream
    }
}

// MARK: - StreamDelegate
extension SerialStream: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        os_log(.debug, "%{public}s[%{public}ld], %{public}s: eventCode %s", ((#file as NSString).lastPathComponent), #line, #function, String(eventCode.rawValue))

        guard aStream == boundStreams.output else {
            return
        }
        
        if eventCode.contains(.hasSpaceAvailable) {
            canWrite = true
        }
        
        if eventCode.contains(.errorOccurred) {
            // Close the streams and alert the user that the upload failed.
            boundStreams.output.close()
        }
    }
}
