//
//  FilesTableViewController.swift
//  Neat
//
//  Created by Sam Khavari on 6/8/15.
//  Copyright (c) 2015 Sam Khavari. All rights reserved.
//

import UIKit

class FilesTableViewController: UITableViewController {
    
    var parentDir =  ""
    var files : [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let resourcePath = NSBundle.mainBundle().resourcePath {
            self.parentDir = "\(resourcePath)/samples"
            let enumerator = NSFileManager.defaultManager().enumeratorAtPath(self.parentDir)
            while let item = enumerator?.nextObject() as? String {
                files.append(item)
            }
        }
        self.tableView.tableFooterView = UIView(frame: CGRectZero)

    }

    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("filesCell", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel!.text = files[indexPath.row]
        return cell
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destVC = segue.destinationViewController as? FileViewerViewController {
            if let cell = sender as? UITableViewCell {
                if let filename = cell.textLabel?.text {
                    destVC.url = NSURL.fileURLWithPath("\(parentDir)/\(filename)")
                }
            }
        }
    }
    

}
