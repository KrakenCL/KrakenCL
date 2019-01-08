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

extension KrakenContracts.APIMethod {
    init?(httpMethod: HTTPMethod) {
        switch httpMethod {
        case .GET:
            self = KrakenContracts.APIMethod.GET
        case .POST:
            self = KrakenContracts.APIMethod.POST
        case .DELETE:
            self = KrakenContracts.APIMethod.DELETE
        default:
            return nil
        }
    }
}

extension HTTPResponseStatus {
    init(_ status: APIResponseStatus) {
        switch status {
        case .notFound:
            self = .notFound
        case .error:
            self = .internalServerError
        case .forbidden:
            self = .forbidden
        case .positive:
            self = .ok
        case .badRequest:
            self = .badRequest
        }
    }
}

//
//extension Version {
//    init(_ httpVersion: HTTPVersion) {
//        self = Version(major: httpVersion.major, minor: httpVersion.minor)
//    }
//}
//
//extension RequestHead {
//    init(_ httpRequestHead: HTTPRequestHead) {
//        self = RequestHead(method: KrakenContracts.Method(httpMethod: httpRequestHead.method) ?? .GET,
//                           version: Version(httpRequestHead.version),
//                           headers: Headers(httpRequestHead.headers),
//                           uri: httpRequestHead.uri)
//    }
//}
//
//extension ResponseHead {
//    var httpRequestHead: HTTPResponseHead {
//        
//        let httpVersion = HTTPVersion(major: version.major, minor: version.minor)
//        var statusCode: HTTPResponseStatus = .ok
//        switch status {
//        case .notFound:
//            statusCode = .notFound
//        case .error:
//            statusCode = .internalServerError
//        case .forbidden:
//            statusCode = .forbidden
//        case .positive:
//            statusCode = .ok
//        case .badRequest:
//            statusCode = .badRequest
//        }
//        return HTTPResponseHead(version: httpVersion, status: statusCode)
//    }
//}

extension String {
    public func chopPrefix(_ prefix: String) -> String? {
        if self.unicodeScalars.starts(with: prefix.unicodeScalars) {
            return String(self[self.index(self.startIndex, offsetBy: prefix.count)...])
        } else {
            return nil
        }
    }
    
    public func containsDotDot() -> Bool {
        for idx in self.indices {
            if self[idx] == "." && idx < self.index(before: self.endIndex) && self[self.index(after: idx)] == "." {
                return true
            }
        }
        return false
    }
}

func httpResponseHead(request: HTTPRequestHead, status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders()) -> HTTPResponseHead {
    var head = HTTPResponseHead(version: request.version, status: status, headers: headers)
    let connectionHeaders: [String] = head.headers[canonicalForm: "connection"].map { $0.lowercased() }
    
    if !connectionHeaders.contains("keep-alive") && !connectionHeaders.contains("close") {
        // the user hasn't pre-set either 'keep-alive' or 'close', so we might need to add headers
        switch (request.isKeepAlive, request.version.major, request.version.minor) {
        case (true, 1, 0):
            // HTTP/1.0 and the request has 'Connection: keep-alive', we should mirror that
            head.headers.add(name: "Connection", value: "keep-alive")
        case (false, 1, let n) where n >= 1:
            // HTTP/1.1 (or treated as such) and the request has 'Connection: close', we should mirror that
            head.headers.add(name: "Connection", value: "close")
        default:
            // we should match the default or are dealing with some HTTP that we don't support, let's leave as is
            ()
        }
    }
    return head
}

internal final class FrontendHTTPHandler: ChannelInboundHandler {
    private enum FileIOMethod {
        case sendfile
        case nonblockingFileIO
    }
    
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    private enum State {
        case idle
        case waitingForRequestBody
        case sendingResponse
        
        mutating func requestReceived() {
            precondition(self == .idle, "Invalid state for request received: \(self)")
            self = .waitingForRequestBody
        }
        
        mutating func requestComplete() {
            precondition(self == .waitingForRequestBody, "Invalid state for request complete: \(self)")
            self = .sendingResponse
        }
        
        mutating func responseComplete() {
            precondition(self == .sendingResponse, "Invalid state for response complete: \(self)")
            self = .idle
        }
    }
    
    private var buffer: ByteBuffer! = nil
    private var keepAlive = false
    private var state = State.idle
    private let htdocsPath: String
    
    private var handler: ((ChannelHandlerContext, HTTPServerRequestPart) -> Void)?
    private var handlerFuture: EventLoopFuture<Void>?
    private let fileIO: NonBlockingFileIO
    private let defaultResponse = "Hello World\r\n"
    private let authoriser: Authorisable
    private let apiInteractor: APIInteractor
    private var savedRequestHead: HTTPRequestHead?
    
    public init(fileIO: NonBlockingFileIO, htdocsPath: String, authoriser: Authorisable, apiInteractor: APIInteractor) {
        self.htdocsPath = htdocsPath
        self.fileIO = fileIO
        self.authoriser = authoriser
        self.apiInteractor = apiInteractor
    }
    
    func handleAPICall(ctx: ChannelHandlerContext, request: HTTPServerRequestPart) {
        switch request {
        case .head(let request):
            self.keepAlive = request.isKeepAlive
            self.state.requestReceived()
            self.savedRequestHead = request
        case .body(buffer: let buf):
            print(#function, buf.debugDescription)
            
            break
        case .end:
            self.state.requestComplete()
            guard let requestHead = self.savedRequestHead else {
                print("savedRequestHead is \(String(describing: savedRequestHead))")
                return
            }
            guard let method = APIMethod(httpMethod: requestHead.method) else { return }
            let headers = requestHead.headers.compactMap { ($0.name, $0.value) }
            let apiRequestHead = APIRequestHead(method: method, headers: headers, uri: requestHead.uri)
            
            let responder = self.apiInteractor.process(requestHead: apiRequestHead, requestBody: "POST IS EMPTY")
            
            let head = httpResponseHead(request: requestHead,
                                        status: HTTPResponseStatus(responder.responseHead.status),
                                        headers:HTTPHeaders(responder.responseHead.headers))
            self.buffer.clear()
            self.buffer.write(string: responder.responseBody)
            
            
            ctx.write(self.wrapOutboundOut(.head(head)), promise: nil)
            ctx.write(self.wrapOutboundOut(.body(.byteBuffer(self.buffer))), promise: nil)
            self.completeResponse(ctx, trailers: nil, promise: nil)
        }
    }
    
    func handleJustWrite(ctx: ChannelHandlerContext, request: HTTPServerRequestPart, statusCode: HTTPResponseStatus = .ok, string: String, trailer: (String, String)? = nil, delay: TimeAmount = .nanoseconds(0), responseHeaders: HTTPHeaders = HTTPHeaders()) {
        switch request {
        case .head(let request):
            self.keepAlive = request.isKeepAlive
            self.state.requestReceived()
            ctx.writeAndFlush(self.wrapOutboundOut(.head(httpResponseHead(request: request, status: statusCode, headers: responseHeaders))), promise: nil)
        case .body(buffer: _):
            ()
        case .end:
            self.state.requestComplete()
            ctx.eventLoop.scheduleTask(in: delay) { () -> Void in
                var buf = ctx.channel.allocator.buffer(capacity: string.utf8.count)
                buf.write(string: string)
                ctx.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(buf))), promise: nil)
                var trailers: HTTPHeaders? = nil
                if let trailer = trailer {
                    trailers = HTTPHeaders()
                    trailers?.add(name: trailer.0, value: trailer.1)
                }
                
                self.completeResponse(ctx, trailers: trailers, promise: nil)
            }
        }
    }
    
    func dynamicHandler(request reqHead: HTTPRequestHead) -> ((ChannelHandlerContext, HTTPServerRequestPart) -> Void)? {
        switch reqHead.uri {
        case "/api/pid":
            return { ctx, req in self.handleJustWrite(ctx: ctx, request: req, string: "\(getpid())\r\n") }
        default:
            return self.handleAPICall
        }
    }
    
    private func handleFile(ctx: ChannelHandlerContext, request: HTTPServerRequestPart, ioMethod: FileIOMethod, path: String) {
        self.buffer.clear()
        
        func sendErrorResponse(request: HTTPRequestHead, _ error: Error) {
            var body = ctx.channel.allocator.buffer(capacity: 128)
            let response = { () -> HTTPResponseHead in
                switch error {
                case let e as IOError where e.errnoCode == ENOENT:
                    body.write(staticString: "IOError (not found)\r\n")
                    return httpResponseHead(request: request, status: .notFound)
                case let e as IOError:
                    body.write(staticString: "IOError (other)\r\n")
                    body.write(string: e.description)
                    body.write(staticString: "\r\n")
                    return httpResponseHead(request: request, status: .notFound)
                default:
                    body.write(string: "\(type(of: error)) error\r\n")
                    return httpResponseHead(request: request, status: .internalServerError)
                }
            }()
            body.write(string: "\(error)")
            body.write(staticString: "\r\n")
            ctx.write(self.wrapOutboundOut(.head(response)), promise: nil)
            ctx.write(self.wrapOutboundOut(.body(.byteBuffer(body))), promise: nil)
            ctx.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
            ctx.channel.close(promise: nil)
        }
        
        func responseHead(request: HTTPRequestHead, fileRegion region: FileRegion, mimeType: String) -> HTTPResponseHead {
            if mimeType.contains("") {
                
            }
            var response = httpResponseHead(request: request, status: .ok)
            response.headers.add(name: "Content-Length", value: "\(region.endIndex)")
            response.headers.add(name: "Content-Type", value: "\(mimeType); charset=UTF-8")
            return response
        }
        
        switch request {
        case .head(let request):
            self.keepAlive = request.isKeepAlive
            self.state.requestReceived()
            guard !request.uri.containsDotDot() else {
                let response = httpResponseHead(request: request, status: .forbidden)
                ctx.write(self.wrapOutboundOut(.head(response)), promise: nil)
                self.completeResponse(ctx, trailers: nil, promise: nil)
                return
            }
            let path = self.htdocsPath + "/" + path
            let fileURL = URL(fileURLWithPath: path)
            let mimeTypes = MimeTypes.Extension(value: fileURL.pathExtension).mimeType
            
            
            let fileHandleAndRegion = self.fileIO.openFile(path: path, eventLoop: ctx.eventLoop)
            fileHandleAndRegion.whenFailure {
                sendErrorResponse(request: request, $0)
            }
            fileHandleAndRegion.whenSuccess { (file, region) in
                switch ioMethod {
                case .nonblockingFileIO:
                    var responseStarted = false
                    let response = responseHead(request: request, fileRegion: region, mimeType: mimeTypes)
                    return self.fileIO.readChunked(fileRegion: region,
                                                   chunkSize: 32 * 1024,
                                                   allocator: ctx.channel.allocator,
                                                   eventLoop: ctx.eventLoop) { buffer in
                                                    if !responseStarted {
                                                        responseStarted = true
                                                        ctx.write(self.wrapOutboundOut(.head(response)), promise: nil)
                                                    }
                                                    return ctx.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(buffer))))
                        }.then { () -> EventLoopFuture<Void> in
                            let p = ctx.eventLoop.newPromise(of: Void.self)
                            self.completeResponse(ctx, trailers: nil, promise: p)
                            return p.futureResult
                        }.thenIfError { error in
                            if !responseStarted {
                                if let ioError = error as? NIO.IOError {
                                    print(ioError.reason)
                                }
                                let response = httpResponseHead(request: request, status: .ok)
                                ctx.write(self.wrapOutboundOut(.head(response)), promise: nil)
                                var buffer = ctx.channel.allocator.buffer(capacity: 100)
                                buffer.write(string: "fail: \(error)")
                                ctx.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
                                self.state.responseComplete()
                                return ctx.writeAndFlush(self.wrapOutboundOut(.end(nil)))
                            } else {
                                return ctx.close()
                            }
                        }.whenComplete {
                            _ = try? file.close()
                    }
                case .sendfile:
                    let response = responseHead(request: request, fileRegion: region, mimeType: mimeTypes)
                    ctx.write(self.wrapOutboundOut(.head(response)), promise: nil)
                    ctx.writeAndFlush(self.wrapOutboundOut(.body(.fileRegion(region)))).then {
                        let p = ctx.eventLoop.newPromise(of: Void.self)
                        self.completeResponse(ctx, trailers: nil, promise: p)
                        return p.futureResult
                        }.thenIfError { (_: Error) in
                            ctx.close()
                        }.whenComplete {
                            _ = try? file.close()
                    }
                }
            }
        case .end:
            self.state.requestComplete()
        default:
            fatalError("oh noes: \(request)")
        }
    }
    
    //MARK: Response helper
    private func completeResponse(_ ctx: ChannelHandlerContext, trailers: HTTPHeaders?, promise: EventLoopPromise<Void>?) {
        self.state.responseComplete()
        
        let promise = self.keepAlive ? promise : (promise ?? ctx.eventLoop.newPromise())
        if !self.keepAlive {
            promise!.futureResult.whenComplete { ctx.close(promise: nil) }
        }
        self.handler = nil
        
        ctx.writeAndFlush(self.wrapOutboundOut(.end(trailers)), promise: promise)
    }
    
    //MARK: - Routing
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        if let handler = self.handler {
            handler(ctx, reqPart)
            return
        }
        
        switch reqPart {        
        case .head(let request):
            guard let method = APIMethod(httpMethod: request.method) else {
                self.handler =  { ctx, req in self.handleJustWrite(ctx: ctx, request: req, statusCode: .forbidden, string: "Forbidden") }
                self.handler!(ctx, reqPart)
                return
            }
            
            guard authoriser.isAllowed(method: method, path: request.uri, headers: request.headers.compactMap { ($0.name, $0.value)}) else {
                self.handler =  { ctx, req in self.handleJustWrite(ctx: ctx, request: req, statusCode: .forbidden, string: "Forbidden") }
                self.handler!(ctx, reqPart)
                return
            }
            
            if request.uri.unicodeScalars.starts(with: "/api".unicodeScalars) {
                self.handler = self.dynamicHandler(request: request)
                self.handler!(ctx, reqPart)
                return
            }  else if let path = request.uri.chopPrefix("/static/") {
                self.handler = { self.handleFile(ctx: $0, request: $1, ioMethod: .nonblockingFileIO, path: path) }
                self.handler!(ctx, reqPart)
                return
            } else if let _ = request.uri.chopPrefix("/favicon.ico") {
                self.handler = { self.handleFile(ctx: $0, request: $1, ioMethod: .nonblockingFileIO, path: "/favicon.ico") }
                self.handler!(ctx, reqPart)
                return
            } else if request.uri == "/" {
                //Index page kind
                
                let headers = HTTPHeaders([("Location", "static/index.html")])
                self.handler =  { ctx, req in self.handleJustWrite(ctx: ctx,
                                                                   request: req,
                                                                   statusCode: .movedPermanently,
                                                                   string: "",
                                                                   responseHeaders: headers)}
                self.handler!(ctx, reqPart)
                return
            }
            // In case route (Page) not found.
            self.handler =  { ctx, req in self.handleJustWrite(ctx: ctx,
                                                               request: req,
                                                               statusCode: .notFound,
                                                               string: "Page not found") }
            self.handler!(ctx, reqPart)
            return
        case .body:
            break
        case .end:
            self.state.requestComplete()
            let content = HTTPServerResponsePart.body(.byteBuffer(buffer!.slice()))
            ctx.write(self.wrapOutboundOut(content), promise: nil)
            self.completeResponse(ctx, trailers: nil, promise: nil)
        }
    }
    
    func channelReadComplete(ctx: ChannelHandlerContext) {
        ctx.flush()
    }
    
    func handlerAdded(ctx: ChannelHandlerContext) {
        self.buffer = ctx.channel.allocator.buffer(capacity: 0)
    }
    
    func userInboundEventTriggered(ctx: ChannelHandlerContext, event: Any) {
        switch event {
        case let evt as ChannelEvent where evt == ChannelEvent.inputClosed:
            // The remote peer half-closed the channel. At this time, any
            // outstanding response will now get the channel closed, and
            // if we are idle or waiting for a request body to finish we
            // will close the channel immediately.
            switch self.state {
            case .idle, .waitingForRequestBody:
                ctx.close(promise: nil)
            case .sendingResponse:
                self.keepAlive = false
            }
        default:
            ctx.fireUserInboundEventTriggered(event)
        }
    }
}
