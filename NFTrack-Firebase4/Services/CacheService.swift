//
//  CacheService.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-09-18.
//

import UIKit

final class CacheManager: NSCache<AnyObject, UIImage> {
    static let shared = CacheManager()
    
    /// Note, this is `private` to avoid subclassing this; singletons shouldn't be subclassed.
    /// Add observer to purge cache upon memory pressure.
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.configureActivityIndicatorPosition), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    /// The singleton will never be deallocated, but as a matter of defensive programming (in case this is
    /// later refactored to not be a singleton), let's remove the observer if deallocated.
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    /// Subscript operation to retrieve and update
    subscript(key: String) -> UIImage? {
        get {
            return object(forKey: key as AnyObject)
        }
        
        set (newValue) {
            if let object = newValue {
                setObject(object, forKey: key as AnyObject)
            } else {
                removeObject(forKey: key as AnyObject)
            }
        }
    }
    
    /// Subscript operation to retrieve and update
    subscript(key: Int) -> UIImage? {
        get {
            return object(forKey: key as AnyObject)
        }
        
        set (newValue) {
            if let object = newValue {
                setObject(object, forKey: key as AnyObject)
            } else {
                removeObject(forKey: key as AnyObject)
            }
        }
    }
    
    @objc func configureActivityIndicatorPosition() {
        self.removeAllObjects()
    }
}

final class CacheService: GenericCache<AnyObject, AnyObject> {
    static let shared = CacheService()
    
    /// Note, this is `private` to avoid subclassing this; singletons shouldn't be subclassed.
    /// Add observer to purge cache upon memory pressure.
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.configureActivityIndicatorPosition), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    /// The singleton will never be deallocated, but as a matter of defensive programming (in case this is
    /// later refactored to not be a singleton), let's remove the observer if deallocated.
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    /// Subscript operation to retrieve and update
    subscript(key: AnyObject) -> AnyObject? {
        get {
            return object(forKey: key)
        }
        
        set (newValue) {
            if let object = newValue {
                setObject(object, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }
    
    @objc func configureActivityIndicatorPosition() {
        self.removeAllObjects()
    }
}

//KeyType is T, ObjectType is U
class GenericCache<T: AnyObject, U: AnyObject> {
    private var cache = NSCache<T, U>()
    var delegate: NSCacheDelegate? {
        get { return self.cache.delegate }
        set { self.cache.delegate = newValue }
    }
    
    var name: String {
        get { return self.cache.name }
        set { self.cache.name = newValue }
    }
    
    func object(forKey: T) -> U? {
        let forKey = forKey
        return self.cache.object(forKey: forKey)
    }
    
    func setObject(_ obj: U, forKey key: T) {
        self.cache.setObject(obj, forKey: key)
    }
    
    func setObject(_ obj: U, forKey key: T, cost g: Int) {
        self.cache.setObject(obj, forKey: key, cost: g)
    }
    
    func removeObject(forKey: T) {
        self.cache.removeObject(forKey: forKey)
    }
    
    func removeAllObjects() {
        self.cache.removeAllObjects()
    }
    
    var totalCostLimit: Int {
        get { return self.cache.totalCostLimit }
        set { self.cache.totalCostLimit = newValue }
    }
    
    var countLimit: Int {
        get { return self.cache.countLimit }
        set { self.cache.countLimit = newValue }
    }
    
    var evictsObjectsWithDiscardedContent: Bool {
        get { return self.cache.evictsObjectsWithDiscardedContent }
        set { self.cache.evictsObjectsWithDiscardedContent = newValue }
    }
}
