//
//  JournalViewController.swift
//  HealthKit~Swift
//
//  Created by EdenLi on 2014/9/17.
//  Copyright (c) 2014年 Darktt Personal Company. All rights reserved.
//

import UIKit
import HealthKit

class JournalViewController: UITableViewController
{

    var healthStore: HKHealthStore?
    
    private var foodItems: [FoodItem]?
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Food Journal"
        
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Reading HealthKit Data
    
    private func updateJournal()
    {
        let calendar: NSCalendar = NSCalendar.currentCalendar()
        let nowDate: NSDate = NSDate()
        
        let componentsUnit = NSCalendarUnit.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay
        let components: NSDateComponents = calendar.components(componentsUnit, fromDate: nowDate)
        
        let stareDate: NSDate? = calendar.dateFromComponents(components)
        let endDate: NSDate? = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: 1, toDate: stareDate!, options: nil)
        
        let foodType: HKCorrelationType = HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierFood)
        
        let predicate: NSPredicate = HKQuery.predicateForSamplesWithStartDate(stareDate, endDate: endDate, options: HKQueryOptions.None)
        let limit: Int = Int(HKObjectQueryNoLimit)
        
        let query: HKSampleQuery = HKSampleQuery(sampleType: foodType, predicate: predicate, limit: limit, sortDescriptors: nil) {
            (query, results, error) -> Void in
            
            if results == nil {
                println("An error occured fetching the user's tracked food. In your app, try to handle this gracefully. The error was: (error).")
                abort()
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                () -> Void in
                
                self.foodItems!.removeAll(keepCapacity: false)
                
                for foodCorrelation in results {
                    // Create an FoodItem instance that contains the information we care about that's
                    // stored in the food correlation.
                    let foodItem: FoodItem = self.foodItemFromFoodCorrelation(foodCorrelation as HKCorrelation)
                    
                    self.foodItems?.append(foodItem)
                }
                
                self.tableView.reloadData()
            })
        }
        
        self.healthStore?.executeQuery(query)
    }
    
    private func foodItemFromFoodCorrelation(foodCorrelation: HKCorrelation) -> FoodItem
    {
        // Fetch the name fo the food.
        let foodName = foodCorrelation.metadata[HKMetadataKeyFoodType] as NSString?
        
        // Fetch the total energy from the food.
        let energyConsumedType: HKQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)
        let energyConsumedSamples: NSSet = foodCorrelation.objectsForType(energyConsumedType)
        
        // Note that we only have one energy consumed sample correlation (for Fit specifically).
        let energyConsumedSample: HKQuantitySample = energyConsumedSamples.anyObject() as HKQuantitySample!
        
        let energyQuantityConsumed: HKQuantity = energyConsumedSample.quantity
        
        let joules: Double = energyQuantityConsumed.doubleValueForUnit(HKUnit.jouleUnit())
        
        return FoodItem.foodItem(foodName as String, joules: joules)
    }
    
    //MARK: - UITableView DataSource Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let CellIdentifier: String = "CellIdentifier"
        
        var cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: CellIdentifier)
        }
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if let foodItems: [FoodItem] = self.foodItems {
            let foodItem = foodItems[indexPath.row]
            
            cell.textLabel?.text = foodItem.name
            
            let energyFormatter: NSEnergyFormatter = self.energyFormatter()
            cell.detailTextLabel?.text = energyFormatter.stringFromJoules(foodItem.joules)
        }
    }
}
