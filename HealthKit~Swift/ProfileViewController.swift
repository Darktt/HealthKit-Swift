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

class ProfileViewController: UITableViewController {
    
    let kProfileUnit = 0
    let kProfileDetail = 1
    
    var healthStore: HKHealthStore?
    var userProfiles: [ProfileKeys: [String]]?
    
    override func viewDidAppear(animated: Bool) {
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
        
        var completion: ((Bool, NSError!) -> Void)! = { (success, error) -> Void in
            if !success {
                println("You didn't allow HealthKit to access these read/write data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: (error). If you're using a simulator, try it on a device.")
                
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                // Update the user interface based on the current user's health information.
                self.updateUserAge()
                self.updateUsersHeight()
                self.updateUsersWeight()
            })
        }
        
        self.healthStore?.requestAuthorizationToShareTypes(writeDataTypes, readTypes: readDataTypes, completion: completion)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.title = "Your Profile"
        
        self.userProfiles = [ProfileKeys.Age: [NSLocalizedString("Age (yrs)", comment: ""), "Not available"],
                             ProfileKeys.Height: [NSLocalizedString("Height ()", comment: ""), "Not available"],
                             ProfileKeys.Weight: [NSLocalizedString("Weight ()", comment: ""), "Not available"]]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//MARK: - Private Method
//MARK: HealthKit Permissions
    
    func dataTypesToWrite() -> NSSet {
        var dietaryCalorieEnergyType: HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryEnergyConsumed)
        var activeEnergyBurnType: HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)
        var heightType:  HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)
        var weightType: HKQuantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
        
        var writeDataTypes: NSSet = NSSet(objects: dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType)
        
        return writeDataTypes
    }
    
    func dataTypesToRead() -> NSSet {
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
    
    func updateUserAge() -> Void
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
        
        var indexPath: NSIndexPath = NSIndexPath(forRow: ProfileViewControllerTableViewIndex.Age.toRaw(), inSection: 0)
        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
    
    func updateUsersHeight() -> Void {
        var indexPath: NSIndexPath = NSIndexPath(forRow: ProfileViewControllerTableViewIndex.Height.toRaw(), inSection: 0)
        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
    
    func updateUsersWeight() -> Void {
        var indexPath: NSIndexPath = NSIndexPath(forRow: ProfileViewControllerTableViewIndex.Weight.toRaw(), inSection: 0)
        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
    
//MARK: - UITableView DataSource Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
            println()
        }
        
        if let profiles = self.userProfiles {
            var profile: [String] = profiles[profilekey!] as [String]!
            
            cell?.textLabel?.text = profile.first as String!
            cell?.detailTextLabel?.text = profile.last as String!
        }
        
        return cell!
    }
    
//MARK: - UITableView Delegate Methods
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var index: ProfileViewControllerTableViewIndex = ProfileViewControllerTableViewIndex.fromRaw(indexPath.row)!
        
        // We won't allow people to change their date of birth, so ignore selection of the age cell.
        if index == .Age {
            return
        }
        
        // Set up variables based on what row the user has selected.
        var title: String?
        var valueChangedHandler: (Double -> Void)?
        
        if index == .Height {
            title = NSLocalizedString("Your Height", comment: "")
            
            valueChangedHandler = { value -> Void in
//                [self saveHeightIntoHealthStore:value];
            }
        }
        
        if index == .Weight {
            title = NSLocalizedString("Your Weight", comment: "")
            
            valueChangedHandler = { value -> Void in
//                [self saveWeightIntoHealthStore:value];
            }
        }
        
        // Create an alert controller to present.
        var alertController: UIAlertController = UIAlertController(title: title, message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        // Add the text field to let the user enter a numeric value.
        alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
            // Only allow the user to enter a valid number.
            textField.keyboardType = UIKeyboardType.DecimalPad
        }
        
        // Create the "OK" button.
        var okTitle: String = NSLocalizedString("OK", comment: "")
        var okAction: UIAlertAction = UIAlertAction(title: okTitle, style: UIAlertActionStyle.Default) { (action) -> Void in
            var textField: UITextField = alertController.textFields?.first as UITextField
            
            var text: NSString = textField.text
            var value: Double = text.doubleValue
            
            valueChangedHandler!(value)
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        alertController.addAction(okAction)
        
        // Create the "Cancel" button.
        var cancelTitle: String = NSLocalizedString("Cancel", comment: "")
        var cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.Cancel) { (action) -> Void in
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        alertController.addAction(cancelAction)
        
        // Present the alert controller.
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
