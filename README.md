# Scoop
심플하게 만든 다운로드 라이브러리 입니다.

***

## feature
 
***

## install
    pod 'Scoop'
***

## example

    guard let connectURL = <URL> else { return }
    let download = SCOOP(identify: "Scoop", connectURL: connectURL, downloadPath: "scoop", progressHandler: { (progress) in
        print("progress - ", progress.progress)
    }) { (sucess) in
        print("sucess - ", sucess.progress)
    }
    download.resume()

***
