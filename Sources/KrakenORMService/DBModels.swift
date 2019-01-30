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

public protocol ModelObjectRepresentable: Codable {
    
}
extension Identifier {
    public static var new: Identifier {
        return UUID().uuidString
    }
}

public protocol Identifiable  {
    var identifier: Identifier { get }
}

public protocol Descriable {
    var name: String { get set }
    var description: String { get set }
}

public struct DataBase: Codable {
    
}

public enum Dependensies {
    case pip(packages: [String])
    case pm(packages: [String])
}

extension Dependensies: Codable {
    private enum CodingKeys: String, CodingKey {
        case base, packagesParams
    }
    
    private enum Base: String, Codable {
        case casePIP, casePM
    }
    
    private struct CasePackagesParams: Codable {
        let packages: [String]
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .pip(let packages):
            try container.encode(Base.casePIP, forKey: .base)
            try container.encode(CasePackagesParams(packages: packages), forKey: .packagesParams)
            
        case .pm(let packages):
            try container.encode(Base.casePIP, forKey: .base)
            try container.encode(CasePackagesParams(packages: packages), forKey: .packagesParams)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = try container.decode(Base.self, forKey: .base)
        
        switch base {
        case .casePIP:
            let params = try container.decode(CasePackagesParams.self, forKey: .packagesParams)
            self = .pip(packages: params.packages)
        case .casePM:
            let params = try container.decode(CasePackagesParams.self, forKey: .packagesParams)
            self = .pm(packages: params.packages)
        }
    }
}
    
public enum Language: String, Codable {
    case python2
    case python3
    case swift
}

public enum Accelerator: String, Codable {
    case none, gpu, tpu
}

public struct TensorBoardOptions: Codable {
    var logDir: String
}

public struct DockerOptions: Codable {
    
}

public struct TensorFlowOptions: Codable {
    var accelerator: Accelerator = .none
    var tensorBoardOptions: TensorBoardOptions?
}

public struct SourcePoint: Identifiable, Codable {
    public let identifier: Identifier
    public let name: String
    public let path: String
}

public struct GitRepository: Codable {
    public let path: String
}

public enum ModelSource: Codable {
    case sourcePoint(anchor: SourcePoint)
    case git(anchor: GitRepository)
    
    private enum CodingKeys: String, CodingKey {
        case base, anchor
    }
    
    private enum Base: String, Codable {
        case caseSourcePoint, caseGit
    }
    
    private struct CaseAnchor: Codable {
        let Anchor: [String]
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .sourcePoint(let anchor):
            try container.encode(Base.caseSourcePoint, forKey: .base)
            try container.encode(anchor, forKey: .anchor)
            
        case .git(let anchor):
            try container.encode(Base.caseGit, forKey: .base)
            try container.encode(anchor, forKey: .anchor)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = try container.decode(Base.self, forKey: .base)
        
        switch base {
        case .caseSourcePoint:
            let sourcePoint = try container.decode(SourcePoint.self, forKey: .anchor)
            self = .sourcePoint(anchor: sourcePoint)
        case .caseGit:
            let gitOptions = try container.decode(GitRepository.self, forKey: .anchor)
            self = .git(anchor: gitOptions)
        }
    }
}

public struct SomeModel: ModelObjectRepresentable { }

public struct MLModel: Identifiable, Descriable, ModelObjectRepresentable {
    public let identifier: Identifier
    public var name: String
    public var description: String

    var mainFile: String
    var language: Language
    var dependensies: Dependensies
    var tensorFlowOptions: TensorFlowOptions
    var dockerOptions: DockerOptions?
    var modelSource: ModelSource
}
