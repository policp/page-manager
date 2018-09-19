//
//  MainViewController.swift
//  page-manager_Example
//
//  Created by 陈鹏 on 2018/9/19.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @objc var name: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = name
        view.backgroundColor = UIColor.red
        // Do any additional setup after loading the view.
    }
    
    deinit {
        print("aaaaaaaaaaaa")
    }


}
