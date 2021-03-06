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
import KrakenORMService

protocol RawModelObjectRepresentable: Codable { }
struct RawMLModel: RawModelObjectRepresentable {
    public var identifier: Identifier
    public var label: String
    public var description: String
}

struct RawSourcePoint: RawModelObjectRepresentable {
    public var identifier: Identifier
    public var label: String
    public var description: String
}


struct RawLanguageEnvironment: RawModelObjectRepresentable {
    public var identifier: Identifier
    public var label: String
    
    init(_ environment: LanguageEnvironment) {
        self.label = environment.rawValue
        self.identifier = environment.rawValue
    }
}


extension Core: ModelInteraction {
    func update(model: RawModelObjectRepresentable, for client: APIClient, callback: (Result<RawModelObjectRepresentable>) -> Void) {
        guard var mlModel = model as? RawMLModel else {
            callback(.negative(error: URLError(.badServerResponse) ))
            return
        }
        
        if mlModel.identifier.isEmpty {
             mlModel.identifier = Identifier.new
            callback(.positive(value: mlModel))
        }
    }
}
