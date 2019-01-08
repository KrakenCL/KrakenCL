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
import KituraContracts
import KrakenContracts
import SwiftKuerySQLite
import SwiftKueryORM
import SwiftKuery

public enum ORMServiceError: Error {
    case databasePathNotFound
    case poolNotFound
    case connectionNotFound
}


public class ORMService {
    static let databaseFileName = "KrakenCL.db"
    static let databaseInitialCapacity = 10
    static let databaseMaxCapacity = 30
    var interactor: ORMServiceInteractor!
    var pool: SwiftKuery.ConnectionPool?
    
    public required init() {
        
    }
    
    internal func initializeTabels(database: Database? = nil) throws {
        do {
            try MLModel.createTableSync(using: database)
        } catch {
            //table already exists.
            guard let requestError = error as? KituraContracts.RequestError, requestError.rawValue == 706 else  {
                throw error
            }
        }
    }
}

extension ORMService: Serviceable {
    public func initialize() throws {
        let dbPath = interactor.configsFolderURL.appendingPathComponent(ORMService.databaseFileName, isDirectory: false)
        pool = SQLiteConnection.createPool(filename: dbPath.absoluteString,
                                           poolOptions: ConnectionPoolOptions(initialCapacity: ORMService.databaseInitialCapacity,
                                                                              maxCapacity: ORMService.databaseMaxCapacity))
    }
    
    public func launch() throws {
        let semaphore = DispatchSemaphore(value: 1)
        var error: Error? = nil
        guard let pool = pool else { throw ORMServiceError.poolNotFound }
        pool.getConnection() { [weak self ] connection, connectionError in
            guard let wSelf = self else { return }
            defer {
                semaphore.signal()
            }
            if let connectionError = connectionError {
                error = connectionError
                return
            }
            
            guard let _ = connection else {
                error = ORMServiceError.connectionNotFound
                return
            }
        }
        
        
        semaphore.wait()
        
        if let error = error {
            throw error
        }
        
        Database.default = Database(pool)
        try initializeTabels()

    }
    
    public func shoutdown() throws {
        
    }
    
    public func register(interactor: ServiceInteractor) throws {
        guard let interactor = interactor as? ORMServiceInteractor else {
            throw ServiceError.incompatibleServiceInteractor
        }
        self.interactor = interactor
    }
}

public protocol ORMServiceInteractor: ServiceInteractor {
}
