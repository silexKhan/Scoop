# Scoop

Swift 기반의 경량 파일 다운로드 유틸리티입니다.  
Combine과 async/await을 모두 지원하며, 다운로드 일시정지 및 이어받기(resume) 기능을 제공합니다.

## Features

- Combine을 활용한 다운로드 진행률 및 완료 이벤트 제공  
- async/await 방식 다운로드 지원  
- 일시정지 후 resumeData를 디스크에 저장  
- 앱 재실행 후 이어받기 가능  
- `Accept-Ranges: bytes` 응답 헤더 자동 체크로 이어받기 가능 여부 판단  
- 다운로드 파일은 문서 디렉토리에 자동 저장 (기존 파일 자동 덮어쓰기)

## Installation

### Swift Package Manager

```swift
.package(url: "https://github.com/silexKhan/Scoop.git", from: "1.0.0")
```

또는 Xcode에서:

**Xcode > File > Add Packages**  
다음 URL을 추가하세요:

```
https://github.com/silexKhan/Scoop.git
```

## Usage

### Combine 방식 다운로드

```swift
import Scoop

let scoop = Scoop()

scoop.progress
    .sink { percent in
        print("Progress: \(percent * 100)%")
    }
    .store(in: &cancellables)

scoop.completed
    .sink(receiveCompletion: { completion in
        if case let .failure(error) = completion {
            print("Error: \(error)")
        }
    }, receiveValue: { fileURL in
        print("Downloaded to: \(fileURL)")
    })
    .store(in: &cancellables)

scoop.resume(url: URL(string: "https://example.com/sample.pdf")!)
```

### async/await 방식 다운로드

```swift
let scoop = Scoop()

Task {
    do {
        let result = try await scoop.resumeAsync(url: URL(string: "https://example.com/sample.pdf")!)
        print("Downloaded to: \(result)")
    } catch {
        print("Error: \(error)")
    }
}
```

### 일시정지 및 이어받기

```swift
scoop.pause() // 다운로드 중단 및 resumeData 저장
scoop.resume(url: ...) // 자동 이어받기 판단 후 다운로드 재개
```

## 저장 위치

다운로드된 파일은 앱의 문서 디렉토리 내 다음 위치에 저장됩니다:

```
<앱 DocumentDirectory>/scoop/<파일명>
```

기존 동일한 파일이 있으면 자동으로 덮어씌워집니다.

## Resume 동작 조건

- 서버가 `Accept-Ranges: bytes` 헤더를 응답해야 합니다.
- 이어받기 요청 시 서버가 `206 Partial Content` 응답을 해야 합니다.
- `resumeData`는 임시 디렉토리에 저장되며 앱 재실행 후에도 이어받기에 사용됩니다.

## Example App

`Scoop/Example` 경로에 SwiftUI 기반 테스트 앱이 포함되어 있습니다.  
직접 URL 입력 후 다운로드 / 일시정지 / 이어받기 시나리오를 확인할 수 있습니다.

## Requirements

- iOS 13+
- Swift 5.5+
- macOS 10.15+

## License

MIT License

## Author

**Kyusuk Ahn** ([@silexKhan](https://github.com/silexKhan))
