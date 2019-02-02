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

public enum APIMessage: String, CaseIterable {
    case info
    case mlmodel
    case configuration
    case storepoint
    case trigger
    case rpc
}

extension APIMessage {
    var responsableClass: APIResponder.Type {
        switch self {
        case .mlmodel:
            return MLModelResponder.self
        case .info:
            return InfoResponder.self
        case .configuration:
            return ConfigurationResponder.self
        case .storepoint:
            return StorepointResponder.self
        case .trigger:
            return TriggerResponder.self
        case .rpc:
            return RPCResponder.self
        }
    }
}

extension APIResponder { }

public enum APIResponderError: Error {
    case bodyRequired
    case modelRequired
}

class BaseResponder: APIResponder {
    
    public var defaultHeaders: APIHeaders {
        var headers = APIHeaders()
        headers.append(("Content-Length", "\(self.responseBody?.count ?? 0)"))
        return headers
    }
    
    var requestHead: APIRequestHead
    var requestBody: Data?

    required init(requestHead: APIRequestHead, requestBody: Data?) {
        self.requestHead = requestHead
        self.requestBody = requestBody
    }
    
    public var rawResponseHead: APIResponseHead?
    public var rawResponseBody: Data?
    
    public var responseHead: APIResponseHead {
        get {
            if let head = rawResponseHead {
                return head
            }
            return APIResponseHead(status: .error, headers: defaultHeaders)
        }
        set {
            rawResponseHead = newValue
        }
    }
    
    public var responseBody: Data? {
        get {
            return rawResponseBody
        }
        set {
            rawResponseBody = newValue
        }
    }
    
    func response(status: APIResponseStatus) {
        responseHead = APIResponseHead(status: status, headers: defaultHeaders)
    }
    
}

class ModelInteractableResponder: BaseResponder {
    var model: ModelObjectRepresentable?
}

class ForbiddenResponder: BaseResponder {
    
    public override var responseHead: APIResponseHead {
        get {
            return APIResponseHead(status: .forbidden, headers: defaultHeaders)
        }
        set {
            rawResponseHead = APIResponseHead(status: .forbidden, headers: defaultHeaders)
        }
    }
    
    override var rawResponseBody: Data? {
        get { return "Forbidden".data(using: .utf8) }
        set { }
    }
}

class NotFoundResponder: BaseResponder {
    
    public override var responseHead: APIResponseHead {
        get {
            return APIResponseHead(status: .notFound, headers: defaultHeaders)
        }
        set {
            rawResponseHead = APIResponseHead(status: .notFound, headers: defaultHeaders)
        }
    }
    override var rawResponseBody: Data? {
        get { return "NotFound".data(using: .utf8) }
        set { }
    }
}

class InfoResponder: BaseResponder {
    public override var responseHead: APIResponseHead {
        get {
            return APIResponseHead(status: .positive, headers: defaultHeaders)
        }
        set {
            rawResponseHead = APIResponseHead(status: .positive, headers: defaultHeaders)
        }
    }
    
    override var rawResponseBody: Data? {
        get { return "Info ok".data(using: .utf8) }
        set { }
    }
}

class MLModelResponder: ModelInteractableResponder { }

class ConfigurationResponder: BaseResponder { }

class  StorepointResponder: BaseResponder { }

class  TriggerResponder: BaseResponder { }

class  RPCResponder: BaseResponder { }
