//
//  JournalViewController.swift
//  HealthKit~Swift
//
//  Created by EdenLi on 2014/9/17.
//  Copyright (c) 2014年 Darktt Personal Company. All rights reserved.
//

import UIKit
import HealthKit

class JournalViewController: UITableViewController, FoodPickerViewControllerDelegate
{

    var healthStore: HKHealthStore?
    
    private var foodItems: [FoodItem]?
    
    private var energyFormatter: NSEnergyFormatter {
        get {
            let energyFormatter: NSEnergyFormatter = NSEnergyFormatter()
            energyFormatter.unitStyle = NSFormattingUnitStyle.Long
            energyFormatter.forFoodEnergyUse = true
            energyFormatter.numberFormatter.maximumFractionDigits = 2
            
            return energyFormatter
        }
    }
    
    override func viewDidAppear(animated: Bool)
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(JournalViewController.updateJournal), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool)
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Food Journal"
        
        self.foodItems = []
        
        let addBarButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: #selector(JournalViewController.pickFood(_:)));
        
        self.navigationItem.rightBarButtonItem = addBarButton
        
        self.updateJournal()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Button Action
    
    @IBAction func pickFood(sender: AnyObject)
    {
        let pickFoodViewController = FoodPickerViewController(style: UITableViewStyle.Plain)
        pickFoodViewController.delegate = self
        
        self.navigationController?.pushViewController(pickFoodViewController, animated: true)
    }
    
    //MARK: - Reading HealthKit Data
    
    // Use for someone selector, can not be private.
    func updateJournal()
    {
        let calendar: NSCalendar = NSCalendar.currentCalendar()
        let nowDate: NSDate = NSDate()
        
        let componentsUnit: NSCalendarUnit = [NSCalendarUnit.Year, .Month, .Day]
        let components: NSDateComponents = calendar.components(componentsUnit, fromDate: nowDate)
        
        let stareDate: NSDate? = calendar.dateFromComponents(components)
        let endDate: NSDate? = calendar.dateByAddingUnit(NSCalendarUnit.Day, value: 1, toDate: stareDate!, options: [])
        
        let foodType: HKCorrelationType = HKObjectType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierFood)!
        
        let predicate: NSPredicate = HKQuery.predicateForSamplesWithStartDate(stareDate, endDate: endDate, options: HKQueryOptions.None)
        let limit: Int = Int(HKObjectQueryNoLimit)
        
        let query: HKSampleQuery = HKSampleQuery(sampleType: foodType, predicate: predicate, limit: limit, sortDescriptors: nil) {
            (query, results, error) -> Void in
            
            if results == nil {
                print("An error occured fetching the user's tracked food. In your app, try to handle this gracefully. The error was: \(error).")
                abort()
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                () -> Void in
                
                self.foodItems!.removeAll(keepCapacity: false)
                
                for foodCorrelation in results! {
                    // Create an FoodItem instance that contains the information we care about that's
                    // stored in the food correlation.
                    let foodItem: FoodItem = self.foodItemFromFoodCorrelation(foodCorrelation as! HKCorrelation)
                    
                    self.foodItems!.append(foodItem)
                }
                
                self.tableView.reloadData()
            })
        }
        
        self.healthStore!.executeQuery(query)
    }
    
    private func foodItemFromFoodCorrelation(foodCorrelation: HKCorrelation) -> FoodItem
    {
        // Fetch the name fo the food.
        let foodName = foodCorrelation.metadata![HKMetadataKeyFoodType] as? NSString
        
        // Fetch the total energy from the food.
        let energyConsumedType: HKQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!
        let energyConsumedSamples: NSSet = foodCorrelation.objectsForType(energyConsumedType)
        
        // Note that we only have one energy consumed sample correlation (for Fit specifically).
        let energyConsumedSample: HKQuantitySample = energyConsumedSamples.anyObject() as! HKQuantitySample
        
        let energyQuantityConsumed: HKQuantity = energyConsumedSample.quantity
        
        let joules: Double = energyQuantityConsumed.doubleValueForUnit(HKUnit.jouleUnit())
        
        return FoodItem.foodItem(foodName as! String, joules: joules)
    }
    
    //MARK: - Writing HealthKit Data
    
    private func addFoodItem(foodItem: FoodItem)
    {
        // Create a new food correlation for the given food item.
        let foodCorrelationForFoodItem: HKCorrelation = self.foodCorrelationForFoodItem(foodItem)
        
        let completion: (Bool, NSError?) -> Void = {
            (success, error) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), {
                () -> Void in
                
                if !success {
                    print("An error occured saving the food %@. In your app, try to handle this gracefully. The error was: \(error)")
                    
                    return
                }
                
                self.foodItems!.insert(foodItem, atIndex: 0)
                
                let indexPathForInsertedFoodItem: NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                
                self.tableView.insertRowsAtIndexPaths([indexPathForInsertedFoodItem], withRowAnimation: UITableViewRowAnimation.None)
            })
        }
        
        self.healthStore!.saveObject(foodCorrelationForFoodItem, withCompletion: completion)
    }
    
    private func foodCorrelationForFoodItem(foodItem: FoodItem) -> HKCorrelation
    {
        let nowDate: NSDate = NSDate()
        
        let energyQuantityConsumed: HKQuantity = HKQuantity(unit: HKUnit.jouleUnit(), doubleValue: foodItem.joules)
        let energyConsumedType: HKQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)!
        let energyConsumedSample: HKQuantitySample = HKQuantitySample(type: energyConsumedType, quantity: energyQuantityConsumed, startDate: nowDate, endDate: nowDate)
        let energyConsumedSamples: Set<HKSample> = [energyConsumedSample]
        
        let foodType: HKCorrelationType = HKCorrelationType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierFood)!
        let foodCorrelationMetadata: [String: AnyObject] = [HKMetadataKeyFoodType: foodItem.name]
        
        let foodCorrelation: HKCorrelation = HKCorrelation(type: foodType, startDate: nowDate, endDate: nowDate, objects: energyConsumedSamples, metadata: foodCorrelationMetadata)
        
        return foodCorrelation
    }
    
    //MARK: - UITableView DataSource Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if self.foodItems == nil {
            return 0
        }
        
        return self.foodItems!.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let CellIdentifier: String = "CellIdentifier"
        
        var cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier(CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: CellIdentifier)
        }
        
        return cell!
    }
    
    //MARK: - UITableView Delegate Methods
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if let foodItems: [FoodItem] = self.foodItems {
            let foodItem = foodItems[indexPath.row]
            
            cell.textLabel!.text = foodItem.name
            
            let energyFormatter: NSEnergyFormatter = self.energyFormatter
            cell.detailTextLabel!.text = energyFormatter.stringFromJoules(foodItem.joules)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    //MARK - FoodPickerViewController Delegate Method
    
    func foodPicker(foodPicker: FoodPickerViewController, didSelectedFoodItem foodItem: FoodItem)
    {
        self.navigationController?.popViewControllerAnimated(true)
        
        self.addFoodItem(foodItem)
    }
}
