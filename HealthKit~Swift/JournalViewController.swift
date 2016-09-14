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
    
    private var foodItems: Array<FoodItem>?
    
    private var energyFormatter: EnergyFormatter {
        
        let energyFormatter = EnergyFormatter()
        energyFormatter.unitStyle = Formatter.UnitStyle.long
        energyFormatter.isForFoodEnergyUse = true
        energyFormatter.numberFormatter.maximumFractionDigits = 2
        
        return energyFormatter
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        NotificationCenter.default.addObserver(self, selector: #selector(JournalViewController.updateJournal), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Food Journal"
        
        self.foodItems = []
        
        let addBarButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(JournalViewController.pickFood(sender:)));
        
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
        let pickFoodViewController = FoodPickerViewController(style: UITableViewStyle.plain)
        pickFoodViewController.delegate = self
        
        self.navigationController?.pushViewController(pickFoodViewController, animated: true)
    }
    
    //MARK: - Reading HealthKit Data
    
    // Use for someone selector, can not be private.
    func updateJournal()
    {
        let calendar = Calendar.current
        let nowDate = Date()
        
        let componentsUnit: Set<Calendar.Component>= [Calendar.Component.year, .month, .day]
        let components: DateComponents = calendar.dateComponents(componentsUnit, from: nowDate)
        
        let stareDate: Date = calendar.date(from: components)!
        let endDate: Date = calendar.date(byAdding: Calendar.Component.day, value: 1, to: stareDate)!
        
        let foodType = HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)!
        
        let predicate: NSPredicate = HKQuery.predicateForSamples(withStart: stareDate, end: endDate, options: [])
        let limit: Int = Int(HKObjectQueryNoLimit)
        
        let query: HKSampleQuery = HKSampleQuery(sampleType: foodType, predicate: predicate, limit: limit, sortDescriptors: nil) {
            
            [unowned self] (query, results, error) -> Void in
            
            guard let results = results else {
                print("An error occured fetching the user's tracked food. In your app, try to handle this gracefully. The error was: \(error).")
                abort()
            }
            
            DispatchQueue.main.async {
                
                self.foodItems!.removeAll(keepingCapacity: false)
                
                for foodCorrelation in results {
                    // Create an FoodItem instance that contains the information we care about that's
                    // stored in the food correlation.
                    let foodItem: FoodItem = self.foodItem(fromFoodCorrelation: foodCorrelation as! HKCorrelation)
                    
                    self.foodItems!.append(foodItem)
                }
                
                self.tableView.reloadData()
            }
        }
        
        if let healthStore = self.healthStore {
            
            healthStore.execute(query)
        }
    }
    
    private func foodItem(fromFoodCorrelation foodCorrelation: HKCorrelation) -> FoodItem
    {
        // Fetch the name fo the food.
        let foodName: String = foodCorrelation.metadata![HKMetadataKeyFoodType] as! String
        
        // Fetch the total energy from the food.
        let energyConsumedType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!
        let energyConsumedSamples: Set<HKSample> = foodCorrelation.objects(for: energyConsumedType)
        
        // Note that we only have one energy consumed sample correlation (for Fit specifically).
        let energyConsumedSample: HKQuantitySample = energyConsumedSamples.first as! HKQuantitySample
        let energyQuantityConsumed: HKQuantity = energyConsumedSample.quantity
        
        let joules: Double = energyQuantityConsumed.doubleValue(for: HKUnit.joule())
        
        return FoodItem.foodItem(name: foodName, joules: joules)
    }
    
    //MARK: - Writing HealthKit Data
    
    private func addFoodItem(_ foodItem: FoodItem)
    {
        // Create a new food correlation for the given food item.
        let foodCorrelationForFoodItem: HKCorrelation = self.foodCorrelationForFoodItem(foodItem)
        
        let completion: (Bool, Error?) -> Void = {
            [unowned self] (success, error) -> Void in
            
            DispatchQueue.main.async {
                
                if !success {
                    print("An error occured saving the food %@. In your app, try to handle this gracefully. The error was: \(error)")
                    
                    return
                }
                
                self.foodItems!.insert(foodItem, at: 0)
                
                let indexPathForInsertedFoodItem = IndexPath(row: 0, section: 0)
                
                self.tableView.insertRows(at: [indexPathForInsertedFoodItem], with: UITableViewRowAnimation.none)
            }
        }
        
        if let healthStore = self.healthStore {
            
            healthStore.save(foodCorrelationForFoodItem, withCompletion: completion)
        }
    }
    
    private func foodCorrelationForFoodItem(_ foodItem: FoodItem) -> HKCorrelation
    {
        let nowDate = Date()
        
        let energyQuantityConsumed = HKQuantity(unit: HKUnit.joule(), doubleValue: foodItem.joules)
        let energyConsumedType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!
        let energyConsumedSample = HKQuantitySample(type: energyConsumedType, quantity: energyQuantityConsumed, start: nowDate, end: nowDate)
        let energyConsumedSamples: Set<HKSample> = [energyConsumedSample]
        
        let foodType = HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)!
        let foodCorrelationMetadata: Dictionary<String, String> = [HKMetadataKeyFoodType: foodItem.name]
        
        let foodCorrelation = HKCorrelation(type: foodType, start: nowDate, end: nowDate, objects: energyConsumedSamples, metadata: foodCorrelationMetadata)
        
        return foodCorrelation
    }
    
    //MARK: - UITableView DataSource Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int 
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard let foodItems = self.foodItems else {
            
            return 0
        }
        
        return foodItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let CellIdentifier: String = "CellIdentifier"
        
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: CellIdentifier)
        }
        
        return cell!
    }
    
    //MARK: - UITableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) 
    {
        guard let foodItems = self.foodItems else {
            
            return
        }
        
        let foodItem = foodItems[indexPath.row]
        
        cell.textLabel!.text = foodItem.name
        
        let energyFormatter: EnergyFormatter = self.energyFormatter
        cell.detailTextLabel!.text = energyFormatter.string(fromJoules: foodItem.joules)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK - FoodPickerViewController Delegate Method
    
    func foodPicker(_ foodPicker: FoodPickerViewController, didSelectedFoodItem foodItem: FoodItem)
    {
        let _ = self.navigationController?.popViewController(animated: true)
        
        self.addFoodItem(foodItem)
    }
}
