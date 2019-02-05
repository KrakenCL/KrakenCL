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



extension Core: APIInteractor {
    
    public func process(requestHead: APIRequestHead, requestBody: Data?) -> APIResponder {
        if let call = requestHead.uri.chopPrefix("/api") {
            if let essence = call.split(separator: "/").first {
                if let message = APIMessage(rawValue: String(essence)) {
                    
                    let responder = message.responsableClass.init(requestHead: requestHead,
                                                                  requestBody: requestBody,
                                                                  authInteraction: self,
                                                                  personInteraction: self,
                                                                  modelInteraction: self)
                    
                    return responder.process()
                }
            }
        }
        return ORMResponder(requestHead: requestHead,
                            requestBody: requestBody,
                            authInteraction: self,
                            personInteraction: self,
                            modelInteraction: self).process()
    }
}
