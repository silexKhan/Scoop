//
//  Files.swift
//  Pods
//
//  Created by Kyu Suk Ahn on 2020/01/31.
//

import UIKit
import Combine

public protocol Filesable {}

public extension Filesable {
    
    /// FileManager 기본 인스턴스를 반환합니다.
    ///
    /// - Returns: 공유 인스턴스 FileManager
    var fileManager: FileManager {
        FileManager.default
    }
    
    /// 지정한 디렉토리 유형에 대한 경로를 반환합니다.
    ///
    /// - Parameter directory: documents, library, temporary 중 하나
    /// - Returns: 해당 디렉토리의 URL
    func url(for directory: DirectoryType) -> URL? {
        switch directory {
        case .documents:
            return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        case .library:
            return fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first
        case .temporary:
            return fileManager.temporaryDirectory
        }
    }
    
    /// 디렉토리 내에 폴더를 생성하고 다운로드 경로를 반환합니다.
    ///
    /// - Parameters:
    ///   - directory: 기준 디렉토리 (기본값은 .documents)
    ///   - folderName: 생성할 하위 폴더명 (기본값은 \"scoop\")
    /// - Returns: 생성된 경로의 URL
    func makeDownloadURL(in directory: DirectoryType = .documents, folderName: String = "scoop") -> URL? {
        guard var baseURL = url(for: directory) else { return nil }
        baseURL.appendPathComponent(folderName)
        
        if !fileManager.fileExists(atPath: baseURL.path) {
            do {
                try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
            } catch {
                print("❌ Failed to create directory: \(error.localizedDescription)")
                return nil
            }
        }
        return baseURL
    }
}

public extension Filesable {
    
    /// 해당 경로에 파일이 존재하는지 여부를 반환합니다.
    ///
    /// - Parameter url: 확인할 파일의 경로
    /// - Returns: 파일이 존재하면 true, 없으면 false
    @discardableResult
    func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
    
    /// 주어진 디렉토리 경로에서 파일 목록을 조회합니다.
    ///
    /// - Parameter directory: 대상 디렉토리 경로
    /// - Returns: 파일 이름 배열 (없으면 빈 배열)
    @discardableResult
    func listFiles(in directory: URL) -> [String] {
        (try? fileManager.contentsOfDirectory(atPath: directory.path)) ?? []
    }
    
    /// 요청 URL을 기준으로 저장될 목적지 경로를 생성합니다.
    ///
    /// - Parameters:
    ///   - base: 기준이 되는 폴더 경로
    ///   - original: 요청에 사용된 원본 URL
    /// - Returns: 생성된 목적지 URL (실패 시 nil)
    func makeDestinationURL(base: URL?, for original: URL?) -> URL? {
        guard let base = base, let fileName = original?.pathComponents.joined(separator: "") else { return nil }
        return base.appendingPathComponent(fileName)
    }
}

public extension Filesable {
    
    /// 파일을 지정된 경로로 이동합니다. 대상에 파일이 있으면 덮어씁니다.
    ///
    /// - Parameters:
    ///   - source: 원본 파일 경로
    ///   - destination: 이동될 파일 경로
    ///   - completion: 결과 콜백 (성공 여부 및 에러)
    func moveFile(from source: URL, to destination: URL, completion: ((Bool, Error?) -> Void)? = nil) {
        do {
            if fileExists(at: destination) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.moveItem(at: source, to: destination)
            print("✅ Moved to: \(destination)")
            completion?(true, nil)
        } catch {
            print("❌ Move failed: \(error.localizedDescription)")
            completion?(false, error)
        }
    }
    
    /// 파일을 지정된 경로로 복사합니다. 대상에 파일이 있으면 덮어씁니다.
    ///
    /// - Parameters:
    ///   - source: 원본 파일 경로
    ///   - destination: 복사될 파일 경로
    ///   - completion: 결과 콜백 (성공 여부 및 에러)
    func copyFile(from source: URL, to destination: URL, completion: ((Bool, Error?) -> Void)? = nil) {
        do {
            if fileExists(at: destination) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: source, to: destination)
            print("✅ Copied to: \(destination)")
            completion?(true, nil)
        } catch {
            print("❌ Copy failed: \(error.localizedDescription)")
            completion?(false, error)
        }
    }
    
    /// 지정된 경로의 파일을 삭제합니다.
    ///
    /// - Parameters:
    ///   - url: 삭제할 파일 경로
    ///   - completion: 결과 콜백 (성공 여부 및 에러)
    func deleteFile(at url: URL, completion: ((Bool, Error?) -> Void)? = nil) {
        do {
            try fileManager.removeItem(at: url)
            print("🗑️ Deleted: \(url)")
            completion?(true, nil)
        } catch {
            print("❌ Delete failed: \(error.localizedDescription)")
            completion?(false, error)
        }
    }
}
    

///비동기
public extension Filesable {
    
    /// 파일을 비동기로 이동합니다.
    ///
    /// - Parameters:
    ///   - source: 원본 파일 경로
    ///   - destination: 이동할 대상 경로
    /// - Throws: 파일 이동 실패 시 오류 발생
    func moveFileAsync(from source: URL, to destination: URL) async throws {
        if fileExists(at: destination) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: source, to: destination)
        print("✅ Moved to: \(destination)")
    }
    
    /// 파일을 비동기로 복사합니다.
    ///
    /// - Parameters:
    ///   - source: 원본 파일 경로
    ///   - destination: 복사할 대상 경로
    /// - Throws: 파일 복사 실패 시 오류 발생
    func copyFileAsync(from source: URL, to destination: URL) async throws {
        if fileExists(at: destination) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: source, to: destination)
        print("✅ Copied to: \(destination)")
    }
    
    
    /// 파일을 비동기로 삭제합니다.
    ///
    /// - Parameter url: 삭제할 파일 경로
    /// - Throws: 파일 삭제 실패 시 오류 발생
    func deleteFileAsync(at url: URL) async throws {
        try fileManager.removeItem(at: url)
        print("🗑️ Deleted: \(url)")
    }
    
}

public extension Filesable {
    
    /// Combine Future를 통해 파일 이동 작업을 수행합니다.
    ///
    /// - Parameters:
    ///   - source: 원본 파일 경로
    ///   - destination: 이동될 경로
    /// - Returns: 성공 시 destination URL을 방출하는 Future
    func moveFilePublisher(from source: URL, to destination: URL) -> Future<URL, Error> {
        Future { promise in
            do {
                if self.fileExists(at: destination) {
                    try self.fileManager.removeItem(at: destination)
                }
                try self.fileManager.moveItem(at: source, to: destination)
                print("✅ Moved to: \(destination)")
                promise(.success(destination))
            } catch {
                print("❌ Move failed: \(error.localizedDescription)")
                promise(.failure(error))
            }
        }
    }
    
    /// Combine Future를 통해 파일 삭제 작업을 수행합니다.
    ///
    /// - Parameter url: 삭제할 파일 경로
    /// - Returns: 성공 시 삭제된 URL을 방출하는 Future
    func deleteFilePublisher(at url: URL) -> Future<URL, Error> {
        Future { promise in
            do {
                try self.fileManager.removeItem(at: url)
                print("🗑️ Deleted: \(url)")
                promise(.success(url))
            } catch {
                print("❌ Delete failed: \(error.localizedDescription)")
                promise(.failure(error))
            }
        }
    }
}

