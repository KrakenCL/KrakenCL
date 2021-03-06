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

public typealias APIHeaders = [(String, String)]
public struct APIRequestHead {
    public var method: APIMethod
    public var headers = [(String, String)]()
    public var uri: String
    
    public init(method: APIMethod, headers: [(String, String)], uri: String) {
        self.method = method
        self.headers = headers
        self.uri = uri
    }
}

public enum APIResponseStatus: Int, CustomStringConvertible {
    
    case notFound
    case forbidden
    case error
    case positive
    case badRequest
    
    public var description: String {
        switch self {
        case .notFound:
            return "Page not found."
        case .forbidden:
            return "Access denided."
        case .error:
            return "Internal server error."
        case .positive:
            return "Ok!."
        case .badRequest:
            return "Bad request format or values."
            
        }
    }

}

public enum APIMethod: String {
    case GET
    case POST
    case DELETE
    
    public init?(string: String) {
        if let method = APIMethod(rawValue: string) {
            self = method
        }
        return nil
    }
}

public struct APIResponseHead {
    public var status: APIResponseStatus
    public var headers = [(String, String)]()
    
    public init(status: APIResponseStatus, headers: [(String, String)]) {
        self.status = status
        self.headers = headers
    }
}

public typealias Identifier = String

public protocol APIClient {
    var identifier: Identifier { get }
}

public protocol Personalizable {
    func personalize(by header: APIHeaders) -> APIClient?
}

public protocol APIResponder {
    var requestHead: APIRequestHead { get }
    var requestBody: Data? { get }

    var responseHead: APIResponseHead { get set }
    var responseBody: Data? { get set }
    var defaultHeaders: APIHeaders { get }        
}

public protocol APIInteractor: Personalizable {
    func process(requestHead: APIRequestHead, requestBody: Data?) -> APIResponder
}

public protocol Authorisable {
    func isAllowed(method: APIMethod, path: String, headers: APIHeaders) -> Bool
    func isAllowed(method: APIMethod, path: String, client: APIClient) -> Bool
}
