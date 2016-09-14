//
//  FoodPickerViewController.swift
//  HealthKit~Swift
//
//  Created by EdenLi on 2014/9/17.
//  Copyright (c) 2014年 Darktt Personal Company. All rights reserved.
//

import UIKit
 
@objc
protocol FoodPickerViewControllerDelegate: class
{
    @objc 
    optional func foodPicker(_ foodPicker: FoodPickerViewController, didSelectedFoodItem foodItem: FoodItem) -> Void
}

class FoodPickerViewController: UITableViewController
{
    var delegate: FoodPickerViewControllerDelegate?
    
    private var foodItems: [FoodItem] {
        
        var foodItems = Array<FoodItem>() 
        foodItems.append(FoodItem(name: "Wheat Bagel", joules: 240000.0))
        foodItems.append(FoodItem(name: "Bran with Raisins", joules: 190000.0))
        foodItems.append(FoodItem(name: "Regular Instant Coffee", joules: 1000.0))
        foodItems.append(FoodItem(name: "Banana", joules: 439320.0))
        foodItems.append(FoodItem(name: "Cranberry Bagel", joules: 416000.0))
        foodItems.append(FoodItem(name: "Oatmeal", joules: 150000.0))
        foodItems.append(FoodItem(name: "Fruits Salad", joules: 60000.0))
        foodItems.append(FoodItem(name: "Fried Sea Bass", joules: 200000.0))
        foodItems.append(FoodItem(name: "Chips", joules: 190000.0))
        foodItems.append(FoodItem(name: "Chicken Taco", joules: 170000.0))
        
        return foodItems
    }
    
    private var energyFormatter: EnergyFormatter {
        
        let energyFormatter = EnergyFormatter()
        energyFormatter.unitStyle = Formatter.UnitStyle.long
        energyFormatter.isForFoodEnergyUse = true
        energyFormatter.numberFormatter.maximumFractionDigits = 2
        
        return energyFormatter
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
    
    override func numberOfSections(in tableView: UITableView) -> Int 
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.foodItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let CellIdentifier: String = "CellIdentifier"
        
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: CellIdentifier)
        }
        
        let foodItem: FoodItem = self.foodItems[indexPath.row]
        cell!.textLabel!.text = foodItem.name
        
        let energyFormatter: EnergyFormatter = self.energyFormatter
        cell!.detailTextLabel!.text = energyFormatter.string(fromJoules: foodItem.joules)
        
        return cell!
    }
    
    //MARK: - UITableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let foodItem: FoodItem = self.foodItems[indexPath.row]
        
        if let delegate = self.delegate, let foodPicker = delegate.foodPicker {
            
            foodPicker(self, foodItem)
        }
    }
}
