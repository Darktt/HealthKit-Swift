//
//  ProfileViewController.swift
//  HealthKit~Swift
//
//  Created by EdenLi on 2014/9/17.
//  Copyright (c) 2014年 Darktt Personal Company. All rights reserved.
//

import UIKit
import HealthKit

enum ProfileViewControllerTableViewIndex : Int {
    case Age = 0
    case Height
    case Weight
}

enum ProfileKeys : String {
    case Age = "age"
    case Height = "height"
    case Weight = "weight"
}

class ProfileViewController: UITableViewController
{
    
    private let kProfileUnit = 0
    private let kProfileDetail = 1
    
    var healthStore: HKHealthStore?
    
    private var userProfiles: [ProfileKeys: [String]]?
    
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
            
            if !success {
                
                print("You didn't allow HealthKit to access these read/write data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: \(error). If you're using a simulator, try it on a device.")
                
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
        
        self.userProfiles = [ProfileKeys.Age: [NSLocalizedString("Age (yrs)", comment: ""), NSLocalizedString("Not available", comment: "")],
                             ProfileKeys.Height: [NSLocalizedString("Height ()", comment: ""), NSLocalizedString("Not available", comment: "")],
                             ProfileKeys.Weight: [NSLocalizedString("Weight ()", comment: ""), NSLocalizedString("Not available", comment: "")]]
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//MARK: - Private Method
//MARK: HealthKit Permissions
    
    private func dataTypesToWrite() -> Set<HKSampleType> {

        let dietaryCalorieEnergyType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!
        let activeEnergyBurnType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
        let heightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!
        let weightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        
        let writeDataTypes: Set<HKSampleType> = [dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType]
        
        return writeDataTypes
    }
    
    private func dataTypesToRead() -> Set<HKObjectType> {

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
    
    private func updateUserAge() -> Void
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
        
        if var userProfiles = self.userProfiles {
            
            var age: [String] = userProfiles[ProfileKeys.Age] as [String]!
            age[kProfileDetail] = ageValue
            
            userProfiles[ProfileKeys.Age] = age
            self.userProfiles = userProfiles
        }
        
        // Reload table view (only age row)
        let indexPath = IndexPath(row: ProfileViewControllerTableViewIndex.Age.rawValue, section: 0)
        self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
    }
    
    private func updateUsersHeight() -> Void
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
            
            if var userProfiles = self.userProfiles {

                var height: [String] = userProfiles[ProfileKeys.Height] as [String]!
                height[self.kProfileUnit] = heightUnitDescription
                height[self.kProfileDetail] = heightValue
                
                userProfiles[ProfileKeys.Height] = height
                self.userProfiles = userProfiles
            }
            
            // Reload table view (only height row)
            let indexPath = IndexPath(row: ProfileViewControllerTableViewIndex.Height.rawValue, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
        }
        
        let heightType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!
        
        // Query to get the user's latest height, if it exists.
        let completion: HKCompletionHandle = {
            
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
    
    private func updateUsersWeight() -> Void
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
            
            if var userProfiles = self.userProfiles {
                var weight: [String] = userProfiles[ProfileKeys.Weight] as [String]!
                weight[self.kProfileUnit] = weightUnitDescription
                weight[self.kProfileDetail] = weightValue
                
                userProfiles[ProfileKeys.Weight] = weight
                self.userProfiles = userProfiles
            }
            
            // Reload table view (only height row)
            let indexPath: IndexPath = IndexPath(row: ProfileViewControllerTableViewIndex.Weight.rawValue, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
        }
        
        let weightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        
        // Query to get the user's latest weight, if it exists.
        let completion: HKCompletionHandle = {
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
    
    private func saveHeightIntoHealthStore(_ height: Double) -> Void
    {
        // Save the user's height into HealthKit.
        let inchUnit = HKUnit.inch()
        let heightQuantity = HKQuantity(unit: inchUnit, doubleValue: height)
        
        let heightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!
        let nowDate = Date()
        
        let heightSample = HKQuantitySample(type: heightType, quantity: heightQuantity, start: nowDate, end: nowDate)
        
        let completion: ((Bool, Error?) -> Void) = {
            [unowned self] (success, error) -> Void in
            
            if !success {
                print("An error occured saving the height sample \(heightSample). In your app, try to handle this gracefully. The error was: \(error).")
                
                abort()
            }
            
            self.updateUsersHeight()
        }
        
        if let healthStore = self.healthStore {
            
            healthStore.save(heightSample, withCompletion: completion)
        }
    }
    
    private func saveWeightIntoHealthStore(_ weight: Double) -> Void
    {
        // Save the user's weight into HealthKit.
        let poundUnit = HKUnit.pound()
        let weightQuantity = HKQuantity(unit: poundUnit, doubleValue: weight)
        
        let weightType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!
        let nowDate = Date()
        
        let weightSample: HKQuantitySample = HKQuantitySample(type: weightType, quantity: weightQuantity, start: nowDate, end: nowDate)
        
        let completion: ((Bool, Error?) -> Void) = {
            [unowned self] (success, error) -> Void in
            
            if !success {
                print("An error occured saving the weight sample \(weightSample). In your app, try to handle this gracefully. The error was: \(error).")
                
                abort()
            }
            
            self.updateUsersWeight()
        }
        
        if let healthStore = self.healthStore {
            healthStore.save(weightSample, withCompletion: completion)
        }
    }
    
//MARK: - UITableViewDataSource Methods
    
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
            cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: CellIdentifier)
        }
        
        var profilekey: ProfileKeys?
        
        switch indexPath.row {
        case 0:
            profilekey = .Age
            
        case 1:
            profilekey = .Height
            
        case 2:
            profilekey = .Weight
            
        default:
            break
        }
        
        if let profiles = self.userProfiles {
            let profile: [String] = profiles[profilekey!] as [String]!
            
            cell!.textLabel!.text = profile.first as String!
            cell!.detailTextLabel!.text = profile.last as String!
        }
        
        return cell!
    }
    
//MARK: - UITableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let index: ProfileViewControllerTableViewIndex = ProfileViewControllerTableViewIndex(rawValue: indexPath.row)!
        
        // We won't allow people to change their date of birth, so ignore selection of the age cell.
        if index == .Age {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        // Set up variables based on what row the user has selected.
        var title: String?
        var valueChangedHandler: ((Double) -> Void)?
        
        if index == .Height {
            title = NSLocalizedString("Your Height", comment: "")
            
            valueChangedHandler = {
                value -> Void in
                
                self.saveHeightIntoHealthStore(value)
            }
        }
        
        if index == .Weight {
            title = NSLocalizedString("Your Weight", comment: "")
            
            valueChangedHandler = {
                value -> Void in
                
                self.saveWeightIntoHealthStore(value)
            }
        }
        
        // Create an alert controller to present.
        let alertController: UIAlertController = UIAlertController(title: title, message: nil, preferredStyle: UIAlertControllerStyle.alert)
        
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
                
                let textField: UITextField = alertController.textFields!.first!
                
                if let text: String = textField.text, let value: Double = Double(text) {
                    
                    valueChangedHandler!(value)
                    
                    tableView.deselectRow(at: indexPath, animated: true)
                }
            }
            
            return UIAlertAction(title: okTitle, style: UIAlertActionStyle.default, handler: handler)
        }()
        
        alertController.addAction(okAction)
        
        // Create the "Cancel" button.
        let cancelAction: UIAlertAction = {
            
            let cancelTitle: String = NSLocalizedString("Cancel", comment: "")
            let handler: (UIAlertAction) -> Void = {
                
                _ in
                
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
            return UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.cancel, handler: handler)
        }()
        
        alertController.addAction(cancelAction)
        
        // Present the alert controller.
        self.present(alertController, animated: true, completion: nil)
    }
}
