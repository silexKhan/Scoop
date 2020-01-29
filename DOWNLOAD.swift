//
//  DOWNLOAD.swift
//  Pods
//
//  Created by Kyu Suk Ahn on 2020/01/28.
//

import Foundation

//콜백타입 선언
public typealias PROGRESS_HANDLER = (DOWNLOAD) -> Void

public class DOWNLOAD: NSObject, URLSessionDownloadDelegate {
    
    //생성시 사용되는 필수 맴버
    public var identify: String                //task 네임
    public var connectURL: URL                 //다운로드 연결한 URL
    public var path: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!               //다운로드 경로
    
    //생성 후 사용되는 맴버
    public var session: URLSession?
    public var task: URLSessionDownloadTask?
    public var isDownloading = false            //작업상태
    public var downloaded = false               //다운로드 완료되면 true로 변경됨
    public var resumeData: Data?                //다운로드시 생성된 Data를 저장함, 서버가 지원하면 resume가능
    public var progress: Float = 0.0            //프로그래스 0.0 ~ 1.0
    //콜백 핸들러
    public var progressHandler: PROGRESS_HANDLER?
    public var completeHandler: PROGRESS_HANDLER?
    
    //response 정보
    public var error: Error?
    public var response: HTTPURLResponse?
    /*
     @param identify: String -          task로 생성될 이름
     @param connectURL: URL -           다운로드 받을 URL
     @param downloadPath: String -      저장할 로컬 경로
     @param completeHandler: func -     완료(에러포함) 시 받을 핸들러 모델을 돌려줌
     */
    public init(identify: String, connectURL: URL, downloadPath: String, progressHandler: @escaping PROGRESS_HANDLER, completeHandler: @escaping PROGRESS_HANDLER) {
        
        self.identify = identify
        self.connectURL = connectURL
        path.appendPathComponent(downloadPath)
        self.progressHandler = progressHandler
        self.completeHandler = completeHandler
    }
    
    /*
     다운로드를 시작(재개)함
        MEMO : downloadTask(with: {}, completionHandler: {} ) 사용 시 "Completion handler blocks are not supported in background sessions. Use a delegate instead" 에러 발생
     */
    public func resume() {
        
        guard resumeData == nil else {
            //resumeData 데이터가 있으면 재개함
            task = session?.downloadTask(withResumeData: resumeData!)
            task?.resume()
            isDownloading = true
            return
        }
        //resumeData 없다면 처음부터 다운로드
        let configuration = URLSessionConfiguration.background(withIdentifier: identify)
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        task = session?.downloadTask(with: connectURL)
        task?.resume()
        isDownloading = true
    }
    
    /*
     다운로드 일시중지
     */
    public func pause() {
        
        task?.cancel { resumeDataOrNil in
            guard let resumeData = resumeDataOrNil else {
              print("Download cannot be resumed.")
              return
            }
            self.resumeData = resumeData
        }
        isDownloading = false
    }
    
    
    /*  implements URLSessionDownloadDelegate */
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        //다운로드 받을 url에서 lastPath를 잘라서 파일명으로 사용한다
        func localFilePath(for url: URL) -> URL {
            return path.appendingPathComponent(url.lastPathComponent)
        }
        let fileManager = FileManager.default
        //다운로드완료 로컬에 파일 write코드 추가
        guard let sourceURL = downloadTask.originalRequest?.url else { return }
        let writeURL = localFilePath(for: sourceURL)
        do {
            //폴더만들고 파일쓴다, TODO : 디렉토리 관련 메서드 프로토콜로 빼서 만들자 ( 자경이 작업 )
            try fileManager.createDirectory(atPath: path.path, withIntermediateDirectories: true, attributes: nil)
            try fileManager.moveItem(at: location, to: writeURL)
            downloaded = true
        } catch let error {
            print("Could not copy file to disk: \(error.localizedDescription)")
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        guard error == nil else {
            print("------ HTTP Request Error : \(String(describing: error?.localizedDescription))")
            return
        }
        guard let httpResponse = task.response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            self.error = error
            completeHandler?(self)
            return
        }
        response = httpResponse
        completeHandler?(self)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        self.progress = progress
        progressHandler?(self)
    }
    
    
}



