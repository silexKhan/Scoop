//
//  Files.swift
//  Pods
//
//  Created by Kyu Suk Ahn on 2020/01/31.
//

import UIKit

/**
 참고
 - link : http://iosbrain.com/blog/2018/04/22/ios-file-management-with-filemanager-in-protocol-oriented-swift-4/
 
 앱 샌드박스 구조(간략)
    Documents
    Library
        Caches
        Preferences
        Saved Application State
        SplashBoard
    SystemData
    tmp(download temp file)
 
 개발요구정의
    - 디렉토리생성, 조회, 관리
    - 파일이동, 복사, 삭제
    - URL키 캐싱
 */

public enum DIRECTORIES: String {
    
    case documents = "Documents"
    case library = "Library"
    case temp = "tmp"
}

public protocol Filesable {     }

public extension Filesable {
    
    internal func documentsDirectoryURL() -> URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    internal func libraryDirectoryURL() -> URL? {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
    }
    
    internal func tempDirectoryURL() -> URL? {
        
        if #available(iOS 10.0, *) {
            return FileManager.default.temporaryDirectory
        } else {
            // Fallback on earlier versions
            return nil
        }
    }
    
    /**
        -   Parameter directory : 정의된 타입
        - Parameter createFolder : 폴더를 생성하냐? 1뎁스만 생성하자
     */
    func getBaseDownloadURL(for directory: DIRECTORIES, createFolder: String? = nil) -> URL? {
        //SendBox내 기본 디렉토리 URL리턴
        func getTypeURL(type: DIRECTORIES) -> URL? {
            switch type {
            case .documents:    return documentsDirectoryURL()
            case .library:      return libraryDirectoryURL()
            case .temp:         return tempDirectoryURL()
            }
        }
        //기본디렉토리에 생상할 폴더가 있는지 체크해서 생성 후 URL 반환
        guard var typeURL = getTypeURL(type: directory) else {  return nil  }
        if let folder = createFolder {
            typeURL = typeURL.appendingPathComponent(folder)
            do {
                if typeURL.type == .not {
                    try FileManager.default.createDirectory(at: typeURL, withIntermediateDirectories: true, attributes: nil)
                }
            } catch let error {
                print("Could not copy file to disk: \(error.localizedDescription)")
                return nil
            }
        }
        return typeURL
    }
    
    func writeURL(basePath: URL?, requestURL: URL?) -> URL? {
        
        guard let hasBasePath = basePath, let hasRequestURL = requestURL else { return nil }
        return hasBasePath.appendingPathComponent(hasRequestURL.lastPathComponent)
    }
    
    //파일 이동, 복사, 삭제
    /**
    move메서드는 overwrite를 기본으로 한다
     -  Parameter from : 이동할 파일의 위치
     - Parameter to : 이동될 파일의 위치
     */
    func move(at: URL, to: URL, completeHandler: ((Bool) -> Void)? = nil) {
        
        let manager = FileManager.default
        do {
            try manager.removeItem(at: to)
            try manager.moveItem(at: at, to: to)
            completeHandler?(true)
            print("move sucess - \(to)")
        } catch let error {
            print("move error - \(error.localizedDescription)")
            completeHandler?(false)
        }
    }
    
    func copy(at: URL, to: URL, completeHandler: ((Bool) -> Void)? = nil) {
        
        let manager = FileManager.default
        do {
            try manager.removeItem(at: to)
            try manager.copyItem(at: at, to: to)
            completeHandler?(true)
            print("copy sucess - \(to)")
        } catch let error {
            print("copy error - \(error.localizedDescription)")
            completeHandler?(false)
        }
    }
    
    func remove(at: URL, completeHandler: ((Bool) -> Void)? = nil) {
        
        let manager = FileManager.default
        do {
            try manager.removeItem(at: at)
            completeHandler?(true)
            print("remove sucess - \(at)")
        } catch let error {
            print("remove error - \(error.localizedDescription)")
            completeHandler?(false)
        }
    }
}
