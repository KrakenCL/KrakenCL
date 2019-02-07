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
import KrakenContracts
import KrakenHTTPService
import KrakenORMService

public struct ErrorRepresentation: Codable {
    var code: Int?
    var message: String?
}

public enum ResponderError: Int, CustomStringConvertible, Error {
    case timeout
    case encodeModel
    case decodeModel
    case ormInteraction
    
    public var description: String {
        switch self {
        case .timeout:
            return "Server can't process request for allocated period of time."
        case .encodeModel:
            return "Can't encode model."
        case .decodeModel:
            return "Can't decode model."
        case .ormInteraction:
            return "Can't save or restore model from ORM,"

        }
    }
    
    var representation: ErrorRepresentation {
        return ErrorRepresentation(code: self.rawValue, message: self.description)
    }
}

public struct EmptyValue: Codable {}

public struct ErrorOrValue<V: Codable>: Codable {
    var error: ErrorRepresentation?
    var value: [V]?
    
    init(errorCode code: Int, errorMessage message: String) {
        self.error = ErrorRepresentation(code: code, message: message)
    }
    
    init(value: V) {
        self.value = [value]
    }

    init(values: [V]) {
        self.value = values
    }
    
    init(error: ErrorRepresentation) {
        self.value = nil
        self.error = error
    }
    
    func serialyze() throws -> Data {
        return try JSONEncoder().encode(self)
    }
}

public enum APIMessage: String, CaseIterable {
    case orm
}

extension APIMessage {
    var responsableClass: BaseResponder.Type {
        switch self {
        case .orm:
            return ORMResponder.self
        }
    }
}

extension APIResponder { }

public enum APIResponderError: Error {
    case bodyRequired
    case modelRequired
}

protocol BaseResponder: class, APIResponder {
    var defaultHeaders: APIHeaders { get }
    var requestHead: APIRequestHead { get set }
    var requestBody: Data? { get set }
    var authInteraction: Authorisable { get set }
    var personInteraction: Personalizable { get set }
    var modelInteraction: ModelInteraction { get  set }
    func process() -> APIResponder
    init(requestHead: APIRequestHead, requestBody: Data?, authInteraction: Authorisable, personInteraction: Personalizable, modelInteraction: ModelInteraction)
    
}

extension BaseResponder {
    public var defaultHeaders: APIHeaders {
        var headers = APIHeaders()
        headers.append(("Content-Length", "\(self.responseBody?.count ?? 0)"))
        headers.append(("Access-Control-Allow-Origin", "*"))
        return headers
    }
    public func process() {
        
    }
}

class ORMResponder: BaseResponder {
    static let timeout: Double = 60
    var requestHead: APIRequestHead
    var requestBody: Data?
    var responseHead: APIResponseHead
    var responseBody: Data?
    var queue = DispatchQueue(label: "com.krakencl.ResponderProcessQueue", qos: DispatchQoS.default, attributes: DispatchQueue.Attributes.concurrent)
    var semaphore = DispatchSemaphore(value: 0)
    
    var authInteraction: Authorisable
    var personInteraction: Personalizable
    var modelInteraction: ModelInteraction
    var rawModelType: RawModelObjectRepresentable.Type!
    
    

    
    required init(requestHead: APIRequestHead, requestBody: Data?, authInteraction: Authorisable, personInteraction: Personalizable, modelInteraction: ModelInteraction) {
        self.requestHead = requestHead
        self.requestBody = requestBody
        self.authInteraction = authInteraction
        self.personInteraction = personInteraction
        self.modelInteraction = modelInteraction
        self.responseHead = APIResponseHead(status: .error, headers: [])
    }
    
    func evaluate() {
        guard let client = personInteraction.personalize(by: requestHead.headers) else {
            terminate(error: .timeout)
            return
        }
        
        guard authInteraction.isAllowed(method: requestHead.method, path: requestHead.uri, client: client) else {
            terminate(status: .forbidden)
            return
        }
        // Do actions
        action(for: client)
    }
    
    func action(for client: APIClient) {
        switch requestHead.method {
        case .GET:
            fetch(identifier: nil, for: client)
            
            return
            
        case .POST:
            if modelType() == RawMLModel.self {
                guard let model: RawMLModel = readModelObject() else { return }
                update(model: model, for: client)
            } else {
                terminate(status: .badRequest)
            }
            return
            
        case .DELETE:
            return
        }
    }

    func update<M: RawModelObjectRepresentable>(model: M, for client: APIClient) {
        modelInteraction.update(model: model, for: client) { (result) in
            result.onNegative({ (error: Error) in
                if let modelError = error as? ModelInteractionError {
                    if modelError == .accessDenied {
                        self.terminate(status: .forbidden)
                    }
                    terminate(error: .ormInteraction)
                }
            })
            
            result.onPositive({ (model) in
                guard let rawModel = model as? M else {
                    terminate(error: .encodeModel)
                    return
                }
                self.write(model: rawModel)
                self.finish()
            })
        }
    }
    
    func readModelObject<M: RawModelObjectRepresentable>() -> M? {
        guard let data = requestBody else {
            terminate(status: .badRequest)
            return nil
        }
        
        do {
          return try JSONDecoder().decode(M.self, from: data)
        } catch {
            terminate(error: .decodeModel)
        }
        return nil
    }
    
    func write<M: RawModelObjectRepresentable>(model: M) {
        do {
            responseBody = try ErrorOrValue(value: model).serialyze()
            responseHead.status = .positive
        } catch {
            terminate(error: .encodeModel)
        }
    }

    func write<M: RawModelObjectRepresentable>(models: [M]) {
        do {
            responseBody = try ErrorOrValue(values: models).serialyze()
            responseHead.status = .positive
        } catch {
            terminate(error: .encodeModel)
        }
    }
    
    func finish() {
        processHeaders()
        semaphore.signal()
    }
    
    func modelType() -> RawModelObjectRepresentable.Type? {
        guard let call = requestHead.uri.chopPrefix("/api") else  { return nil }
        guard let type = call.split(separator: "/").first, type == "orm" else { return nil }
        guard let model = call.split(separator: "/").last else { return nil }
        return Model(rawValue: String(model))?.rawModelType
    }
    
    func terminate(error: ResponderError) {
        self.responseHead.status = .error
        self.responseBody = try? ErrorOrValue<EmptyValue>(error: error.representation).serialyze()
        semaphore.signal()
    }

    func terminate(status: APIResponseStatus) {
        self.responseHead.status = status
        if status == .positive {
            let errorOrValue = ErrorOrValue<EmptyValue>(value: EmptyValue())
            self.responseBody = try? errorOrValue.serialyze()

        } else {
            let errorOrValue = ErrorOrValue<EmptyValue>(errorCode: status.rawValue, errorMessage: status.description)
            self.responseBody = try? errorOrValue.serialyze()
        }
        processHeaders()
        semaphore.signal()
    }
    
    public func processHeaders() {
        self.responseHead.headers = defaultHeaders
    }
    
    public func process() -> APIResponder {
    
        guard let modelType = modelType() else {
            terminate(status: .badRequest)
            return self
        }
        
        rawModelType = modelType
        
        // Launch processing
        queue.async {
            self.evaluate()
        }
        
        let result = semaphore.wait(timeout: DispatchTime.now() + ORMResponder.timeout)
        if result == .timedOut {
            terminate(error: .timeout)
        }
        return self
    }
}
