# Scoop
Scoop는 심플하게 만든 다운로드 라이브러리입니다. 다운받은 파일 중 압축 해제 가능한 파일 경우 자동적으로 압축 해제합니다.
Scoop is simply made for downloading files. And the downloaded files that can be unzip will be automatically unzipped. 
***

## Feature
* 다운로드 받은 파일이 zip 확장자인 경우에만 자동 압축해제 지원합니다.
* 클로저를 통해 사용이 간편합니다.

* Automatic-unzip only supports in '.zip' file.
* Simply used by closure.
***

## Install
Scoop는 Cocopods에서 다운로드가 가능합니다.
Scoop can be downloaded from Cocopods.

```swift
    pod 'Scoop'
```
사용은 Swift file 상단에서 가능합니다.
Use it at the top of the Swift file
```swift
    import Scoop
```
***

## Example
아래와 같이 다운로드 메소드 사용이 가능합니다. 
You can use download function as below.
```swift
    guard let connectURL = <URL> else { return }
    let download = SCOOP(identify: "Scoop", connectURL: connectURL, downloadPath: "scoop", progressHandler: { (progress) in
        print("progress - ", progress.progress)
    }) { (sucess) in
        print("sucess - ", sucess.progress)
    }
    download.resume()
```
***

## Contact To
질문 또는 제안이 있으면 realsilex@gmail.com(silexKhan) 또는 jakyung8@gmail.com(JakyungYoon)에게 연락바랍니다. 📨
If you have any questions or suggestions, feel free to write at realsilex@gmail.com(silexKhan) or jakyung8@gmail.com(JakyungYoon).
***
