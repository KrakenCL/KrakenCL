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
import Dispatch

public enum ORMServiceError: Error {
    case databasePathNotFound
    case poolNotFound
    case connectionNotFound
}


public class ORMService {
    static let databaseFileName = "KrakenCL.db"
    var interactor: ORMServiceInteractor!
    let dbQueue = DispatchQueue(label: "com.KrakenCL.ORMQueue")
    public required init() { }
}

extension ORMService: Serviceable {
    public func initialize() throws {
        let dbPath = interactor.configsFolderURL.appendingPathComponent(ORMService.databaseFileName, isDirectory: false)
        dbQueue.sync(flags: .barrier) {
            
            
        }
    }
    
    public func launch() throws {
//        let model = MLModel(identifier: Identifier.new,
//                            name: "ResNet",
//                            description: "New ResNet model",
//                            mainFile: "model.py",
//                            language: .python2,
//                            dependensies: .pip(packages: ["numpy", "pandas"]),
//                            tensorFlowOptions: TensorFlowOptions(accelerator: .none, tensorBoardOptions: TensorBoardOptions(logDir: "/tmp/logdir")),
//                            dockerOptions: nil,
//                            modelSource: ModelSource.sourcePoint(anchor: SourcePoint(identifier: Identifier.new, name: "ArchivedFolder", path: "/tmp/path")))
//
//        let data = try? JSONEncoder().encode(model)
//        if let data = data {
//            print(String(data: data, encoding: .utf8))
//        }
//        {
//            "tensorFlowOptions": {
//                "accelerator": "none",
//                "tensorBoardOptions": {
//                    "logDir": "\\/tmp\\/logdir"
//                }
//            },
//            "dependensies": {
//                "base": "casePIP",
//                "packagesParams": {
//                    "packages": [
//                    "numpy",
//                    "pandas"
//                    ]
//                }
//            },
//            "language": "python2",
//            "mainFile": "model.py",
//            "description": "New ResNet model",
//            "identifier": "4F8AA078-4A91-43B2-A111-76B3BFE70132",
//            "name": "ResNet",
//            "modelSource": {
//                "base": "caseSourcePoint",
//                "anchor": {
//                    "name": "ArchivedFolder",
//                    "path": "\\/tmp\\/path",
//                    "identifier": "D006D35A-C050-4D7C-8DA2-9AC3BB6A5804"
//                }
//            }
//        }
    }
    
    public func shoutdown() throws { }
    
    public func register(interactor: ServiceInteractor) throws {
        guard let interactor = interactor as? ORMServiceInteractor else {
            throw ServiceError.incompatibleServiceInteractor
        }
        self.interactor = interactor
    }
}

public protocol ORMServiceInteractor: ServiceInteractor { }
