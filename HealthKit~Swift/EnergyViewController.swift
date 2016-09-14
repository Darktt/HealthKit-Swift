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
        
        lazy var netEnergy: Double = {
            
            return self.energyConsumed - self.activeEnergyBurned - self.restingEnergyBurned
        }()
    }
    
    private let energyStore: Energy = Energy()
    private var menu: Array<String> = ["Resting Burn", "Active Burn", "Consumed", "Net"]
    
    private var energyFormatter: EnergyFormatter {
        
        let energyFormatter = EnergyFormatter()
        energyFormatter.unitStyle = Formatter.UnitStyle.long
        energyFormatter.isForFoodEnergyUse = true
        energyFormatter.numberFormatter.maximumFractionDigits = 2
        
        return energyFormatter
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.refreshStatistics()
        
        NotificationCenter.default.addObserver(self, selector: #selector(EnergyViewController.refreshStatistics), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = self.navigationController?.title
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(EnergyViewController.refreshStatistics), for: UIControlEvents.valueChanged)
        
        self.refreshControl = refreshControl
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
        
        let energyConsumedType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!
        let activeEnergyBurnType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
        
        // First, fetch the sum of energy consumed samples from HealthKit. Populate this by creating your
        // own food logging app or using the food journal view controller.
        let completeFirstTime: ((Double, Error?) -> Void) = {
            
            (totalJoulesConsumed, error) -> Void in
            
            // Next, fetch the sum of active energy burned from HealthKit. Populate this by creating your
            // own calorie tracking app or the Health app.
            let completeSecondTime: ((Double, Error?) -> Void) = {
                
                (activeEnergyBurned, error) -> Void in
                
                // Last, calculate the user's basal energy burn so far today.
                let completion: ((HKQuantity?, Error?) -> Void) = {
                    
                    [unowned self] (basalEnergyBurn, error) -> Void in
                    
                    guard let basalEnergyBurn = basalEnergyBurn else {
                        print("An error occurred trying to compute the basal energy burn. In your app, handle this gracefully. Error: \(error)")
                        
                        return
                    }
                    
                    // Update the UI with all of the fetched values.
                    DispatchQueue.main.async {
                        
                        self.energyStore.activeEnergyBurned = activeEnergyBurned
                        
                        self.energyStore.restingEnergyBurned = basalEnergyBurn.doubleValue(for: HKUnit.joule())
                        
                        self.energyStore.energyConsumed = totalJoulesConsumed
                        
                        self.refreshControl!.endRefreshing()
                        self.tableView!.reloadData()
                    }
                    
                }
                
                self.fetchTotalBasalBurn(completion: completion)
                
            }
            
            self.fetchSumOfSamplesTodayForType(quantityType: activeEnergyBurnType, unit: HKUnit.joule(), completion: completeSecondTime)
        }
        
        self.fetchSumOfSamplesTodayForType(quantityType: energyConsumedType, unit: HKUnit.joule(), completion: completeFirstTime)
    }
    
    private func fetchSumOfSamplesTodayForType(quantityType: HKQuantityType, unit: HKUnit, completion completionHandler: ((Double, Error?) -> Void)?)
    {
        let predicate = self.predicateForSamplesToday()
        let completionHandler: (HKStatisticsQuery, HKStatistics?, Error?) -> Void = {
            (_query, result, error) -> Void in
            
            let sum: HKQuantity? = result!.sumQuantity()
            
            if completionHandler != nil {
                let value: Double = (sum != nil) ? sum!.doubleValue(for: unit) : 0
                
                completionHandler!(value, error)
            }
        }
        
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: HKStatisticsOptions.cumulativeSum, completionHandler: completionHandler) 
        
        if let healthStore = self.healthStore {
         
            healthStore.execute(query)
        }
    }
    
    // Calculates the user's total basal (resting) energy burn based off of their height, weight, age,
    // and biological sex. If there is not enough information, return an error.
    private func fetchTotalBasalBurn(completion: @escaping (HKQuantity?, Error?) -> Void)
    {
        let todayPredicate: NSPredicate = self.predicateForSamplesToday()
        
        let weightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        let heightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!
        
        let queryWeigth: HKCompletionHandle = {
            (weight, error) -> Void in
            
            guard let weight = weight else {
                completion(nil, error)
                
                return
            }
            
            let queryHeigth: HKCompletionHandle = {
                (height, error) -> Void in
                
                if height == nil {
                    completion(nil, error)
                    
                    return;
                }
                
                var dateOfBirth: Date!
                
                do {
                    
                    dateOfBirth = try self.healthStore!.dateOfBirth()
                    
                } catch {
                    
                    completion(nil, error)
                    
                    return
                }
                
                var biologicalSexObjet: HKBiologicalSexObject!
                
                do {
                
                    biologicalSexObjet = try self.healthStore!.biologicalSex()
                    
                } catch {
                    
                    completion(nil, error)
                    
                    return
                }
                
                // Once we have pulled all of the information without errors, calculate the user's total basal energy burn
                let basalEnergyButn: HKQuantity? = self.calculateBasalBurnTodayFromWeight(weight, height: height, dateOfBirth: dateOfBirth!, biologicalSex: biologicalSexObjet)
                
                completion(basalEnergyButn, nil)
            }
            
            if let healthStore = self.healthStore {
                
                healthStore.mostRecentQuantitySample(ofType: heightType, predicate: todayPredicate, completion: queryHeigth)
            }
        }
        
        if let healthStore = self.healthStore {
            healthStore.mostRecentQuantitySample(ofType: weightType, predicate: nil, completion: queryWeigth)
        }
    }
    
    private func calculateBasalBurnTodayFromWeight(_ weight: HKQuantity?, height: HKQuantity?, dateOfBirth: Date, biologicalSex: HKBiologicalSexObject) -> HKQuantity?
    {
        // Only calculate Basal Metabolic Rate (BMR) if we have enough information about the user
        guard let weight = weight, let height = height else {
            
            return nil
        }
        
        // Note the difference between calling +unitFromString: vs creating a unit from a string with
        // a given prefix. Both of these are equally valid, however one may be more convenient for a given
        // use case.
        let heightInCentimeters: Double = height.doubleValue(for: HKUnit(from:"cm"))
        let weightInKilograms: Double = weight.doubleValue(for: HKUnit.gramUnit(with: HKMetricPrefix.kilo))
        
        let nowDate = Date()
        let ageComponents: DateComponents = Calendar.current.dateComponents([Calendar.Component.year], from: dateOfBirth, to: nowDate)
        let ageInYears: Int = ageComponents.year!
        
        // BMR is calculated in kilocalories per day.
        let BMR: Double = self.calculateBMRFromWeight(weightInKilograms: weightInKilograms, height: heightInCentimeters, age: ageInYears, biologicalSex: biologicalSex.biologicalSex)
        
        // Figure out how much of today has completed so we know how many kilocalories the user has burned.
        let (startOfToday, endOfToday): (Date, Date) = self.datesFromToday()
        
        let secondsInDay: TimeInterval = endOfToday.timeIntervalSince(startOfToday)
        let percentOfDayComplete: Double = nowDate.timeIntervalSince(startOfToday) / secondsInDay
        
        let kilocaloriesBurned: Double = BMR * percentOfDayComplete
        
        let basalBurn = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: kilocaloriesBurned)
        
        return basalBurn
    }
    
    //MARK: - Convenience
    
    private func predicateForSamplesToday() -> NSPredicate
    {
        let (starDate, endDate): (Date, Date) = self.datesFromToday()
        
        let predicate: NSPredicate = HKQuery.predicateForSamples(withStart: starDate, end: endDate, options: HKQueryOptions.strictStartDate)
        
        return predicate
    }
    
    /// Returns BMR value in kilocalories per day. Note that there are different ways of calculating the
    /// BMR. In this example we chose an arbitrary function to calculate BMR based on weight, height, age,
    /// and biological sex.
    private func calculateBMRFromWeight(weightInKilograms: Double, height heightInCentimeters: Double, age ageInYears: Int, biologicalSex: HKBiologicalSex) -> Double
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
        let calendar = Calendar.current
        
        let nowDate = Date()
        
        let starDate: Date = calendar.startOfDay(for: nowDate)
        let endDate: Date = calendar.date(byAdding: Calendar.Component.day, value: 1, to: starDate)!
        
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
            cell!.selectionStyle = .none
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
        
        cell!.textLabel!.text = title
        cell!.detailTextLabel!.text = detailText!
        
        return cell!
    }
}
