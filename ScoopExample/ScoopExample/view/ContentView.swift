//
//  ContentView.swift
//  ScoopExample
//
//  Created by ahn kyu suk on 6/23/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Scoop Downloader")
                .font(.title)

            HStack {
                TextField("", text: $viewModel.inputURLString)
                    .focused($isFocused)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                if !viewModel.inputURLString.isEmpty {
                    Button {
                        viewModel.inputURLString = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)

            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .frame(width: 250)

            if let fileName = viewModel.savedFileName {
                Text("저장 위치: \(fileName)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }

            HStack {
                Button(viewModel.isDownloading ? "Pause" : "Download") {
                    if viewModel.isDownloading {
                        viewModel.pause()
                    } else {
                        isFocused = false // ✅ 키보드 포커스 해제
                        viewModel.startDownload()
                    }
                }

                Button("Clear") {
                    viewModel.reset()
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
