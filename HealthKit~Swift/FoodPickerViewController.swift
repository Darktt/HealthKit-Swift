//
//  FoodPickerViewController.swift
//  HealthKit~Swift
//
//  Created by EdenLi on 2014/9/17.
//  Copyright (c) 2014年 Darktt Personal Company. All rights reserved.
//

import UIKit

@objc protocol FoodPickerViewControllerDelegate: NSObjectProtocol
{
    optional func foodPicker(foodPicker: FoodPickerViewController, didSelectedFoodItem foodItem: FoodItem) -> Void
}

class FoodPickerViewController: UITableViewController
{
    var delegate: FoodPickerViewControllerDelegate?
    
    private var foodItems: [FoodItem] {
        get {
            var foodItems: [FoodItem] = [FoodItem.foodItem("Wheat Bagel", joules: 240000.0)]
            foodItems.append(FoodItem.foodItem("Bran with Raisins", joules: 190000.0))
            foodItems.append(FoodItem.foodItem("Regular Instant Coffee", joules: 1000.0))
            foodItems.append(FoodItem.foodItem("Banana", joules: 439320.0))
            foodItems.append(FoodItem.foodItem("Cranberry Bagel", joules: 416000.0))
            foodItems.append(FoodItem.foodItem("Oatmeal", joules: 150000.0))
            foodItems.append(FoodItem.foodItem("Fruits Salad", joules: 60000.0))
            foodItems.append(FoodItem.foodItem("Fried Sea Bass", joules: 200000.0))
            foodItems.append(FoodItem.foodItem("Chips", joules: 190000.0))
            foodItems.append(FoodItem.foodItem("Chicken Taco", joules: 170000.0))
            
            return foodItems
        }
    }
    
    private var energyFormatter: NSEnergyFormatter {
        get {
            let energyFormatter: NSEnergyFormatter = NSEnergyFormatter()
            energyFormatter.unitStyle = NSFormattingUnitStyle.Long
            energyFormatter.forFoodEnergyUse = true
            energyFormatter.numberFormatter.maximumFractionDigits = 2
            
            return energyFormatter
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Pick Food"
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UITableView DataSource Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.foodItems.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let CellIdentifier: String = "CellIdentifier"
        
        var cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: CellIdentifier)
        }
        
        let foodItem: FoodItem = self.foodItems[indexPath.row]
        cell!.textLabel.text = foodItem.name
        
        let energyFormatter: NSEnergyFormatter = self.energyFormatter
        cell!.detailTextLabel!.text = energyFormatter.stringFromJoules(foodItem.joules)
        
        return cell!
    }
    
    //MARK: - UITableView Delegate Methods
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let foodItem: FoodItem = self.foodItems[indexPath.row]
        
        if self.delegate? != nil {
            self.delegate?.foodPicker!(self, didSelectedFoodItem: foodItem)
        }
    }
}
