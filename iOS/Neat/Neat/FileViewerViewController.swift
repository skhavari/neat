//
//  FileViewerViewController.swift
//  Neat
//
//  Created by Sam Khavari on 6/8/15.
//  Copyright (c) 2015 Sam Khavari. All rights reserved.
//

import UIKit
import WebKit

class FileViewerViewController: UIViewController {

    var webView : UIWebView?
    var url = NSURL(string: "http://www.google.com")
    
    override func loadView() {
        self.webView = UIWebView()
        self.webView?.scalesPageToFit = true
        self.view = self.webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.url?.lastPathComponent
        let req = NSURLRequest(URL: url!)
        self.webView!.loadRequest(req)
    }
}
