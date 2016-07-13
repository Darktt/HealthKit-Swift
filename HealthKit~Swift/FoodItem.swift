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
    var name: String {
        get {
            return _name!
        }
    }
    
    private var _name: String?
    
    var joules: Double {
        get {
            return _joules!
        }
    }
    
    private var _joules: Double?
    
    class func foodItem(_ name: String, joules: Double) -> FoodItem
    {
        let item: FoodItem = FoodItem(name: name, joules: joules)
        
        return item
    }
    
    init(name: String, joules: Double) {
        super.init()
        
        self._name = name
        self._joules = joules
    }
    
    override func isEqual(_ object: AnyObject?) -> Bool {
        if object!.isKind(of: object_getClass(FoodItem)) {
            return (object!.joules == self.joules) && (object!.name == self.name)
        }
        
        return false
    }
}
