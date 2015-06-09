//
//  FileViewerViewController.swift
//  Neat
//
//  Created by Sam Khavari on 6/8/15.
//  Copyright (c) 2015 Sam Khavari. All rights reserved.
//

import UIKit
import WebKit

class FileViewerViewController: UIViewController, UIWebViewDelegate, NSXMLParserDelegate {

    var webView : UIWebView?
    var url = NSURL(string: "http://www.google.com")
    @IBOutlet weak var neatButton: UIBarButtonItem!
    
    
    // Mark: View lifecycle
    
    override func loadView() {
        self.webView = UIWebView()
        self.webView?.scalesPageToFit = true
        self.webView?.delegate = self
        self.view = self.webView
        self.neatButton.enabled = false
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
        SSZipArchive.unzipFileAtPath(self.filePath(), toDestination: unzipDir())
        let data = NSData(contentsOfFile: self.mainDocPath())
        let parser = NSXMLParser(data: data!)
        parser.delegate = self
        parser.parse()
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
    
    // Mark: Sax parser
    
    var htmlOutput = "";
    func parserDidStartDocument(parser: NSXMLParser) {
        htmlOutput = "<html><body>"
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        htmlOutput += "</body></html>"
        println(htmlOutput)
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]) {
        println(elementName)
        switch elementName {
            case "w:p":
                htmlOutput += "<p>"
            default:
                let x = 1
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        println(elementName)
        switch elementName {
        case "w:p":
            htmlOutput += "</p>"
        default:
            let x = 1
        }
    }
    
}
