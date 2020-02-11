//
//  DOWNLOAD.swift
//  Pods
//
//  Created by Kyu Suk Ahn on 2020/01/28.
//

import Foundation


/**
 -  Note: Example Code
 
    guard let connectURL = URL(string: "https://vt.tumblr.com/tumblr_o600t8hzf51qcbnq0_480.mp4") else { return }
    let download = SCOOP(identify: "Scoop", connectURL: connectURL, downloadPath: "scoop", progressHandler: { (progress) in
        print("progress - ", progress.progress)
    }) { (sucess) in
        print("sucess - ", sucess.progress)
    }
    download.resume()
 
 */
public typealias PROGRESS_HANDLER = (SCOOP) -> Void

public class SCOOP: NSObject {    
    
    //생성시 사용되는 필수 맴버
    public var identify: String                //task 네임
    public var connectURL: URL                 //다운로드 연결한 URL
    public var useCashing: Bool                //true : 캐싱사용, false : fourced download
    public var path: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!               //다운로드 경로
    
    //생성 후 사용되는 맴버
    public var session: URLSession?
    public var task: URLSessionDownloadTask?
    public var isDownloading = false            //작업상태
    public var downloaded = false               //다운로드 완료되면 true로 변경됨
    public var resumeData: Data?                //다운로드시 생성된 Data를 저장함, 서버가 지원하면 resume가능
    public var progress: Float = 0.0            //프로그래스 0.0 ~ 1.0
    public var savedURL: URL?                   //완료되어 저장된 위치<완료되면 채워야함>
    //콜백 핸들러
    public var progressHandler: PROGRESS_HANDLER?
    public var completeHandler: PROGRESS_HANDLER?
    
    /** response 정보 */
    public var error: Error?
    public var response: HTTPURLResponse?
    
    /**
        초기화 필요한게 많다
     - parameter identify:   task로 생성될 이름
     - parameter connectURL: 다운로드 받을 URL
     - parameter completeHandler: func -     완료(에러포함) 시 받을 핸들러 모델을 돌려줌
     */
    public init(connectURL: URL, useCashing:Bool = true, progressHandler: PROGRESS_HANDLER? = nil, completeHandler: PROGRESS_HANDLER? = nil) {
        
        self.connectURL = connectURL
        self.useCashing = useCashing
        self.identify = connectURL.path
        self.progressHandler = progressHandler
        self.completeHandler = completeHandler
    }
    
    /**
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
        //로컬에 캐싱되어 있는지 확인한다. 파일이 존재하지 않을때 다운로드 받는다
        let analogyCashingURL = writeURL(basePath: getBaseDownloadURL(), requestURL: connectURL)
        guard useCashing, let hasAnalogyCashingURL = analogyCashingURL, !fileExists(at: hasAnalogyCashingURL) else {
            //지정된 위치에서 저장되는 규칙에 따라 저장된 파일이 있는지 체크한다
            //저장된 파일이 있다면 다운로드를 받지않고 로컬의 경로를 업데이트하고 SCOOP의 완료모델을 반환한다
            DispatchQueue.main.async {
                self.savedURL = analogyCashingURL
                self.completeHandler?(self)
            }
            return
        }
        
        //resumeData 없다면 처음부터 다운로드
        let configuration = URLSessionConfiguration.background(withIdentifier: identify)
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        task = session?.downloadTask(with: connectURL)
        task?.resume()
        isDownloading = true
    }
    
    /**
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
}



extension SCOOP: URLSessionDownloadDelegate, Filesable {
    
    /**
        다운로드가 완료되었을때, 임시파일상태이며 이곳에서 파일을 복사, 이동 하지 않으면 삭제됨
     */
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("didFinishDownloadingTo")
        //다운로드완료 로컬에 파일 write코드 추가
        guard let sourceURL = downloadTask.originalRequest?.url, let writeURL = writeURL(basePath: getBaseDownloadURL(for: .documents, createFolder: "scoop"), requestURL: sourceURL) else { return }
        move(at: location, to: writeURL) { (sucess, error) in
            guard sucess else {
                self.error = error
                DispatchQueue.main.async {
                    if self.fileExists(at: writeURL) {
                        self.savedURL = writeURL
                    }
                    self.completeHandler?(self)
                }
                return
            }
            self.savedURL = writeURL
            self.downloaded = sucess
        }
    }
    
    /**
     */
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("didCompleteWithError")
        guard let httpResponse = task.response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("------ HTTP Request Error : \(String(describing: error?.localizedDescription))")
            self.error = error
            DispatchQueue.main.async {
                self.completeHandler?(self)
            }
            return
        }
        response = httpResponse
        DispatchQueue.main.async {
            self.completeHandler?(self)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        self.progress = progress
        DispatchQueue.main.async {
            self.progressHandler?(self)
        }
    }
}
