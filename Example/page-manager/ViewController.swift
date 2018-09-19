//
//  ViewController.swift
//  page-manager
//
//  Created by policp on 09/19/2018.
//  Copyright (c) 2018 policp. All rights reserved.
//

import UIKit
import page_manager

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    let dataSource = ["system","present","fade","scale","circleScale"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "page-manager"
        
        tableView.rowHeight = 50
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reusecell")
        // Do any additional setup after loading the view, typically from a nib. reusecell
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reusecell")
        cell?.textLabel?.text = dataSource[indexPath.row]
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        weak var weakSelf = self
        PageManager.share.push("MainViewController", pushAnimator: self.getPushAnimator(indexPath.row)) { (target) in
            target.setValue(weakSelf?.dataSource[indexPath.row], forKey: "name")
        }
    }
    
    private func getPushAnimator(_ index: Int) -> PushAnimator {
        switch index {
        case 0:
            return .system
        case 1:
            return .present
        case 2:
            return .fade
        case 3:
            return .scale
        case 4:
            return .circleScale
        default:
            return .system
        }
    }
}

