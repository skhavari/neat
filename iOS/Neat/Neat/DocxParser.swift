//
//  DocxParser.swift
//  Neat
//
//  Created by Sam Khavari on 6/9/15.
//  Copyright (c) 2015 Sam Khavari. All rights reserved.
//

import Foundation




class DocxParser : NSObject, NSXMLParserDelegate {
    
    typealias CompletionBlock = String -> Void
    var completionHandler : CompletionBlock!
    
    var htmlOutput = "";
    var currentBlock = Block()
    var indent = 0
    var isText = false
    
    static let htmlHeader = DocxParser.loadHeader()
    static let htmlFooter = DocxParser.loadFooter()
    
    // Mark: NSXMLParserDelegate
    
    func parserDidStartDocument(parser: NSXMLParser) {
        debug("start")
        htmlOutput = DocxParser.htmlHeader
        currentBlock = Block()
        indent = 0
        isText = false
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        debug("end")
        htmlOutput += DocxParser.htmlFooter
        
        if let handler = completionHandler {
            handler(htmlOutput)
        }
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]) {
        indent += 4
        debug("start \(elementName)")
        
        switch elementName {
        case DocxParser.wpPara: self.startPara()
        case DocxParser.wpParaStyle: self.startParaStyle(attributeDict)
        case DocxParser.wpText: isText = true
        case DocxParser.wpNumberedListProps: self.startList()
        default: ()
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

        debug("end \(elementName)")
        
        switch elementName {
        case DocxParser.wpPara: self.endPara()
        case DocxParser.wpText: isText = false
        default: ()
        }
        
        indent -= 4
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String?) {

        if let msg = string {
            if isText {
                indent += 4
                debug(msg)
                self.currentBlock.text += msg
                indent -= 4
            }
        }
    }
    
    
    // Mark: Internal Parser Handlers
    
    private func startPara(){
        currentBlock = DocxParser.blocks["Default"]!
    }
    
    private func endPara(){
        htmlOutput += currentBlock.toHtml()
    }
    
    private func startParaStyle(attributeDict: [NSObject : AnyObject]) {
        indent += 4
        debug("\(attributeDict)")
        indent -= 4
        
        if let styleVal = attributeDict[DocxParser.wpAttrVal] as? String {
            if let b = DocxParser.blocks[styleVal] {
                currentBlock.start = b.start
                currentBlock.end = b.end
            }
        }
    }
    
    private func startList() {
        currentBlock.start = "<li>"
        currentBlock.end = "</li>"
    }
    
    
    
    
    
    
    // Mark: Block definition & mapping
    
    struct Block {
        var start = ""
        var end   = ""
        var text  = ""
        
        func toHtml() -> String {
            return "\(start)\(text)\(end)"
        }
    }
    
    static let blocks = [
        "Default"       : Block(start: "<p>" , end: "</p>" , text: ""),
        "DocumentTitle" : Block(start: "<h1>", end: "</h1>", text: ""),
        "Title"         : Block(start: "<h1>", end: "</h1>", text: ""),
        "Heading1"      : Block(start: "<h1>", end: "</h1>", text: ""),
        "Heading2"      : Block(start: "<h2>", end: "</h2>", text: ""),
        "Heading3"      : Block(start: "<h3>", end: "</h3>", text: ""),
        "Heading4"      : Block(start: "<h4>", end: "</h4>", text: ""),
        "Heading5"      : Block(start: "<h5>", end: "</h5>", text: "")
    ]
    
    // Mark: WordProcessing ML tags & attribute names
    
    static let wpPara = "w:p"
    static let wpParapProps = "w:pPr"
    static let wpRun = "w:r"
    static let wpText = "w:t"
    static let wpParaStyle = "w:pStyle"
    static let wpAttrVal = "w:val"
    static let wpNumberedListProps = "w:numPr"
    
    
    func debug(msg: String){
//        let indentation = String(count: self.indent, repeatedValue: Character(" "))
//        println("    DocxParser:    \(indentation)\(msg)")
    }
    
    
    private static func loadHeader() -> String {
        let path = NSBundle.mainBundle().pathForResource("header.tmpl", ofType: "html")
        return String(contentsOfFile: path!, encoding: NSUTF8StringEncoding, error: nil)!
    }
    
    private static func loadFooter() -> String {
        let path = NSBundle.mainBundle().pathForResource("footer.tmpl", ofType: "html")
        return String(contentsOfFile: path!, encoding: NSUTF8StringEncoding, error: nil)!
    }
    
    
}