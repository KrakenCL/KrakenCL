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

extension Core: ModelInteraction {
    
    func processModelResponder<M: ModelObjectRepresentable>(modelResponder: ModelInteractableResponder<M>, from apiClient: APIClient) {
        switch modelResponder.requestHead.method {
        case .GET:
            break
        case .POST:
            updateModel(modelResponder: modelResponder, from: apiClient)
            break
        case .DELETE:
            break
        
        }
    }
    
    func updateModel<M: ModelObjectRepresentable>(modelResponder: ModelInteractableResponder<M>, from apiClient: APIClient) {

        guard var model = try? modelResponder.readModel() else {
            return
        }
        if model.identifier.isEmpty {
            model.identify()
            modelResponder.model = model
            modelResponder.writeModel()
        } else {
            modelResponder.writeModel()
        }

    }
    
    func readModel<M: ModelObjectRepresentable>(modelResponder: ModelInteractableResponder<M>, from apiClient: APIClient) {
    
    }
}
