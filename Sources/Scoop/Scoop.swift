//
//  Scoop.swift
//  Scoop
//
//  Created by Kyu Suk Ahn on 2025/06/23.
//

import Foundation
import Combine

/*
 Scoop

 파일 다운로드를 Combine 및 async/await 기반으로 처리하는 유틸리티 클래스입니다.

 - Description:
   - 파일 다운로드를 Combine 퍼블리셔 또는 async 방식으로 처리
   - 일시정지(pause), 이어받기(resume) 기능 지원
   - 서버가 `Accept-Ranges: bytes`를 응답하는지 자동 체크하여 이어받기 가능 여부 판단
   - 디스크에 resumeData를 저장하여 앱 재실행 후에도 이어받기 가능

 - Usage Example:
 ```swift
 let scoop = Scoop()
 scoop.resume(url: downloadURL)
 */
public final class Scoop: NSObject, ObservableObject, Filesable {

    // MARK: - Public Publisher

    public let progress = PassthroughSubject<Double, Never>()
    public let completed = PassthroughSubject<URL, Error>()

    // MARK: - Private

    private var continuation: CheckedContinuation<URL, Error>?
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    private var downloadTask: URLSessionDownloadTask?

    private let resumeDataCachePath: URL = {
        let directory = FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("resume_data.cache")
    }()


    /// 다운로드 시작 (Combine 방식)
    ///
    /// - Parameter url: 다운로드할 원격 파일 URL
    /// - Note: 다운로드 시작 전, 로컬에 이미 파일이 있는지 확인하여 캐시처럼 동작합니다.
    public func resume(url: URL) {
        // 1. 캐시 확인: 해시된 파일명이 이미 존재하는지 확인
        guard let downloadDir = makeDownloadURL() else {
            let error = NSError(domain: "ScoopError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create download directory."])
            completed.send(completion: .failure(error))
            continuation?.resume(throwing: error)
            return
        }
        
        let hashedName = hashedFileName(for: url)
        let finalURL = downloadDir.appendingPathComponent(hashedName)

        if fileExists(at: finalURL) {
            print("[Scoop] 파일이 이미 존재합니다 (캐시 히트) → \(finalURL.lastPathComponent)")
            completed.send(finalURL)
            continuation?.resume(returning: finalURL)
            return
        }
        
        // 2. 캐시가 없으면 다운로드 진행
        checkResumableSupport(for: url) { [weak self] isResumable in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if isResumable, let savedResumeData = try? Data(contentsOf: self.resumeDataCachePath) {
                    print("[Scoop] resumeData 존재 + 서버 지원 → 이어받기 시도")
                    self.downloadTask = self.session.downloadTask(withResumeData: savedResumeData)
                } else {
                    print("[Scoop] resume 불가 또는 resumeData 없음 → 새로 다운로드 시작")
                    self.downloadTask = self.session.downloadTask(with: url)
                }

                print("[Scoop] downloadTask resume 시작")
                self.downloadTask?.resume()
            }
        }
    }

    /// 다운로드 일시정지 및 resumeData 저장
    ///
    /// - Note: 현재 다운로드 중인 작업을 일시정지하고, resumeData를 디스크에 저장합니다.
    public func pause() {
        downloadTask?.cancel(byProducingResumeData: { [weak self] data in
            guard let self = self, let data = data else {
                print("[Scoop] pause 실패 – resumeData 없음")
                return
            }
            do {
                try data.write(to: self.resumeDataCachePath)
                print("[Scoop] resumeData 저장 완료: \(self.resumeDataCachePath.lastPathComponent)")
            } catch {
                print("[Scoop] resumeData 저장 실패: \(error.localizedDescription)")
            }
        })
    }

    /// resumeData 캐시 파일 삭제
    ///
    /// - Note: resumeData 파일이 존재하는 경우 삭제하며, 이어받기 실패나 완료 시 호출됩니다.
    private func clearResumeCacheIfNeeded() {
        do {
            try FileManager.default.removeItem(at: resumeDataCachePath)
            print("[Scoop] resumeData 캐시 삭제됨")
        } catch {
            // 에러 무시
        }
    }

    
    /// 서버의 resume 지원 여부 확인
    ///
    /// - Parameter url: 확인할 원격 파일 URL
    /// - Parameter completion: `true`면 이어받기 가능, `false`면 불가능
    /// - Note: HEAD 요청을 통해 `Accept-Ranges` 헤더가 "bytes"인지 확인합니다.
    public func checkResumableSupport(for url: URL, completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: request) { _, response, _ in
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false)
                return
            }

            let acceptRanges = httpResponse.allHeaderFields["Accept-Ranges"] as? String ?? ""
            let isResumable = acceptRanges.lowercased() == "bytes"
            print("[Scoop] Accept-Ranges '\(acceptRanges)' → resume 가능 여부: \(isResumable)")
            completion(isResumable)
        }.resume()
    }
}

// MARK: - URLSessionDownloadDelegate

extension Scoop: URLSessionDownloadDelegate {

    /// 이어받기 시도 결과 처리
    ///
    /// - Parameters:
    ///   - fileOffset: 이어받은 시작 바이트 오프셋
    ///   - expectedTotalBytes: 전체 파일 크기
    /// - Note: offset이 0이면서 statusCode가 200이면 resume 실패로 간주하여 resumeData를 삭제합니다.
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                           didResumeAtOffset fileOffset: Int64,
                           expectedTotalBytes: Int64) {
        print("[Scoop] 이어받기 시도됨 → offset: \(fileOffset), expected: \(expectedTotalBytes)")

        if let response = downloadTask.response as? HTTPURLResponse {
            print("[Scoop] 서버 응답 상태 코드: \(response.statusCode)") // 206이어야 정상
        }

        if fileOffset == 0 {
            if let httpResponse = downloadTask.response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                print("[Scoop] 서버가 resume 요청을 무시하고 전체 파일 응답 → resume 불가")
            }
            print("[Scoop] 이어받기 실패로 판단됨 → resumeData 삭제")
            clearResumeCacheIfNeeded()
        }
    }
    
    /// 다운로드 진행률 전송
    ///
    /// - Parameters:
    ///   - bytesWritten: 새로 받은 바이트 수
    ///   - totalBytesWritten: 지금까지 받은 총 바이트 수
    ///   - totalBytesExpectedToWrite: 전체 파일 크기
    /// - Note: 퍼센트 계산 후 `progress` 퍼블리셔로 전송
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let percent = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progress.send(percent)
    }

    /// 다운로드 완료 처리
    ///
    /// - Parameter location: 임시로 저장된 다운로드 파일 위치
    /// - Note: Document 디렉토리로 이동 후 `completed` 퍼블리셔 또는 continuation 으로 알림
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {
        
        defer { clearResumeCacheIfNeeded()  }
        
        guard let sourceURL = downloadTask.originalRequest?.url else {
            let error = NSError(domain: "ScoopError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Original URL not found in download task."])
            completed.send(completion: .failure(error))
            continuation?.resume(throwing: error)
            return
        }
        
        do {
            guard let folder = makeDownloadURL() else {
                let error = NSError(domain: "ScooError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create download directory."])
                throw error
            }

            let fileName = hashedFileName(for: sourceURL)
            let finalURL = folder.appendingPathComponent(fileName)

            if fileManager.fileExists(atPath: finalURL.path) {
                try fileManager.removeItem(at: finalURL)
            }

            try fileManager.moveItem(at: location, to: finalURL)
            print("[Scoop] 다운로드 완료 및 파일 이동 → \(finalURL.lastPathComponent)")
            completed.send(finalURL)
            continuation?.resume(returning: finalURL)
            continuation = nil

        } catch {
            print("[Scoop] 파일 이동 실패: \(error.localizedDescription)")
            completed.send(completion: .failure(error))
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}
