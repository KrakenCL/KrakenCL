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

enum APIMessage: String, CaseIterable {
    case model
    case info
    
    var responsableClass: APIResponder.Type {
        switch self {
        case .model:
            return ModelResponder.self
        case .info:
            return InfoResponder.self
        }
    }
}

extension APIResponder {
    
}

class BaseResponder: APIResponder {
    public var defaultHeaders: APIHeaders {
        var headers = APIHeaders()
        headers.append(("Content-Length", "\(self.responseBody.utf8.count)"))
        return headers
    }
    
    var requestHead: APIRequestHead
    var requestBody: String
    required init(requestHead: APIRequestHead, requestBody: String) {
        self.requestHead = requestHead
        self.requestBody = requestBody
    }
    
    public var responseHead: APIResponseHead {
        return APIResponseHead(status: .badRequest, headers: defaultHeaders)
    }
    
    public var responseBody: String {
        return "Bad Request"
    }
    
}
class ModelResponder: BaseResponder {
    
}

class ForbiddenResponder: BaseResponder {
    
    public override var responseHead: APIResponseHead {
        return APIResponseHead(status: .forbidden, headers: defaultHeaders)
    }
    
    public override var responseBody: String {
        return "Forbidden"
    }
}

class NotFoundResponder: BaseResponder {
    
    public override var responseHead: APIResponseHead {
        return APIResponseHead(status: .notFound, headers: defaultHeaders)
    }
    
    public override var responseBody: String {
        return "NotFound"
    }
}

class InfoResponder: BaseResponder {
    public override var responseHead: APIResponseHead {
        return APIResponseHead(status: .positive, headers: defaultHeaders)
    }
    
    public override var responseBody: String {
        return "Info ok"
    }
}
