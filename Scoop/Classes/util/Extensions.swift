//
//  Extensions.swift
//  Pods
//
//  Created by Kyu Suk Ahn on 2020/02/03.
//

import Foundation

extension URL {
    
    public enum FILE_TYPE {
        case file
        case directory
        case not
    }

    public var type: FILE_TYPE {
        get {
            var _type: FILE_TYPE = .not
            var directory: ObjCBool = false
            if FileManager.default.fileExists(atPath: self.path, isDirectory: &directory) {
                _type = directory.boolValue ? .directory : .file
            }
            return _type
        }
    }
}
