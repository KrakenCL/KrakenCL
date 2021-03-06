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

extension ORMResponder {
    
    func fetch(identifier: Identifier? = nil, for client: APIClient) {
        if modelType() == RawMLModel.self {
            let result: [RawMLModel] = fetch(identifier: nil, for: client)
            write(models: result)
            finish()
        } else if modelType() == RawLanguageEnvironment.self{
            let availableEnvironments = LanguageEnvironment.allCases.map { RawLanguageEnvironment($0) }
            write(models: availableEnvironments)
            finish()
        } else if modelType() == RawSourcePoint.self{
            let result: [RawSourcePoint] = fetch(identifier: nil, for: client)
            write(models: result)
            finish()
        } else {
            terminate(status: .badRequest)
        }
    }
    
    func fetch<M: RawModelObjectRepresentable>(identifier: Identifier? = nil, for client: APIClient) -> [M] {
        
        
        return [M]()
    }
    
}
