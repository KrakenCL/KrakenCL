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

public enum ResultError: Error {
    case noValueNoErrorCase
}

public typealias ResultCompletion<T> = (_ result: Result<T>) -> Void

public enum Result<T> {
    case positive(value: T)
    case negative(error: Error)
    
    public var error: Error? {
        switch self {
        case let .negative(error):
            return error
        default:
            return nil
        }
    }
    
    public var value: T? {
        switch self {
        case let .positive(value):
            return value
        default:
            return nil
        }
    }
    
    public init(value: T?, error: Error?) {
        if let value = value {
            self = .positive(value: value)
        } else {
            self = .negative(error: error ?? ResultError.noValueNoErrorCase)
        }
    }
    
    public func combining<R>(otherResult: Result<R>) -> Result<(T, R)> {
        switch self {
        case let .positive(value):
            switch otherResult {
            case let .positive(otherValue):
                return .positive(value: (value, otherValue))
            case let .negative(error):
                return error.toResult()
            }
        case let .negative(error):
            return error.toResult()
        }
    }
}

extension Error {
    public func toResult<T>() -> Result<T> {
        return .negative(error: self)
    }
}

extension Result where T == Void {
    public static var positive: Result<T> {
        return .positive(value: ())
    }
}

extension Result {
    public var empty: Result<Void> {
        switch self {
        case let .negative(error):
            return error.toResult()
        case .positive:
            return .positive
        }
    }
    
    public func onPositive(_ handler: (_ value: T) -> Void) {
        switch self {
        case .positive(let value):
            handler(value)
        default:
            break
        }
    }
    
    public func onNegative(_ handler: (_ error: Error) -> Void) {
        switch self {
        case .negative(let error):
            handler(error)
        default:
            break
        }
    }
    
    public func map<R>(_ transform: (T) throws -> R) -> Result<R> {
        do {
            switch self {
            case .positive(let value):
                return .positive(value: try transform(value))
            case .negative(let error):
                return error.toResult()
            }
        } catch {
            return error.toResult()
        }
    }
}

