//
//  ViewController.swift
//  Scoop
//
//  Created by silexKhan on 01/28/2020.
//  Copyright (c) 2020 silexKhan. All rights reserved.
//

import UIKit
import Scoop

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    internal func initialize() {
        
        guard let connectURL = URL(string: "https://vt.tumblr.com/tumblr_o600t8hzf51qcbnq0_480.mp4") else { return }
        let download = DOWNLOAD(identify: "Scoop", connectURL: connectURL, downloadPath: "scoop", progressHandler: { (progress) in
            print("progress - ", progress.progress)
        }) { (sucess) in
            print("sucess - ", sucess.progress)
        }
        download.resume()
    }

}

