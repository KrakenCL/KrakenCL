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
import Utility

enum EnvironmentError: Error {
    case emptyParameter(parameter: String)
    case showHelp
}

class Environment {
    static let labsFolderPrefix = "labs"
    static let configsFolderPrefix = "configs"

    enum Variable: String, CaseIterable {
        case resourceFolder = "resource-folder"
        case rootFolder = "root-folder"
        
        var optionKey: String {
            return "--\(self.rawValue)"
        }
        
        var environmentKey: String {
            return self.rawValue.uppercased()
        }
        
        var help: String {
            switch self {
            case .resourceFolder:
                return "Path to resource folder"
            case .rootFolder:
                return "Path to root folder"
            }
        }
    }
    
    
    let resourceBundleURL: Foundation.URL
    let rootFolderURL: Foundation.URL
    let labsFolderURL: Foundation.URL
    let configsFolderURL: Foundation.URL
    
    let environment: [String : String ]
    let arguments: [String]
    init() throws {
        
        environment = ProcessInfo.processInfo.environment
        arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())

        let parser = ArgumentParser(usage: "<options>", overview: "KrakenCL - Continuous Learning, integration, deployment server.")
        
        
        let resourceFolder: OptionArgument<String> = parser.add(option: Variable.resourceFolder.optionKey,
                                                                 shortName: nil,
                                                                 kind: String.self,
                                                                 usage: Variable.resourceFolder.help)
        
        let rootFolder: OptionArgument<String> = parser.add(option: Variable.rootFolder.optionKey,
                                                             shortName: nil,
                                                             kind: String.self,
                                                             usage: Variable.rootFolder.help)

        let parsedArguments = try parser.parse(arguments)
        
        self.resourceBundleURL = try Environment.searchURLValue(at: parsedArguments,
                                                                argument: resourceFolder,
                                                                environment: environment,
                                                                variable: Variable.resourceFolder)
        
         self.rootFolderURL = try Environment.searchURLValue(at: parsedArguments,
                                                             argument: rootFolder,
                                                             environment: environment,
                                                             variable: Variable.rootFolder)
        
        labsFolderURL = self.rootFolderURL.appendingPathComponent(Environment.labsFolderPrefix)
        configsFolderURL = self.rootFolderURL.appendingPathComponent(Environment.configsFolderPrefix)
    }
    
    static func searchURLValue(at parsedArguments: ArgumentParser.Result, argument: OptionArgument<String>, environment: [String : String], variable: Variable) throws -> Foundation.URL {
        var foundURL: Foundation.URL? = nil
        if let folderPath: String = parsedArguments.get(argument) {
            if let url = URL(string: folderPath) {
                foundURL = url
            }
        } else if let folderPath = environment[variable.environmentKey] {
            if let url = URL(string: folderPath) {
                foundURL = url
            }
        }
        
        guard let url = foundURL else {
            throw EnvironmentError.emptyParameter(parameter: variable.optionKey)
        }
        return url
    }
}
