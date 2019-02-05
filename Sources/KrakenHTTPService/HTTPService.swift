/* Copyright 2017 The Octadero Authors. All Rights Reserved.
 Created by Volodymyr Pavliukevych on 2018.
 Licensed under the GPL License, Version 3.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.gnu.org/licenses/gpl-3.0.txt
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import NIO
import NIOHTTP1
import KrakenContracts

internal enum BindTo {
    case ip(host: String, port: Int)
    case unixDomainSocket(path: String)
}

public enum HTTPServiceError: Error {
    case resourceBundlePathNotFound
    case resourceBundleNotFound(url: URL)
    //"Address was unable to bind. Please check that the socket was not closed or that the address family was understood."
    case unableToBindAddress
    case canNotExtractUIInterface
    case incorrectUIInterfaceElementFormat
}

public class HTTPService {
    private static let ResourceBundleName = ""
    internal static let ServerPort = 8080
    private var interactor: HTTPServiceInteractor!
    internal var bundlePath = "/dev/null"
    private var channel: Channel?
    
    private let httpQueue = DispatchQueue(label: "com.KrakenCL.httpservice")
    private let fileIO: NonBlockingFileIO
    private let group: MultiThreadedEventLoopGroup
    
    public required init() {
        let threadPool = BlockingIOThreadPool(numberOfThreads: 6)
        threadPool.start()
        fileIO = NonBlockingFileIO(threadPool: threadPool)
        group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    }
    
    internal func startHTTPServer() throws {
        let bindTarget = BindTo.ip(host: "::1", port: HTTPService.ServerPort)
        let allowHalfClosure = true
        
        let bootstrap = ServerBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            
            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).then {
                    channel.pipeline.add(handler: HTTPServiceHandler(fileIO: self.fileIO,
                                                                     htdocsPath: self.bundlePath,
                                                                     authoriser: self.interactor.authorizer,
                                                                     apiInteractor: self.interactor.apiInteractor))
                }
            }
            
            // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
            .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: allowHalfClosure)
        
        self.channel = try { () -> Channel in
            switch bindTarget {
            case .ip(let host, let port):
                return try bootstrap.bind(host: host, port: port).wait()
            case .unixDomainSocket(let path):
                return try bootstrap.bind(unixDomainSocketPath: path).wait()
            }
            }()
        guard let channel = channel else { throw HTTPServiceError.unableToBindAddress }
        guard let localAddress = channel.localAddress else { throw HTTPServiceError.unableToBindAddress }
        print("Server started and listening on \(localAddress), htdocs path \(self.bundlePath)")
        
        // This will never unblock as we don't close the ServerChannel
        try channel.closeFuture.wait()
        print("Server closed")
        
    }
}

extension HTTPService : Serviceable {
    
    public func initialize() throws {
        
        guard let resourceBundlePath = interactor?.resourceBundleURL else { throw HTTPServiceError.resourceBundlePathNotFound }
        var isFolder: ObjCBool = false
        guard FileManager.default.fileExists(atPath: resourceBundlePath.absoluteString,
                                             isDirectory: &isFolder) else { throw HTTPServiceError.resourceBundleNotFound(url: resourceBundlePath) }
        
        guard isFolder.boolValue else { throw HTTPServiceError.resourceBundleNotFound(url: resourceBundlePath) }
        bundlePath = resourceBundlePath.appendingPathComponent(HTTPService.ResourceBundleName).absoluteString
        
        try prepareUserInterface()
    }
    
    public func launch() throws {
        httpQueue.async {[weak self] in
            guard let wSelf = self else { return }
            do {
                try wSelf.startHTTPServer()
            } catch {
                wSelf.interactor.happend(error: error, at: wSelf)
            }
        }
    }
    
    public func register(interactor: ServiceInteractor) throws {
        guard let interactor = interactor as? HTTPServiceInteractor else {
            throw ServiceError.incompatibleServiceInteractor
        }
        self.interactor = interactor
    }
    
    public func shoutdown() throws {
        try group.syncShutdownGracefully()
    }
}

public protocol HTTPServiceInteractor: ServiceInteractor {
    var apiInteractor: APIInteractor { get }
    var authorizer: Authorisable { get }
}


