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
    
    // Private class and variables
    private class Energy {
        var activeEnergyBurned: Double = 0.0
        var restingEnergyBurned: Double = 0.0
        var energyConsumed: Double = 0.0
        
        var netEnergy: Double {
            get {
                let _netEnergy = self.energyConsumed - self.activeEnergyBurned - self.restingEnergyBurned
                
                return _netEnergy
            }
        }
    }
    
    private let energyStore: Energy = Energy()
    private var menu: [String] {
        get {
            let _menu: [String] = ["Resting Burn", "Active Burn", "Consumed", "Net"]
            
            return _menu
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.refreshStatistics()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshStatistics", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.navigationController?.title
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: "refreshStatistics", forControlEvents: UIControlEvents.ValueChanged)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Reading HealthKit Data
    
    func refreshStatistics()
    {
        self.refreshControl!.beginRefreshing()
        
        let energyConsumedType: HKQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)
        let activeEnergyBurnType: HKQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)
        
        // First, fetch the sum of energy consumed samples from HealthKit. Populate this by creating your
        // own food logging app or using the food journal view controller.
        let completeFirstTime: ((Double, NSError?) -> Void) = {
            (totalJoulesConsumed, error) -> Void in
            
            // Next, fetch the sum of active energy burned from HealthKit. Populate this by creating your
            // own calorie tracking app or the Health app.
            let completeSecondTime: ((Double, NSError?) -> Void) = {
                (activeEnergyBurned, error) -> Void in
                
                // Last, calculate the user's basal energy burn so far today.
                var completion: ((HKQuantity?, NSError?) -> Void) = {
                    (basalEnergyBurn, error) -> Void in
                    
                    if basalEnergyBurn == nil {
                        println("An error occurred trying to compute the basal energy burn. In your app, handle this gracefully. Error: \(error)")
                    }
                    
                    // Update the UI with all of the fetched values.
                    dispatch_async(dispatch_get_main_queue(), {
                        () -> Void in
                        
                        self.energyStore.activeEnergyBurned = activeEnergyBurned
                        
                        self.energyStore.restingEnergyBurned = basalEnergyBurn!.doubleValueForUnit(HKUnit.jouleUnit())
                        
                        self.energyStore.energyConsumed = totalJoulesConsumed
                        
                        self.refreshControl!.endRefreshing()
                        self.tableView!.reloadData()
                    })
                    
                }
                
                self.fetchTotalBasalBurn(completion)
                
            }
            
            self.fetchSumOfSamplesTodayForType(activeEnergyBurnType, unit: HKUnit.jouleUnit(), completion: completeSecondTime)
        }
        
        self.fetchSumOfSamplesTodayForType(energyConsumedType, unit: HKUnit.jouleUnit(), completion: completeFirstTime)
    }
    
    private func fetchSumOfSamplesTodayForType(quantityType: HKQuantityType, unit: HKUnit, completion completionHandler: ((Double, NSError?) -> Void)?)
    {
        let predicate = self.predicateForSamplesToday()
        
        let query: HKStatisticsQuery = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: HKStatisticsOptions.CumulativeSum) {
            (_query, result, error) -> Void in
            
            var sum: HKQuantity? = result.sumQuantity()
            
            if completionHandler != nil {
                let value: Double = (sum != nil) ? sum!.doubleValueForUnit(unit) : 0
                
                completionHandler!(value, error)
            }
        }
        
        self.healthStore!.executeQuery(query)
    }
    
    // Calculates the user's total basal (resting) energy burn based off of their height, weight, age,
    // and biological sex. If there is not enough information, return an error.
    private func fetchTotalBasalBurn(completion: ((HKQuantity?, NSError?) -> Void))
    {
        let todayPredicate: NSPredicate = self.predicateForSamplesToday()
        
        let weightType: HKQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
        let heightType: HKQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)
        
        let queryWeigth: HKCompletionHandle = {
            (weight, error) -> Void in
            
            if weight == nil {
                completion(nil, error)
                
                return;
            }
            
            let queryHeigth: HKCompletionHandle = {
                (height, error) -> Void in
                
                if height == nil {
                    completion(nil, error)
                    
                    return;
                }
                
                var queryBirthDayError: NSError? = nil
                var dateOfBirth: NSDate? = self.healthStore!.dateOfBirthWithError(&queryBirthDayError)
                
                if dateOfBirth == nil {
                    completion(nil, error)
                    
                    return;
                }
                
                var queryBiologicalSexError: NSError? = nil
                var biologicalSexObjet: HKBiologicalSexObject? = self.healthStore!.biologicalSexWithError(&queryBiologicalSexError)
                
                if biologicalSexObjet == nil {
                    completion(nil, error)
                    
                    return;
                }
                
                // Once we have pulled all of the information without errors, calculate the user's total basal energy burn
                var basalEnergyButn: HKQuantity? = self.calculateBasalBurnTodayFromWeight(weight, height: height, dateOfBirth: dateOfBirth!, biologicalSex: biologicalSexObjet!)
                
                completion(basalEnergyButn, nil)
            }
            
            self.healthStore!.mostRecentQuantitySampleOfType(heightType, predicate: todayPredicate, completion: queryHeigth)
        }
        
        self.healthStore!.mostRecentQuantitySampleOfType(weightType, predicate: nil, completion: queryWeigth)
    }
    
    private func calculateBasalBurnTodayFromWeight(weight: HKQuantity?, height: HKQuantity?, dateOfBirth: NSDate?, biologicalSex: HKBiologicalSexObject?) -> HKQuantity?
    {
        // Only calculate Basal Metabolic Rate (BMR) if we have enough information about the user
        if (weight == nil) || (height == nil) || (dateOfBirth == nil) || (biologicalSex == nil) {
            return nil
        }
        
        // Note the difference between calling +unitFromString: vs creating a unit from a string with
        // a given prefix. Both of these are equally valid, however one may be more convenient for a given
        // use case.
        let heightInCentimeters: Double = height!.doubleValueForUnit(HKUnit(fromString:"cm"))
        let weightInKilograms: Double = weight!.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(HKMetricPrefix.Kilo))
        
        let nowDate: NSDate = NSDate()
        let ageComponents: NSDateComponents = NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitYear, fromDate: dateOfBirth!, toDate: nowDate, options: NSCalendarOptions.WrapComponents)
        let ageInYears: Int = ageComponents.year
        
        // BMR is calculated in kilocalories per day.
        let BMR: Double = self.calculateBMRFromWeight(weightInKilograms, height: heightInCentimeters, age: ageInYears, biologicalSex: biologicalSex!.biologicalSex)
        
        // Figure out how much of today has completed so we know how many kilocalories the user has burned.
        let (startOfToday: NSDate, endOfToday: NSDate) = self.datesFromToday()
        
        let secondsInDay: NSTimeInterval = endOfToday.timeIntervalSinceDate(startOfToday)
        let percentOfDayComplete: Double = nowDate.timeIntervalSinceDate(startOfToday) / secondsInDay
        
        let kilocaloriesBurned: Double = BMR * percentOfDayComplete
        
        let basalBurn: HKQuantity = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: kilocaloriesBurned)
        
        return basalBurn
    }
    
    //MARK: - Convenience
    
    private func predicateForSamplesToday() -> NSPredicate
    {
        let (starDate: NSDate, endDate: NSDate) = self.datesFromToday()
        
        let predicate: NSPredicate = HKQuery.predicateForSamplesWithStartDate(starDate, endDate: endDate, options: HKQueryOptions.StrictStartDate)
        
        return predicate
    }
    
    /// Returns BMR value in kilocalories per day. Note that there are different ways of calculating the
    /// BMR. In this example we chose an arbitrary function to calculate BMR based on weight, height, age,
    /// and biological sex.
    private func calculateBMRFromWeight(weightInKilograms: Double, height heightInCentimeters: Double, age ageInYears: Int, biologicalSex: HKBiologicalSex) -> Double
    {
        var BMR: Double = 0
        
        if biologicalSex == .Male {
            BMR = 66.0 + (13.8 * weightInKilograms) + (5.0 * heightInCentimeters) - (6.8 * Double(ageInYears))
            
            return BMR
        }
        
        BMR = 655 + (9.6 * weightInKilograms) + (1.8 * heightInCentimeters) - (4.7 * Double(ageInYears))
        
        return BMR
    }
    
    private func datesFromToday() -> (NSDate, NSDate)
    {
        let calendar: NSCalendar = NSCalendar.currentCalendar()
        
        let nowDate: NSDate = NSDate()
        
        let starDate: NSDate = calendar.startOfDayForDate(nowDate)
        let endDate: NSDate = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: 1, toDate: starDate, options: NSCalendarOptions.allZeros)!
        
        return (starDate, endDate)
    }
    
    //MARK: Convert Energy Formatter
    
    private func stringFromJoules(joules: Double) -> String
    {
        let stringOfJourle: String = self.energyFormatter.stringFromJoules(joules)
        
        return stringOfJourle
    }
    
    //MARK: - UITableView DataSource Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.menu.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let CellIdentifier: String = "CellIdentifier"
        
        var cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: CellIdentifier)
        }
        
        let title: String = self.menu[indexPath.row]
        var detailText: String? = nil
        
        switch indexPath.row {
            case 0:
                detailText = self.stringFromJoules(self.energyStore.restingEnergyBurned)
            
            case 1:
                detailText = self.stringFromJoules(self.energyStore.activeEnergyBurned)
            
            case 2:
                detailText = self.stringFromJoules(self.energyStore.energyConsumed)
            
            case 3:
                detailText = self.stringFromJoules(self.energyStore.netEnergy)
            
            default:
                break
        }
        
        cell!.textLabel.text = title
        cell!.detailTextLabel!.text = detailText!
        
        return cell!
    }
}
