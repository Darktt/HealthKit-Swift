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
    
    private var energyFormatter: EnergyFormatter {
        get {
            let energyFormatter: EnergyFormatter = EnergyFormatter()
            energyFormatter.unitStyle = Formatter.UnitStyle.long
            energyFormatter.isForFoodEnergyUse = true
            energyFormatter.numberFormatter.maximumFractionDigits = 2
            
            return energyFormatter
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.refreshStatistics()
        
        NotificationCenter.default.addObserver(self, selector: "refreshStatistics", name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.navigationController?.title
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: "refreshStatistics", for: UIControlEvents.valueChanged)
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
        
        let energyConsumedType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!
        let activeEnergyBurnType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
        
        // First, fetch the sum of energy consumed samples from HealthKit. Populate this by creating your
        // own food logging app or using the food journal view controller.
        let completeFirstTime: ((Double, NSError?) -> Void) = {
            (totalJoulesConsumed, error) -> Void in
            
            // Next, fetch the sum of active energy burned from HealthKit. Populate this by creating your
            // own calorie tracking app or the Health app.
            let completeSecondTime: ((Double, NSError?) -> Void) = {
                (activeEnergyBurned, error) -> Void in
                
                // Last, calculate the user's basal energy burn so far today.
                let completion: ((HKQuantity?, NSError?) -> Void) = {
                    (basalEnergyBurn, error) -> Void in
                    
                    if basalEnergyBurn == nil {
                        print("An error occurred trying to compute the basal energy burn. In your app, handle this gracefully. Error: \(error)")
                    }
                    
                    // Update the UI with all of the fetched values.
                    DispatchQueue.main.async(execute: {
                        () -> Void in
                        
                        self.energyStore.activeEnergyBurned = activeEnergyBurned
                        
                        self.energyStore.restingEnergyBurned = basalEnergyBurn?.doubleValue(for: HKUnit.joule()) ?? 0.0
                        
                        self.energyStore.energyConsumed = totalJoulesConsumed
                        
                        self.refreshControl!.endRefreshing()
                        self.tableView!.reloadData()
                    })
                    
                }
                
                self.fetchTotalBasalBurn(completion)
                
            }
            
            self.fetchSumOfSamplesTodayForType(activeEnergyBurnType, unit: HKUnit.joule(), completion: completeSecondTime)
        }
        
        self.fetchSumOfSamplesTodayForType(energyConsumedType, unit: HKUnit.joule(), completion: completeFirstTime)
    }
    
    private func fetchSumOfSamplesTodayForType(_ quantityType: HKQuantityType, unit: HKUnit, completion completionHandler: ((Double, NSError?) -> Void)?)
    {
        let predicate = self.predicateForSamplesToday()
        
        let query: HKStatisticsQuery = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: HKStatisticsOptions.cumulativeSum) {
            (_query, result, error) -> Void in
            
            let sum: HKQuantity? = result!.sumQuantity()
            
            if completionHandler != nil {
                let value: Double = (sum != nil) ? sum!.doubleValue(for: unit) : 0
                
                completionHandler!(value, error)
            }
        }
        
        self.healthStore!.execute(query)
    }
    
    // Calculates the user's total basal (resting) energy burn based off of their height, weight, age,
    // and biological sex. If there is not enough information, return an error.
    private func fetchTotalBasalBurn(_ completion: ((HKQuantity?, NSError?) -> Void))
    {
        let todayPredicate: Predicate = self.predicateForSamplesToday()
        
        let weightType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        let heightType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!
        
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
                
                var dateOfBirth: Date?
                do {
                    dateOfBirth = try self.healthStore!.dateOfBirth()
                } catch let error as NSError {
                    completion(nil, error)
                    
                    return;
                } catch {
                    fatalError()
                }
                
                var biologicalSexObjet: HKBiologicalSexObject?
                do {
                    biologicalSexObjet = try self.healthStore!.biologicalSex()
                } catch let error as NSError {
                    completion(nil, error)
                    
                    return;
                } catch {
                    fatalError()
                }
                
                // Once we have pulled all of the information without errors, calculate the user's total basal energy burn
                let basalEnergyButn: HKQuantity? = self.calculateBasalBurnTodayFromWeight(weight, height: height, dateOfBirth: dateOfBirth!, biologicalSex: biologicalSexObjet!)
                
                completion(basalEnergyButn, nil)
            }
            
            self.healthStore!.mostRecentQuantitySampleOfType(heightType, predicate: todayPredicate, completion: queryHeigth)
        }
        
        self.healthStore!.mostRecentQuantitySampleOfType(weightType, predicate: nil, completion: queryWeigth)
    }
    
    private func calculateBasalBurnTodayFromWeight(_ weight: HKQuantity?, height: HKQuantity?, dateOfBirth: Date?, biologicalSex: HKBiologicalSexObject?) -> HKQuantity?
    {
        // Only calculate Basal Metabolic Rate (BMR) if we have enough information about the user
        if (weight == nil) || (height == nil) || (dateOfBirth == nil) || (biologicalSex == nil) {
            return nil
        }
        
        // Note the difference between calling +unitFromString: vs creating a unit from a string with
        // a given prefix. Both of these are equally valid, however one may be more convenient for a given
        // use case.
        let heightInCentimeters: Double = height!.doubleValue(for: HKUnit(from:"cm"))
        let weightInKilograms: Double = weight!.doubleValue(for: HKUnit.gramUnit(with: HKMetricPrefix.kilo))
        
        let nowDate: Date = Date()
        let ageComponents: DateComponents = Calendar.current.components(Calendar.Unit.year, from: dateOfBirth!, to: nowDate, options: Calendar.Options.wrapComponents)
        let ageInYears: Int = ageComponents.year!
        
        // BMR is calculated in kilocalories per day.
        let BMR: Double = self.calculateBMRFromWeight(weightInKilograms, height: heightInCentimeters, age: ageInYears, biologicalSex: biologicalSex!.biologicalSex)
        
        // Figure out how much of today has completed so we know how many kilocalories the user has burned.
        let (startOfToday, endOfToday): (Date, Date) = self.datesFromToday()
        
        let secondsInDay: TimeInterval = endOfToday.timeIntervalSince(startOfToday)
        let percentOfDayComplete: Double = nowDate.timeIntervalSince(startOfToday) / secondsInDay
        
        let kilocaloriesBurned: Double = BMR * percentOfDayComplete
        
        let basalBurn: HKQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: kilocaloriesBurned)
        
        return basalBurn
    }
    
    //MARK: - Convenience
    
    private func predicateForSamplesToday() -> Predicate
    {
        let (starDate, endDate): (Date, Date) = self.datesFromToday()
        
        let predicate: Predicate = HKQuery.predicateForSamples(withStart: starDate, end: endDate, options: HKQueryOptions.strictStartDate)
        
        return predicate
    }
    
    /// Returns BMR value in kilocalories per day. Note that there are different ways of calculating the
    /// BMR. In this example we chose an arbitrary function to calculate BMR based on weight, height, age,
    /// and biological sex.
    private func calculateBMRFromWeight(_ weightInKilograms: Double, height heightInCentimeters: Double, age ageInYears: Int, biologicalSex: HKBiologicalSex) -> Double
    {
        var BMR: Double = 0
        
        if biologicalSex == .male {
            BMR = 66.0 + (13.8 * weightInKilograms) + (5.0 * heightInCentimeters) - (6.8 * Double(ageInYears))
            
            return BMR
        }
        
        BMR = 655 + (9.6 * weightInKilograms) + (1.8 * heightInCentimeters) - (4.7 * Double(ageInYears))
        
        return BMR
    }
    
    private func datesFromToday() -> (Date, Date)
    {
        let calendar: Calendar = Calendar.current
        
        let nowDate: Date = Date()
        
        let starDate: Date = calendar.startOfDay(for: nowDate)
        let endDate: Date = calendar.date(byAdding: Calendar.Unit.day, value: 1, to: starDate, options: Calendar.Options())!
        
        return (starDate, endDate)
    }
    
    //MARK: Convert Energy Formatter
    
    private func stringFromJoules(_ joules: Double) -> String
    {
        let stringOfJourle: String = self.energyFormatter.string(fromJoules: joules)
        
        return stringOfJourle
    }
    
    //MARK: - UITableView DataSource Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.menu.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let CellIdentifier: String = "CellIdentifier"
        
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: CellIdentifier)
        }
        
        let title: String = self.menu[(indexPath as NSIndexPath).row]
        var detailText: String? = nil
        
        switch (indexPath as NSIndexPath).row {
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
        
        cell!.textLabel!.text = title
        cell!.detailTextLabel!.text = detailText!
        
        return cell!
    }
}
