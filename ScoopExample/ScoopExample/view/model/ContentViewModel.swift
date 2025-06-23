//
//  ContentViewModel.swift
//  ScoopExample
//
//  Created by ahn kyu suk on 6/23/25.
//

import Foundation
import Combine
import Scoop

final class ContentViewModel: ObservableObject {
    @Published var inputURLString: String = ""
    @Published var progress: Double = 0.0
    @Published var savedFileName: String? = nil
    @Published var isDownloading: Bool = false

    private var scoop = Scoop()
    private var cancellables = Set<AnyCancellable>()

    init() {
        bind()
        inputURLString = "https://upload.wikimedia.org/wikipedia/commons/7/72/%22%2430_every_Thursday%22_pension_plan_out_as_President_discusses_political_situation_with_California_candidates._Washington%2C_D.C.%2C_Sept._27._Sheridan_Downey%2C_who_defeated_Senator_William_Gibbs_LCCN2016874059.tif"
    }

    private func bind() {
        scoop.progress
            .receive(on: RunLoop.main)
            .assign(to: &$progress)

        scoop.completed
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("다운로드 실패: \(error.localizedDescription)")
                    }
                    self?.isDownloading = false
                },
                receiveValue: { [weak self] url in
                    self?.savedFileName = url.lastPathComponent  // ✅ 여기서 파일명 업데이트
                    self?.isDownloading = false
                }
            )
            .store(in: &cancellables)
    }

    func startDownload() {
        guard let url = URL(string: inputURLString) else { return }
        isDownloading = true
        scoop.resume(url: url)
    }

    func pause() {
        scoop.pause()
        isDownloading = false
    }

    func reset() {
        inputURLString = ""
        progress = 0.0
        savedFileName = nil
        isDownloading = false
    }
}
