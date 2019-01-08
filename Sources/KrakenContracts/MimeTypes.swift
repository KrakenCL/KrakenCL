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

public enum MimeTypes {
    public static let `default` = "text/plain"

    public static let `extension` = ["bmp" : ["image/bmp"],
                                     "doc" : ["application/msword"],
                                     "docx" : ["application/vnd.openxmlformats-officedocument.wordprocessingml.document"],
                                     "html" : ["text/html"],
                                     "ico" : ["image/x-icon"],
                                     "jpeg" : ["image/jpeg"],
                                     "gif" : ["image/gif"],
                                     "m1v" : ["video/mpeg"],
                                     "mov" : ["video/quicktime"],
                                     "mp3" : ["audio/mpeg3", "audio/x-mpeg-3"],
                                     "mp4" : ["video/mp4"],
                                     "pic" : ["image/pict"],
                                     "png" : ["image/png"],
                                     "ppt" : ["application/vnd.openxmlformats-officedocument.presentationml.presentation", "application/mspowerpoint"],
                                     "pptx" : ["application/vnd.openxmlformats-officedocument.presentationml.presentation", "application/vnd.ms-powerpoint"],
                                     "rtf" : ["application/x-rtf", "text/richtext", "application/rtf"],
                                     "txt" : ["text/plain"],
                                     "xls" : ["application/vnd.ms-excel"],
                                     "xlsx" : ["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"],
                                     "pdf" : ["application/pdf"],
                                     "css" : ["text/css"],
                                     "js" : ["application/javascript"]]
    public enum Extension: String {
        public static let `default` = Extension.txt
        
        case bmp
        case doc
        case docx
        case html
        case ico
        case jpeg
        case gif
        case m1v
        case mov
        case mp3
        case mp4
        case pic
        case png
        case ppt
        case pptx
        case rtf
        case txt
        case xls
        case xlsx
        case pdf
        case js
        case css
        
        public init(value: String) {
            self = Extension.default
            if let type = Extension(rawValue: value) {
                self = type
            }
        }
        
        public var mimeType: String {
            if let type = MimeTypes.extension[self.rawValue]?.first {
                return type
            } else {
                return MimeTypes.default
            }
        }
    }
}
