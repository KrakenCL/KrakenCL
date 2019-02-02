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
import KrakenORMService
import KrakenHTTPService
import KrakenContracts

enum CoreError: Error {
    
}

class Core {
    var services = [Serviceable]()
    var resourceBundleURL: URL {
        return environment.resourceBundleURL
    }
    
    var labsFolderURL: URL {
        return environment.labsFolderURL
    }
    var configsFolderURL: URL {
        return environment.configsFolderURL
    }


    let environment: Environment
    init() throws {
        environment = try Environment()
    }
    
    func run(callback: @escaping ResultCompletion<Void>) {
        
        DispatchQueue.global().async { [weak self] in
            guard let wSelf = self else { return }
            do {
                try FileManager.checkAndCreateFolder(wSelf.labsFolderURL)
                try FileManager.checkAndCreateFolder(wSelf.configsFolderURL)
                try wSelf.register(service: HTTPService.self)
                try wSelf.register(service: ORMService.self)
            } catch {
                callback(.negative(error: error))
            }
            callback(.positive)
        }
    }
    
    func process(message: APIResponder, from apiClient: APIClient) {

    }
}

extension Core: ServiceContainable {
    func register(service: Serviceable.Type) throws {
        let instance = service.init()
        try instance.register(interactor: self)
        try instance.initialize()
        try register(service: instance)
        try instance.launch()
    }
    
    func register(service: Serviceable) throws {
        self.services.append(service)
        try service.register(interactor: self)
    }

}

extension Core: ServiceInteractor {
    func happend(error: Error, at service: Serviceable) {
        fatalError(error.localizedDescription)
    }
}

extension Core: HTTPServiceInteractor {
    var apiInteractor: APIInteractor { return self }
    var authorizer: Authorisable { return self }
}

extension Core: ORMServiceInteractor {
    
}

