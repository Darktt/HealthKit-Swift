//
//  FoodItem.swift
//  HealthKit~Swift
//
//  Created by EdenLi on 2014/9/17.
//  Copyright (c) 2014年 Darktt Personal Company. All rights reserved.
//

import UIKit

class FoodItem: NSObject
{
    private(set) var name: String
    private(set) var joules: Double
    
    class func foodItem(name: String, joules: Double) -> FoodItem
    {
        let item: FoodItem = FoodItem(name: name, joules: joules)
        
        return item
    }
    
    init(name: String, joules: Double) 
    {
        self.name = name
        self.joules = joules
        
        super.init()
    }
    
    override func isEqual(_ object: Any?) -> Bool 
    {
        guard let object = object as? FoodItem else {
            
            return false
        }
        
        return (object.joules == self.joules) && (object.name == self.name)
    }
}
