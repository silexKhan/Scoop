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
 
 App SandBox Struct(간략)
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
    func getBaseDownloadURL(for directory: DIRECTORIES = .documents, createFolder: String = "scoop") -> URL? {
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
        typeURL = typeURL.appendingPathComponent(createFolder)
        do {
            if typeURL.type == .not {
                try FileManager.default.createDirectory(at: typeURL, withIntermediateDirectories: true, attributes: nil)
            }
        } catch let error {
            print("Could not copy file to disk: \(error.localizedDescription)")
            return nil
        }
        return typeURL
    }
    
    /**
     지정된 경로에 존재하는 파일의 리스트를 보여줌
        - Parameter directory : 리스트를 확인할 폴더 경로
     */
    func list(directory at: URL) -> Bool {
        
        guard let listing = try? FileManager.default.contentsOfDirectory(atPath: at.path), listing.count > 0 else {
            return false
        }
        print("\n----------------------------")
        print("LISTING: \(at.path)\n")
        for file in listing {
            print("File: \(file.debugDescription)")
        }
        print("\n----------------------------\n")
        return true
    }
    
    /**
     지정된 경로에 다운로드한 파일의 path components로 파일이 저장될 경로와 파일명 확장자까지 만듬 (pathComponents으로 하는 이유는 lastComponents 이름은 같고 full path 다른 경우를 나누기 위해서)
     requestURL에 파일명 또는 확장자가 포함되지 않았다면 추가해줘야함
     - Parameter basePath : 베이스가 되는 경로명
     - Parameter requestURL : 다운로드한 요청한 URL
     */
    func writeURL(basePath: URL?, requestURL: URL?) -> URL? {
        
        guard let hasBasePath = basePath, let hasRequestURL = requestURL?.pathComponents.joined(separator: "") else { return nil }
        return hasBasePath.appendingPathComponent(hasRequestURL)
    }
    
    /**
     로컬에 파일이 존재하는지 체크함
     - Parameter at : 파일이 있을것으로 추정되는 로컬 경로
     */
    func fileExists(at: URL) -> Bool {
        
        return FileManager.default.fileExists(atPath: at.path)
    }
    
    /**
    파일을 이동한다, 중복파일에 대한 처리는 overwrite를 기본으로 한다
     -  Parameter at : 이동할 파일의 위치
     - Parameter to : 이동될 파일의 위치
     */
    func move(at: URL, to: URL, completeHandler: ((Bool, Error?) -> Void)? = nil) {
        
        let manager = FileManager.default
        do {
            if self.fileExists(at: to) {
                try manager.removeItem(at: to)
            }
            try manager.moveItem(at: at, to: to)
            completeHandler?(true, nil)
            print("move sucess - \(to)")
        } catch let error {
            print("move error - \(error.localizedDescription)")
            completeHandler?(false, error)
        }
    }
    
    /**
    파일을 복사한다, 중복파일에 대한 처리는 overwrite를 기본으로 한다
     -  Parameter at : 복사할 파일의 위치
     - Parameter to : 복사될 파일의 위치
     */
    func copy(at: URL, to: URL, completeHandler: ((Bool, Error?) -> Void)? = nil) {
        
        let manager = FileManager.default
        do {
            if fileExists(at: to) {
                try manager.removeItem(at: to)
            }
            try manager.copyItem(at: at, to: to)
            completeHandler?(true, nil)
            print("copy sucess - \(to)")
        } catch let error {
            print("copy error - \(error.localizedDescription)")
            completeHandler?(false, error)
        }
    }
    
    /**
    파일을 삭제한다,
     -  Parameter at : 삭제할 파일의 위치
     */
    func remove(at: URL, completeHandler: ((Bool, Error?) -> Void)? = nil) {
        
        let manager = FileManager.default
        do {
            try manager.removeItem(at: at)
            completeHandler?(true, nil)
            print("remove sucess - \(at)")
        } catch let error {
            print("remove error - \(error.localizedDescription)")
            completeHandler?(false, error)
        }
    }
}
