//
//  FileViewerViewController.swift
//  Neat
//
//  Created by Sam Khavari on 6/8/15.
//  Copyright (c) 2015 Sam Khavari. All rights reserved.
//

import UIKit
import WebKit

class FileViewerViewController: UIViewController, UIWebViewDelegate {

    var parserHandler = DocxParser()
    var webView : UIWebView?
    var url = NSURL(string: "http://www.google.com")
    @IBOutlet weak var neatButton: UIBarButtonItem!
    var isNeat = false
    
    
    // Mark: View lifecycle
    
    override func loadView() {
        self.webView = UIWebView()
        self.webView?.scalesPageToFit = true
        self.webView?.delegate = self
        self.view = self.webView
        self.neatButton.enabled = false
        
        var weakSelf = self
        parserHandler.completionHandler = { html in
            weakSelf.webView?.loadHTMLString(html, baseURL: nil)
            weakSelf.isNeat = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.url?.lastPathComponent
        let req = NSURLRequest(URL: url!)
        self.webView!.loadRequest(req)
    }
    
    // Mark: WebView
    
    func webViewDidFinishLoad(webView: UIWebView) {
        self.neatButton.enabled = true
    }
    
    // Mark: Action handlers
    
    @IBAction func onNeatPressed(sender: AnyObject) {
        
        if( !isNeat ){
            SSZipArchive.unzipFileAtPath(self.filePath(), toDestination: unzipDir())
            let data = NSData(contentsOfFile: self.mainDocPath())
            let parser = NSXMLParser(data: data!)
            parser.delegate = parserHandler
            parser.parse()
            self.neatButton.enabled = false
            self.isNeat = true
        } else {
            let req = NSURLRequest(URL: url!)
            self.webView!.loadRequest(req)
            self.neatButton.enabled = false
            self.isNeat = false
        }
    }
    
    // Mark: File Paths
    
    func filePath() -> String {
        return self.url!.path!
    }
    
    func unzipDir() -> String {
        let destParent = NSTemporaryDirectory()
        let destDir = self.url?.lastPathComponent?.stringByDeletingPathExtension
        let dest = "\(destParent)/\(destDir!)"
        return dest
    }
    
    func mainDocPath() -> String {
        return "\(self.unzipDir())/word/document.xml"
    }
}
