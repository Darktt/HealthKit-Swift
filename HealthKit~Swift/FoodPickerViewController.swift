//
//  FoodPickerViewController.swift
//  HealthKit~Swift
//
//  Created by EdenLi on 2014/9/17.
//  Copyright (c) 2014年 Darktt Personal Company. All rights reserved.
//

import UIKit

class FoodPickerViewController: UIViewController {

    var selectedFootItem: FoodItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Pick Food"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
