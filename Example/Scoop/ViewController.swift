//
//  ViewController.swift
//  Scoop
//
//  Created by silexKhan on 01/28/2020.
//  Copyright (c) 2020 silexKhan. All rights reserved.
//

import UIKit
import Scoop

class DownloadTableViewCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var descript: UILabel!
    @IBOutlet weak var progress: UIProgressView!
    var data:SCOOP?
    
    internal func updateState(model: SCOOP) {
        
        var stateDescription: String = ""
        switch model.result {
        case .CACHED :          stateDescription = "이미 저장된 파일이 존재합니다."
        case .DOWNLOADING :     stateDescription = "다운로드 중입니다."
        case .DOWNLOADED :      stateDescription = "다운로드가 완료되었습니다."
        case .PAUSED :          stateDescription = "정지합니다."
        case .ERROR :           stateDescription = "ERROR - \(model.error?.localizedDescription ?? "")"
        }
        descript.text = stateDescription
    }
    
    internal func updateModel(model: SCOOP) {
        
        guard data?.identify != model.identify else { return }
        data = model
        title.text = model.identify
        updateState(model: model)
        progress.progress = model.progress
        model.progressHandler = { result in
            print("progress - ", result.progress)
            self.progress.progress = result.progress
        }
        model.completeHandler = { result in
            self.updateState(model: result)
            //self.backgroundColor = .cyan
            print("completeHandler saved - ", result.savedURL?.path ?? "")
        }
        model.resume()
    }
}

class ViewController: UIViewController, Filesable {
    
    @IBOutlet weak var tableview: UITableView!
    
    lazy var searchController = UISearchController(searchResultsController: nil)
    
    var downloads: [SCOOP] = []
    
    var dummyIndex: Int = 0
    let dummy: [String] = ["https://homebrew.bintray.com/bottles/ffmpeg-4.2.2_1.catalina.bottle.tar.gz", "https://www.videoproc.com/download/videoproc-4k.dmg", "https://homebrew.bintray.com/bottles/ffmpeg-4.2.2_1.high_sierra.bottle.tar.gz"]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initialize()
    }
    
    internal func initialize() {
     
        initializeSearchBar()
    }
    
    internal func initializeSearchBar() {
        
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "append download url"
        searchController.searchBar.autocapitalizationType = .none
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    @IBAction func addTouchUpHandler(_ sender: UIButton) {
        
        dummyIndex = dummyIndex >= dummy.count ? 0 : dummyIndex
        if let url = URL(string: dummy[dummyIndex]) {
            downloads.append(SCOOP(connectURL: url))
        }
        tableview.reloadData()
        dummyIndex += 1
    }
    
    @IBAction func deleteLocalCacheing(_ sender: UIButton) {
        
        if let baseURL = getBaseDownloadURL() {
            remove(at: baseURL)
        }
    }
    
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return downloads.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "defaultCell", for: indexPath) as? DownloadTableViewCell else {
            return UITableViewCell()
        }
        cell.updateModel(model: downloads[indexPath.row])
        return cell
    }
}


extension ViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print(searchBar.text)
    }
}
