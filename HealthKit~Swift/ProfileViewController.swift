//
//  ProfileViewController.swift
//  HealthKit~Swift
//
//  Created by EdenLi on 2014/9/17.
//  Copyright (c) 2014年 Darktt Personal Company. All rights reserved.
//

import UIKit
import HealthKit

class ProfileViewController: UITableViewController
{
    var healthStore: HKHealthStore?
    
    private var userProfiles: Dictionary<Keys, Array<String>>?
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        // Set up an HKHealthStore, asking the user for read/write permissions. The profile view controller is the
        // first view controller that's shown to the user, so we'll ask for all of the desired HealthKit permissions now.
        // In your own app, you should consider requesting permissions the first time a user wants to interact with
        // HealthKit data.
        guard HKHealthStore.isHealthDataAvailable() else {
            
            return
        }
        
        let writeDataTypes: Set<HKSampleType> = self.dataTypesToWrite()
        let readDataTypes: Set<HKObjectType> = self.dataTypesToRead()
        
        let completion: ((Bool, Error?) -> Void)! = {
            (success, error) -> Void in
            
            if let error = error {
                
                print("You didn't allow HealthKit to access these read/write data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: \(error.localizedDescription). If you're using a simulator, try it on a device.")
                
                return
            }

            DispatchQueue.main.async{

                // Update the user interface based on the current user's health information.
                self.updateUserAge()
                self.updateUsersHeight()
                self.updateUsersWeight()
            }
        }

        if let healthStore = self.healthStore {
            
            healthStore.requestAuthorization(toShare: writeDataTypes, read: readDataTypes, completion: completion)
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.title = "Your Profile"
        
        let ageUnit = NSLocalizedString("Age (yrs)", comment: "")
        let ageDetail = NSLocalizedString("Not available", comment: "")
        let heightUnit = NSLocalizedString("Height ()", comment: "")
        let heightDetail = NSLocalizedString("Not available", comment: "")
        let weightUnit = NSLocalizedString("Weight ()", comment: "")
        let weightDetail = NSLocalizedString("Not available", comment: "")
        
        self.userProfiles = [Keys.age: [ageUnit, ageDetail],
                             Keys.height: [heightUnit, heightDetail],
                             Keys.weight: [weightUnit, weightDetail]]
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
    
//MARK: - Private Methods -

fileprivate extension ProfileViewController
{
    //MARK: HealthKit Permissions
    
    fileprivate func dataTypesToWrite() -> Set<HKSampleType> {

        let dietaryCalorieEnergyType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!
        let activeEnergyBurnType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
        let heightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!
        let weightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        
        let writeDataTypes: Set<HKSampleType> = [dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType]
        
        return writeDataTypes
    }
    
    fileprivate func dataTypesToRead() -> Set<HKObjectType> {

        let dietaryCalorieEnergyType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!
        let activeEnergyBurnType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
        let heightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!
        let weightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        let birthdayType = HKQuantityType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!
        let biologicalSexType = HKQuantityType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!
        
        let readDataTypes: Set<HKObjectType> = [dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, birthdayType, biologicalSexType]
        
        return readDataTypes
    }
    
    //MARK: - Reading HealthKit Data
    
    fileprivate func updateUserAge() -> Void
    {
        var dateOfBirth: Date! = nil
        
        do {
            
            dateOfBirth = try self.healthStore?.dateOfBirth()
            
        } catch {
            
            print("Either an error occured fetching the user's age information or none has been stored yet. In your app, try to handle this gracefully.")

            return
        }
        
        let now = Date()
        
        let ageComponents: DateComponents = Calendar.current.dateComponents([.year], from: dateOfBirth, to: now)
        
        let userAge: Int = ageComponents.year!
        
        let ageValue: String = NumberFormatter.localizedString(from: userAge as NSNumber, number: NumberFormatter.Style.none)
        
        if var userProfiles = self.userProfiles,
           var age: Array<String> = userProfiles[Keys.age] {
            
            age[Profile.detail] = ageValue
            
            userProfiles[Keys.age] = age
            self.userProfiles = userProfiles
        }
        
        // Reload table view (only age row)
        let indexPath = IndexPath(row: TableViewIndex.age.rawValue, section: 0)
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    fileprivate func updateUsersHeight() -> Void
    {
        let setHeightInformationHandle: ((String) -> Void) = {
            
            [unowned self] (heightValue) -> Void in
            
            // Fetch user's default height unit in inches.
            let lengthFormatter = LengthFormatter()
            lengthFormatter.unitStyle = Formatter.UnitStyle.long
            
            let heightFormatterUnit = LengthFormatter.Unit.inch
            let heightUniString: String = lengthFormatter.unitString(fromValue: 10, unit: heightFormatterUnit)
            let localizedHeightUnitDescriptionFormat: String = NSLocalizedString("Height (%@)", comment: "");
            
            let heightUnitDescription: String = String(format: localizedHeightUnitDescriptionFormat, heightUniString);
            
            if var userProfiles = self.userProfiles,
               var height: Array<String> = userProfiles[Keys.height] {

                height[Profile.unit] = heightUnitDescription
                height[Profile.detail] = heightValue
                
                userProfiles[Keys.height] = height
                self.userProfiles = userProfiles
            }
            
            // Reload table view (only height row)
            let indexPath = IndexPath(row: TableViewIndex.height.rawValue, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
        
        let heightType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!
        
        // Query to get the user's latest height, if it exists.
        let completion: HKHealthStore.CompletionHandler = {
            
            (mostRecentQuantity, error) -> Void in

            guard let mostRecentQuantity = mostRecentQuantity else {

                print("Either an error occured fetching the user's height information or none has been stored yet. In your app, try to handle this gracefully.")

                DispatchQueue.main.async {

                    let heightValue: String = NSLocalizedString("Not available", comment: "")

                    setHeightInformationHandle(heightValue)
                }
                
                return
            }
            
            // Determine the height in the required unit.
            let heightUnit = HKUnit.inch()
            let usersHeight: Double = mostRecentQuantity.doubleValue(for: heightUnit)
            
            // Update the user interface.
            DispatchQueue.main.async {

                let heightValue: String = NumberFormatter.localizedString(from: usersHeight as NSNumber, number: NumberFormatter.Style.none)
                
                setHeightInformationHandle(heightValue)
            }
        }
        
        if let healthStore = self.healthStore {
            
            healthStore.mostRecentQuantitySample(ofType: heightType, completion: completion)
        }
    }
    
    fileprivate func updateUsersWeight()
    {
        let setWeightInformationHandle: ((String) -> Void) = {
            
            [unowned self] (weightValue) -> Void in
            
            // Fetch user's default height unit in inches.
            let massFormatter = MassFormatter()
            massFormatter.unitStyle = Formatter.UnitStyle.long
            
            let weightFormatterUnit = MassFormatter.Unit.pound
            let weightUniString: String = massFormatter.unitString(fromValue: 10, unit: weightFormatterUnit)
            let localizedHeightUnitDescriptionFormat: String = NSLocalizedString("Weight (%@)", comment: "");
            
            let weightUnitDescription = String(format: localizedHeightUnitDescriptionFormat, weightUniString);
            
            if var userProfiles = self.userProfiles,
               var weight: Array<String> = userProfiles[Keys.weight] {
                
                weight[Profile.unit] = weightUnitDescription
                weight[Profile.detail] = weightValue
                
                userProfiles[Keys.weight] = weight
                self.userProfiles = userProfiles
            }
            
            // Reload table view (only height row)
            let indexPath: IndexPath = IndexPath(row: TableViewIndex.weight.rawValue, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
        
        let weightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        
        // Query to get the user's latest weight, if it exists.
        let completion: HKHealthStore.CompletionHandler = {
            
            (mostRecentQuantity, error) -> Void in

            guard let mostRecentQuantity = mostRecentQuantity else {
                
                print("Either an error occured fetching the user's weight information or none has been stored yet. In your app, try to handle this gracefully.")
                
                DispatchQueue.main.async {

                    let weightValue: String = NSLocalizedString("Not available", comment: "")
                    
                    setWeightInformationHandle(weightValue)
                }
                
                return
            }
            
            // Determine the weight in the required unit.
            let weightUnit = HKUnit.pound()
            let usersWeight: Double = mostRecentQuantity.doubleValue(for: weightUnit)
            
            // Update the user interface.
            DispatchQueue.main.async {
                
                let weightValue: String = NumberFormatter.localizedString(from: usersWeight as NSNumber, number: NumberFormatter.Style.none)
                
                setWeightInformationHandle(weightValue)
            }
        }
        
        if let healthStore = self.healthStore {
            
            healthStore.mostRecentQuantitySample(ofType: weightType, completion: completion)
        }
    }
    
    fileprivate func saveHeightIntoHealthStore(_ height: Double)
    {
        // Save the user's height into HealthKit.
        let inchUnit = HKUnit.inch()
        let heightQuantity = HKQuantity(unit: inchUnit, doubleValue: height)
        
        let heightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!
        let nowDate = Date()
        
        let heightSample = HKQuantitySample(type: heightType, quantity: heightQuantity, start: nowDate, end: nowDate)
        
        let completion: ((Bool, Error?) -> Void) = {
            [unowned self] (success, error) -> Void in
            
            if let error = error {
                print("An error occured saving the height sample \(heightSample). In your app, try to handle this gracefully. The error was: \(error.localizedDescription).")
                
                abort()
            }
            
            self.updateUsersHeight()
        }
        
        if let healthStore = self.healthStore {
            
            healthStore.save(heightSample, withCompletion: completion)
        }
    }
    
    fileprivate func saveWeightIntoHealthStore(_ weight: Double) -> Void
    {
        // Save the user's weight into HealthKit.
        let poundUnit = HKUnit.pound()
        let weightQuantity = HKQuantity(unit: poundUnit, doubleValue: weight)
        
        let weightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        let nowDate = Date()
        
        let weightSample: HKQuantitySample = HKQuantitySample(type: weightType, quantity: weightQuantity, start: nowDate, end: nowDate)
        
        let completion: ((Bool, Error?) -> Void) = {
            [unowned self] (success, error) -> Void in
            
            if let error = error {
                
                print("An error occured saving the weight sample \(weightSample). In your app, try to handle this gracefully. The error was: \(error.localizedDescription).")
                
                abort()
            }
            
            self.updateUsersWeight()
        }
        
        if let healthStore = self.healthStore {
            healthStore.save(weightSample, withCompletion: completion)
        }
    }
}

// MARK: - Delegate Methods -

extension ProfileViewController
{
    //MARK: #UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int 
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let CellIdentifier: String = "CellIdentifier"
        
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        
        if cell == nil {
            
            cell = UITableViewCell(style: .value1, reuseIdentifier: CellIdentifier)
        }
        
        var profilekey: Keys = .age
        
        switch indexPath.row {
        case 0:
            profilekey = .age
            
        case 1:
            profilekey = .height
            
        case 2:
            profilekey = .weight
            
        default:
            break
        }
        
        if let profiles = self.userProfiles,
           let profile: Array<String> = profiles[profilekey] {
            
            cell?.textLabel?.text = profile.first
            cell?.detailTextLabel?.text = profile.last
        }
        
        return cell!
    }
    
    //MARK: #UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let index: TableViewIndex = TableViewIndex(rawValue: indexPath.row)!
        
        // We won't allow people to change their date of birth, so ignore selection of the age cell.
        if index == .age {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        // Set up variables based on what row the user has selected.
        var title: String?
        var valueChangedHandler: ((Double) -> Void)?
        
        if index == .height {
            title = NSLocalizedString("Your Height", comment: "")
            
            valueChangedHandler = {
                value -> Void in
                
                self.saveHeightIntoHealthStore(value)
            }
        }
        
        if index == .weight {
            title = NSLocalizedString("Your Weight", comment: "")
            
            valueChangedHandler = {
                value -> Void in
                
                self.saveWeightIntoHealthStore(value)
            }
        }
        
        // Create an alert controller to present.
        let alertController: UIAlertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        // Add the text field to let the user enter a numeric value.
        alertController.addTextField { 
            
            (textField) -> Void in
            // Only allow the user to enter a valid number.
            textField.keyboardType = UIKeyboardType.decimalPad
        }
        
        // Create the "OK" button.
        let okAction: UIAlertAction = {
            
            let okTitle: String = NSLocalizedString("OK", comment: "")
            let handler: (UIAlertAction) -> Void = {
                
                _ in
                
                let textField: UITextField?? = alertController.textFields?.first
                
                if let text: String = textField??.text,
                   let value = Double(text) {
                    
                    valueChangedHandler?(value)
                    
                    tableView.deselectRow(at: indexPath, animated: true)
                }
            }
            
            let alertAction = UIAlertAction(title: okTitle, style: .default, handler: handler)
            
            return alertAction
        }()
        
        alertController.addAction(okAction)
        
        // Create the "Cancel" button.
        let cancelAction: UIAlertAction = {
            
            let cancelTitle: String = NSLocalizedString("Cancel", comment: "")
            let handler: (UIAlertAction) -> Void = {
                
                _ in
                
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
            let alertAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: handler)
            
            return alertAction
        }()
        
        alertController.addAction(cancelAction)
        
        // Present the alert controller.
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Private Struct And Enumerators -

fileprivate extension ProfileViewController
{
    fileprivate struct Profile
    {
        fileprivate static let unit: Int = 0
        fileprivate static let detail: Int = 1
    }
    
    fileprivate enum TableViewIndex : Int
    {
        case age = 0
        case height
        case weight
    }
    
    fileprivate enum Keys : String
    {
        case age = "age"
        case height = "height"
        case weight = "weight"
    }
}
