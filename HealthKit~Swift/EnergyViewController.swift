//
//  EnergyViewController.swift
//  HealthKit~Swift
//
//  Created by EdenLi on 2014/9/17.
//  Copyright (c) 2014年 Darktt Personal Company. All rights reserved.
//

import UIKit
import HealthKit

class EnergyViewController: UITableViewController
{

    var healthStore: HKHealthStore?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.navigationController?.title
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
