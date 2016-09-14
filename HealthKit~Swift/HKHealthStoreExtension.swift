//
//  HKHealthStore+AAPLExtensions.swift
//  HealthKit~Swift
//
//  Created by EdenLi on 2014/9/17.
//  Copyright (c) 2014年 Darktt Personal Company. All rights reserved.
//

import Foundation
import HealthKit

typealias HKCompletionHandle = ((HKQuantity?, Error?) -> Void)

extension HKHealthStore {
    
    func getClassName(obj : AnyObject) -> String
    {
        let objectClass : AnyClass! = object_getClass(obj)
        let className = objectClass.description()
        
        return className
    }
    
    func mostRecentQuantitySample(ofType quantityType: HKQuantityType, predicate: NSPredicate? = nil, completion: HKCompletionHandle?)
    {
        let timeSortDescript: NSSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Since we are interested in retrieving the user's latest sample, we sort the samples in descending order, and set the limit to 1. We are not filtering the data, and so the predicate is set to nil.
        let query: HKSampleQuery = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: 1, sortDescriptors: [timeSortDescript]) {
            
            (query, results, error) -> Void in
            
            guard let results = results else {
                
                if let completion = completion {
                    completion(nil, error)
                }
                
                return
            }
            
            if let completion = completion, let quantitySample: HKQuantitySample = results.last as? HKQuantitySample {
                
                // If quantity isn't in the database, return nil in the completion block.
                let quantity: HKQuantity = quantitySample.quantity
                
                completion(quantity, error)
            }
        }
        
        self.execute(query)
    }
    
}
