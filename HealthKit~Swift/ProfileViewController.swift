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
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        // Set up an HKHealthStore, asking the user for read/write permissions. The profile view controller is the
        // first view controller that's shown to the user, so we'll ask for all of the desired HealthKit permissions now.
        // In your own app, you should consider requesting permissions the first time a user wants to interact with
        // HealthKit data.
        if !HKHealthStore.isHealthDataAvailable() {
            return
        }
        
        var writeDataTypes: NSSet = self.dataTypesToWrite()
        var readDataTypes: NSSet = self.dataTypesToRead()
        
        var completion: ((Bool, NSError!) -> Void)! = {
            (success, error) -> Void in
            
            if !success {
                println("You didn't allow HealthKit to access these read/write data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: \(error). If you're using a simulator, try it on a device.")
                
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                () -> Void in
                
                // Update the user interface based on the current user's health information.
                self.updateUserAge()
                self.updateUsersHeight()
                self.updateUsersWeight()
            })
        }
        
        self.healthStore?.requestAuthorizationToShareTypes(writeDataTypes, readTypes: readDataTypes, completion: completion)
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
    
    private func dataTypesToWrite() -> NSSet
    {
        var dietaryCalorieEnergyType: HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)
        var activeEnergyBurnType: HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)
        var heightType:  HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)
        var weightType: HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
        
        var writeDataTypes: NSSet = NSSet(objects: dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType)
        
        return writeDataTypes
    }
    
    private func dataTypesToRead() -> NSSet
    {
        var dietaryCalorieEnergyType: HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)
        var activeEnergyBurnType: HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)
        var heightType:  HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)
        var weightType: HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
        var birthdayType: HKCharacteristicType = HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)
        var biologicalSexType: HKCharacteristicType = HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)
        
        var readDataTypes: NSSet = NSSet(objects: dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, birthdayType, biologicalSexType)
        
        return readDataTypes
    }
    
//MARK: - Reading HealthKit Data
    
    private func updateUserAge() -> Void
    {
        var error: NSError?
        let dateOfBirth = self.healthStore?.dateOfBirthWithError(&error)
        
        if dateOfBirth == nil {
            println("Either an error occured fetching the user's age information or none has been stored yet. In your app, try to handle this gracefully.")
            
            return
        }
        
        var now: NSDate = NSDate.date()
        
        var ageComponents: NSDateComponents = NSCalendar.currentCalendar().components(NSCalendarUnit.YearCalendarUnit, fromDate: dateOfBirth!, toDate: now, options: NSCalendarOptions.WrapComponents)
        
        var userAge: Int = ageComponents.year
        
        var ageValue: String = NSNumberFormatter.localizedStringFromNumber(userAge, numberStyle: NSNumberFormatterStyle.NoStyle)
        
        if var userProfiles = self.userProfiles {
            var age: [String] = userProfiles[ProfileKeys.Age] as [String]!
            age[kProfileDetail] = ageValue
            
            userProfiles[ProfileKeys.Age] = age
            self.userProfiles = userProfiles
        }
        
        // Reload table view (only age row)
        var indexPath: NSIndexPath = NSIndexPath(forRow: ProfileViewControllerTableViewIndex.Age.toRaw(), inSection: 0)
        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
    
    private func updateUsersHeight() -> Void
    {
        let setHeightInformationHandle: ((String) -> Void) = {
            (heightValue) -> Void in
            
            // Fetch user's default height unit in inches.
            let lengthFormatter: NSLengthFormatter = NSLengthFormatter()
            lengthFormatter.unitStyle = NSFormattingUnitStyle.Long
            
            let heightFormatterUnit: NSLengthFormatterUnit = .Inch
            let heightUniString: String = lengthFormatter.unitStringFromValue(10, unit: heightFormatterUnit)
            let localizedHeightUnitDescriptionFormat: String = NSLocalizedString("Height (%@)", comment: "");
            
            let heightUnitDescription: NSString = NSString(format: localizedHeightUnitDescriptionFormat, heightUniString);
            
            if var userProfiles = self.userProfiles {
                var height: [String] = userProfiles[ProfileKeys.Height] as [String]!
                height[self.kProfileUnit] = heightUnitDescription
                height[self.kProfileDetail] = heightValue
                
                userProfiles[ProfileKeys.Height] = height
                self.userProfiles = userProfiles
            }
            
            // Reload table view (only height row)
            let indexPath: NSIndexPath = NSIndexPath(forRow: ProfileViewControllerTableViewIndex.Height.toRaw(), inSection: 0)
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        }
        
        let heightType: HKQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)
        
        // Query to get the user's latest height, if it exists.
        let completion: HKCompletionHandle = {
            (mostRecentQuantity, error) -> Void in
            
            if mostRecentQuantity == nil {
                println("Either an error occured fetching the user's height information or none has been stored yet. In your app, try to handle this gracefully.")
                
                dispatch_async(dispatch_get_main_queue(), {
                    () -> Void in
                    let heightValue: String = NSLocalizedString("Not available", comment: "")
                    
                    setHeightInformationHandle(heightValue)
                })
                
                return
            }
            
            // Determine the height in the required unit.
            let heightUnit: HKUnit = HKUnit.inchUnit()
            let usersHeight: Double = mostRecentQuantity.doubleValueForUnit(heightUnit)
            
            // Update the user interface.
            dispatch_async(dispatch_get_main_queue(), {
                () -> Void in
                let heightValue: String = NSNumberFormatter.localizedStringFromNumber(NSNumber(double: usersHeight), numberStyle: NSNumberFormatterStyle.NoStyle)
                
                setHeightInformationHandle(heightValue)
            })
        }
        
        self.healthStore!.mostRecentQuantitySampleOfType(heightType, predicate: nil, completion: completion)
    }
    
    private func updateUsersWeight() -> Void
    {
        let setWeightInformationHandle: ((String) -> Void) = {
            (weightValue) -> Void in
            
            // Fetch user's default height unit in inches.
            let massFormatter: NSMassFormatter = NSMassFormatter()
            massFormatter.unitStyle = NSFormattingUnitStyle.Long
            
            let weightFormatterUnit: NSMassFormatterUnit = .Pound
            let weightUniString: String = massFormatter.unitStringFromValue(10, unit: weightFormatterUnit)
            let localizedHeightUnitDescriptionFormat: String = NSLocalizedString("Weight (%@)", comment: "");
            
            let weightUnitDescription: NSString = NSString(format: localizedHeightUnitDescriptionFormat, weightUniString);
            
            if var userProfiles = self.userProfiles {
                var weight: [String] = userProfiles[ProfileKeys.Weight] as [String]!
                weight[self.kProfileUnit] = weightUnitDescription
                weight[self.kProfileDetail] = weightValue
                
                userProfiles[ProfileKeys.Weight] = weight
                self.userProfiles = userProfiles
            }
            
            // Reload table view (only height row)
            let indexPath: NSIndexPath = NSIndexPath(forRow: ProfileViewControllerTableViewIndex.Weight.toRaw(), inSection: 0)
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        }
        
        let weightType: HKQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
        
        // Query to get the user's latest weight, if it exists.
        let completion: HKCompletionHandle = {
            (mostRecentQuantity, error) -> Void in
            
            if mostRecentQuantity == nil {
                println("Either an error occured fetching the user's weight information or none has been stored yet. In your app, try to handle this gracefully.")
                
                dispatch_async(dispatch_get_main_queue(), {
                    () -> Void in
                    let weightValue: String = NSLocalizedString("Not available", comment: "")
                    
                    setWeightInformationHandle(weightValue)
                })
                
                return
            }
            
            // Determine the weight in the required unit.
            let weightUnit: HKUnit = HKUnit.poundUnit()
            let usersWeight: Double = mostRecentQuantity.doubleValueForUnit(weightUnit)
            
            // Update the user interface.
            dispatch_async(dispatch_get_main_queue(), {
                () -> Void in
                let weightValue: String = NSNumberFormatter.localizedStringFromNumber(NSNumber(double: usersWeight), numberStyle: NSNumberFormatterStyle.NoStyle)
                
                setWeightInformationHandle(weightValue)
            })
        }
        
        self.healthStore!.mostRecentQuantitySampleOfType(weightType, predicate: nil, completion: completion)
    }
    
    private func saveHeightIntoHealthStore(height:Double) -> Void
    {
        // Save the user's height into HealthKit.
        let inchUnit: HKUnit = HKUnit.inchUnit()
        let heightQuantity: HKQuantity = HKQuantity(unit: inchUnit, doubleValue: height)
        
        let heightType: HKQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)
        let nowDate: NSDate = NSDate()
        
        let heightSample: HKQuantitySample = HKQuantitySample(type: heightType, quantity: heightQuantity, startDate: nowDate, endDate: nowDate)
        
        let completion: ((Bool, NSError!) -> Void) = {
            (success, error) -> Void in
            
            if !success {
                println("An error occured saving the height sample \(heightSample). In your app, try to handle this gracefully. The error was: \(error).")
                
                abort()
            }
            
            self.updateUsersHeight()
        }
        
        self.healthStore!.saveObject(heightSample, withCompletion: completion)
    }
    
    private func saveWeightIntoHealthStore(weight:Double) -> Void
    {
        // Save the user's weight into HealthKit.
        let poundUnit: HKUnit = HKUnit.poundUnit()
        let weightQuantity: HKQuantity = HKQuantity(unit: poundUnit, doubleValue: weight)
        
        let weightType: HKQuantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
        let nowDate: NSDate = NSDate()
        
        let weightSample: HKQuantitySample = HKQuantitySample(type: weightType, quantity: weightQuantity, startDate: nowDate, endDate: nowDate)
        
        let completion: ((Bool, NSError!) -> Void) = {
            (success, error) -> Void in
            
            if !success {
                println("An error occured saving the weight sample \(weightSample). In your app, try to handle this gracefully. The error was: \(error).")
                
                abort()
            }
            
            self.updateUsersWeight()
        }
        
        self.healthStore!.saveObject(weightSample, withCompletion: completion)
    }
    
//MARK: - UITableView DataSource Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 3
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let CellIdentifier: String = "CellIdentifier"
        
        var cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: CellIdentifier)
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
            var profile: [String] = profiles[profilekey!] as [String]!
            
            cell?.textLabel?.text = profile.first as String!
            cell?.detailTextLabel?.text = profile.last as String!
        }
        
        return cell!
    }
    
//MARK: - UITableView Delegate Methods
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let index: ProfileViewControllerTableViewIndex = ProfileViewControllerTableViewIndex.fromRaw(indexPath.row)!
        
        // We won't allow people to change their date of birth, so ignore selection of the age cell.
        if index == .Age {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            return
        }
        
        // Set up variables based on what row the user has selected.
        var title: String?
        var valueChangedHandler: (Double -> Void)?
        
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
        let alertController: UIAlertController = UIAlertController(title: title, message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        // Add the text field to let the user enter a numeric value.
        alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
            // Only allow the user to enter a valid number.
            textField.keyboardType = UIKeyboardType.DecimalPad
        }
        
        // Create the "OK" button.
        let okTitle: String = NSLocalizedString("OK", comment: "")
        let okAction: UIAlertAction = UIAlertAction(title: okTitle, style: UIAlertActionStyle.Default) { (action) -> Void in
            let textField: UITextField = alertController.textFields?.first as UITextField
            
            let text: NSString = textField.text
            let value: Double = text.doubleValue
            
            valueChangedHandler!(value)
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        alertController.addAction(okAction)
        
        // Create the "Cancel" button.
        let cancelTitle: String = NSLocalizedString("Cancel", comment: "")
        let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.Cancel) { (action) -> Void in
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        alertController.addAction(cancelAction)
        
        // Present the alert controller.
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
