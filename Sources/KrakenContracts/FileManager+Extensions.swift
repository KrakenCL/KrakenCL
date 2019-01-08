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

public enum FileManagerCustomError: Error {
    case canNotCreateFolder(path: URL)
}

extension FileManager {
    public static func checkAndCreateFolder(_ folder: URL) throws {
        var folder = folder
        if folder.scheme == nil {
            folder = URL(string: "file://" + folder.absoluteString)!
        }
        var isFolder: ObjCBool = true
        if !self.default.fileExists(atPath: folder.path, isDirectory: &isFolder) {
            
            try self.default.createDirectory(at: folder,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        }
        
        #if os(Linux)
        if !isFolder {
            throw FileManagerCustomError.canNotCreateFolder(path: folder)
        }
        #else
        if isFolder.boolValue == false {
            throw FileManagerCustomError.canNotCreateFolder(path: folder)
        }
        #endif
    }
}
