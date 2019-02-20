//
//  PersistenceServiceUtils.swift
//
/*
 * *********************************************************************************************************************
 *
 *  BACKENDLESS.COM CONFIDENTIAL
 *
 *  ********************************************************************************************************************
 *
 *  Copyright 2019 BACKENDLESS.COM. All Rights Reserved.
 *
 *  NOTICE: All information contained herein is, and remains the property of Backendless.com and its suppliers,
 *  if any. The intellectual and technical concepts contained herein are proprietary to Backendless.com and its
 *  suppliers and may be covered by U.S. and Foreign Patents, patents in process, and are protected by trade secret
 *  or copyright law. Dissemination of this information or reproduction of this material is strictly forbidden
 *  unless prior written permission is obtained from Backendless.com.
 *
 *  ********************************************************************************************************************
 */

class PersistenceServiceUtils: NSObject {
    
    private var tableName: String = ""
    
    private let processResponse = ProcessResponse.shared
    private let mappings = Mappings.shared
    private let storedObjects = StoredObjects.shared
    
    func setup(tableName: String?) {
        if let tableName = tableName {
            if tableName == "BackendlessUser" {
                self.tableName = "Users"
            }
            else {
                self.tableName = tableName
            }
        }
    }
    
    func describe(tableName: String, responseHandler: (([ObjectProperty]) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        BackendlessRequestManager(restMethod: "data/\(tableName)/properties", httpMethod: .GET, headers: nil, parameters: nil).makeRequest(getResponse: { response in
            if let result = self.processResponse.adapt(response: response, to: [ObjectProperty].self) {
                if result is Fault {
                    errorHandler(result as! Fault)
                }
                else {
                    responseHandler(result as! [ObjectProperty])
                }
            }
        })
    }
    
    func save(entity: [String : Any], responseHandler: (([String : Any]) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        let headers = ["Content-Type": "application/json"]
        let parameters = entity
        BackendlessRequestManager(restMethod: "data/\(tableName)", httpMethod: .POST, headers: headers, parameters: parameters).makeRequest(getResponse: { response in
            if let result = self.processResponse.adapt(response: response, to: JSON.self) {
                if result is Fault {
                    errorHandler(result as! Fault)
                }
                else {
                    responseHandler((result as! JSON).dictionaryObject!)
                }
            }
        })
    }
    
    func createBulk(entities: [[String: Any]], responseHandler: (([String]) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        let headers = ["Content-Type": "application/json"]
        let parameters = entities
        BackendlessRequestManager(restMethod: "data/bulk/\(tableName)", httpMethod: .POST, headers: headers, parameters: parameters).makeRequest(getResponse: { response in
            if let result = self.processResponse.adapt(response: response, to: [String].self) {
                if result is Fault {
                    errorHandler(result as! Fault)
                }
                else {
                    responseHandler(result as! [String])
                }
            }
        })
    }
    
    func update(entity: [String : Any], responseHandler: (([String : Any]) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        let headers = ["Content-Type": "application/json"]
        let parameters = entity
        if let objectId = entity["objectId"] as? String {
            BackendlessRequestManager(restMethod: "data/\(tableName)/\(objectId)", httpMethod: .PUT, headers: headers, parameters: parameters).makeRequest(getResponse: { response in
                if let result = self.processResponse.adapt(response: response, to: JSON.self) {
                    if result is Fault {
                        errorHandler(result as! Fault)
                    }
                    else {
                        responseHandler((result as! JSON).dictionaryObject!)
                    }
                }
            })
        }        
    }
    
    func updateBulk(whereClause: String?, changes: [String : Any], responseHandler: ((NSNumber) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        let headers = ["Content-Type": "application/json"]
        let parameters = changes
        var restMethod = "data/bulk/\(tableName)"
        if whereClause != nil, whereClause?.count ?? 0 > 0 {
            restMethod += "?where=\(stringToUrlString(originalString: whereClause!))"
        }
        BackendlessRequestManager(restMethod: restMethod, httpMethod: .PUT, headers: headers, parameters: parameters).makeRequest(getResponse: { response in
            if let result = self.processResponse.adapt(response: response, to: Int.self) {
                if result is Fault {
                    errorHandler(result as! Fault)
                }
            }
            else {
                responseHandler(self.dataToNSNumber(data: response.data!))
            }
        })
    }
    
    func removeById(objectId: String, responseHandler: ((NSNumber) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        let headers = [String: String]()
        BackendlessRequestManager(restMethod: "data/\(tableName)/\(objectId)", httpMethod: .DELETE, headers: headers, parameters: nil).makeRequest(getResponse: { response in
            if let result = self.processResponse.adapt(response: response, to: JSON.self) {
                if result is Fault {
                    errorHandler(result as! Fault)
                }
                else if let resultValue = (result as! JSON).dictionaryObject?.first?.value as? Int {
                    self.storedObjects.removeObjectId(objectId: objectId)
                    responseHandler(NSNumber(value: resultValue))
                }
            }
        })
    }
    
    func removeBulk(whereClause: String?, responseHandler: ((NSNumber) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        let headers = ["Content-Type": "application/json"]
        var parameters = ["where": whereClause]
        if whereClause == nil {
            parameters = ["where": "objectId != NULL"]
        }        
        BackendlessRequestManager(restMethod: "data/bulk/\(tableName)/delete", httpMethod: .POST, headers: headers, parameters: parameters).makeRequest(getResponse: { response in
            if let result = self.processResponse.adapt(response: response, to: Int.self) {
                if result is Fault {
                    errorHandler(result as! Fault)
                }
            }
            else {
                self.storedObjects.removeObjectIds(tableName: self.tableName)
                responseHandler(self.dataToNSNumber(data: response.data!))
            }
        })
    }
    
    func getObjectCount(queryBuilder: DataQueryBuilder?, responseHandler: ((NSNumber) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        var restMethod = "data/\(tableName)/count"
        if let whereClause = queryBuilder?.getWhereClause(), whereClause.count > 0 {
            restMethod += "?where=\(stringToUrlString(originalString: whereClause))"
        }
        BackendlessRequestManager(restMethod: restMethod, httpMethod: .GET, headers: nil, parameters: nil).makeRequest(getResponse: { response in
            if let result = self.processResponse.adapt(response: response, to: Int.self) {
                if result is Fault {
                    errorHandler(result as! Fault)
                }
            }
            else {
                self.storedObjects.removeObjectIds(tableName: self.tableName)
                responseHandler(self.dataToNSNumber(data: response.data!))
            }
        })
    }
    
    func find(queryBuilder: DataQueryBuilder?, responseHandler: (([[String : Any]]) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        let headers = ["Content-Type": "application/json"]
        var parameters = [String: Any]()
        if let whereClause = queryBuilder?.getWhereClause() {
            parameters["where"] = whereClause
        }
        if let relationsDepth = queryBuilder?.getRelationsDepth() {
            parameters["relationsDepth"] = String(relationsDepth)
        }
        if let sortBy = queryBuilder?.getSortBy(), sortBy.count > 0 {
            parameters["sortBy"] = arrayToString(array: sortBy)
        }
        if let related = queryBuilder?.getRelated() {
            parameters["loadRelations"] = arrayToString(array: related)
        }
        if let groupBy = queryBuilder?.getGroupBy() {
            parameters["groupBy"] = arrayToString(array: groupBy)
        }
        if let havingClause = queryBuilder?.getHavingClause() {
            parameters["having"] = havingClause
        }
        if let pageSize = queryBuilder?.getPageSize() {
            parameters["pageSize"] = pageSize
        }
        if let offset = queryBuilder?.getOffset() {
            parameters["offset"] = offset
        }
        BackendlessRequestManager(restMethod: "data/\(tableName)/find", httpMethod: .POST, headers: headers, parameters: parameters).makeRequest(getResponse: { response in
            if let result = self.processResponse.adapt(response: response, to: [JSON].self) {
                if result is Fault {
                    errorHandler(result as! Fault)
                }
                else {
                    var resultArray = [[String: Any]]()
                    for resultObject in result as! [JSON] {
                        if let resultDictionary = resultObject.dictionaryObject {
                            resultArray.append(resultDictionary)
                        }
                    }
                    responseHandler(resultArray)
                }
            }
        })
    }
    
    func findFirstOrLastOrById(first: Bool, last: Bool, objectId: String?, queryBuilder: DataQueryBuilder?, responseHandler: (([String : Any]) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        var restMethod = "data/\(tableName)"
        if first {
            restMethod += "/first"
        }
        else if last {
            restMethod += "/last"
        }
        else if let objectId = objectId {
            restMethod += "/\(objectId)"
        }
        
        let related = queryBuilder?.getRelated()
        let relationsDepth = queryBuilder?.getRelationsDepth()
        
        if related != nil, relationsDepth! > 0 {
            let relatedString = stringToUrlString(originalString: arrayToString(array: related!))
            restMethod += "?loadRelations=" + relatedString + "&relationsDepth=" + String(relationsDepth!)
        }
        else if related != nil, relationsDepth == 0 {
            let relatedString = stringToUrlString(originalString: arrayToString(array: related!))
            restMethod += "?loadRelations=" + relatedString
        }
        else if related == nil, relationsDepth! > 0 {
            restMethod += "?relationsDepth=" + String(relationsDepth!)
        }
        BackendlessRequestManager(restMethod: restMethod, httpMethod: .GET, headers: nil, parameters: nil).makeRequest(getResponse: { response in
            if let result = self.processResponse.adapt(response: response, to: JSON.self) {
                if result is Fault {
                    errorHandler(result as! Fault)
                }
                else {
                    responseHandler((result as! JSON).dictionaryObject!)
                }
            }
        })
    }
    
    func setOrAddRelation(columnName: String, parentObjectId: String, childrenObjectIds: [String], httpMethod: HTTPMethod, responseHandler: ((NSNumber) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        let headers = ["Content-Type": "application/json"]
        let parameters = childrenObjectIds
        BackendlessRequestManager(restMethod: "data/\(tableName)/\(parentObjectId)/\(columnName)", httpMethod: httpMethod, headers: headers, parameters: parameters).makeRequest(getResponse: { response in
            if let result = self.processResponse.adapt(response: response, to: Int.self) {
                if result is Fault {
                    errorHandler(result as! Fault)
                }
            }
            else {
                self.storedObjects.removeObjectIds(tableName: self.tableName)
                responseHandler(self.dataToNSNumber(data: response.data!))
            }
        })
    }
    
    func setOrAddRelation(columnName: String, parentObjectId: String, whereClause: String?, httpMethod: HTTPMethod, responseHandler: ((NSNumber) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        var restMethod = "data/\(tableName)/\(parentObjectId)/\(columnName)"
        if whereClause != nil, whereClause?.count ?? 0 > 0 {
            restMethod += "?whereClause=\(stringToUrlString(originalString: whereClause!))"
        }
        else {
            restMethod += "?whereClause=\(stringToUrlString(originalString: "objectId != NULL"))"
        }
        BackendlessRequestManager(restMethod: restMethod, httpMethod: httpMethod, headers: nil, parameters: nil).makeRequest(getResponse: { response in
            if let result = self.processResponse.adapt(response: response, to: Int.self) {
                if result is Fault {
                    errorHandler(result as! Fault)
                }
            }
            else {
                self.storedObjects.removeObjectIds(tableName: self.tableName)
                responseHandler(self.dataToNSNumber(data: response.data!))
            }
        })
    }
    
    func deleteRelation(columnName: String, parentObjectId: String, childrenObjectIds: [String], responseHandler: ((NSNumber) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        let headers = ["Content-Type": "application/json"]
        let parameters = childrenObjectIds
        BackendlessRequestManager(restMethod: "data/\(tableName)/\(parentObjectId)/\(columnName)", httpMethod: .DELETE, headers: headers, parameters: parameters).makeRequest(getResponse: { response in
            if let result = self.processResponse.adapt(response: response, to: Int.self) {
                if result is Fault {
                    errorHandler(result as! Fault)
                }
            }
            else {
                self.storedObjects.removeObjectIds(tableName: self.tableName)
                responseHandler(self.dataToNSNumber(data: response.data!))
            }
        })
    }
    
    func deleteRelation(columnName: String, parentObjectId: String, whereClause: String?, responseHandler: ((NSNumber) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        var whereClause = whereClause
        if whereClause == nil {
            whereClause = "objectId != NULL"
        }
        BackendlessRequestManager(restMethod: "data/\(tableName)/\(parentObjectId)/\(columnName)?whereClause=\(stringToUrlString(originalString: whereClause!))", httpMethod: .DELETE, headers: nil, parameters: nil).makeRequest(getResponse: { response in
            if let result = self.processResponse.adapt(response: response, to: Int.self) {
                if result is Fault {
                    errorHandler(result as! Fault)
                }
            }
            else {
                self.storedObjects.removeObjectIds(tableName: self.tableName)
                responseHandler(self.dataToNSNumber(data: response.data!))
            }
        })
    }
    
    func loadRelations(objectId: String, queryBuilder: LoadRelationsQueryBuilder, responseHandler: (([[String : Any]]) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        var restMethod = "data/\(tableName)/\(objectId)"
        if let relationName = queryBuilder.getRelationName() {
            restMethod += "/\(relationName)"
            
            let pageSize = queryBuilder.getPageSize()
            let offset = queryBuilder.getOffset()
            
            if pageSize != 100, offset != 0 {
                restMethod += "?pageSize=\(pageSize)&offset=\(offset)"
            }
            else if pageSize == 100, offset != 0 {
                restMethod += "?offset=\(offset)"
            }
            else if pageSize != 100, offset == 0 {
                restMethod += "?pageSize=\(pageSize)"
            }
        }
        BackendlessRequestManager(restMethod: restMethod, httpMethod: .GET, headers: nil, parameters: nil).makeRequest(getResponse: { response in
            if let result = self.processResponse.adapt(response: response, to: [JSON].self) {
                if result is Fault {
                    errorHandler(result as! Fault)
                }
                else {
                    var resultArray = [[String: Any]]()
                    for resultObject in result as! [JSON] {
                        if let resultDictionary = resultObject.dictionaryObject {
                            resultArray.append(resultDictionary)
                        }
                    }
                    responseHandler(resultArray)
                }
            }
        })
    }
    
    // ******************** additional methods ********************
    
    func getTableName(entity: Any) -> String {
        var name = String(describing: entity)        
        if name == "BackendlessUser" {
            name = "Users"
        }
        return name
    }
    
    func getClassName(entity: Any) -> String {
        var name = String(describing: entity)
        if name == "Users" {
            name = "BackendessUser"
        }
        if Bundle.main.infoDictionary![kCFBundleNameKey as String] == nil {
            // for unit tests
            let testBundle = Bundle(for: TestClass.self)
            return testBundle.infoDictionary![kCFBundleNameKey as String] as! String + "." + name
        }
        return Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String + "." + name
    }
    
    func getClassName(className: String) -> String? {
        var name = className
        if name == "Users" {
            name = "BackendlessUser"
        }
        if Bundle.main.infoDictionary![kCFBundleNameKey as String] == nil {
            // for unit tests
            let testBundle = Bundle(for: TestClass.self)
            return testBundle.infoDictionary![kCFBundleNameKey as String] as! String + "." + name
        }
        return Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String + "." + name
    }
    
    func getClassProperties(entity: Any) -> [String] {
        let resultClass = type(of: entity) as! NSObject.Type
        var classProperties = [String]()
        var outCount : UInt32 = 0
        if let properties = class_copyPropertyList(resultClass.self, &outCount) {
            for i : UInt32 in 0..<outCount {
                if let key = NSString(cString: property_getName(properties[Int(i)]), encoding: String.Encoding.utf8.rawValue) as String? {
                    classProperties.append(key)
                }
            }
        }
        return classProperties
    }
    
    func entityToDictionary(entity: Any) -> [String: Any] {
        let resultClass = type(of: entity) as! NSObject.Type
        var entityDictionary = [String: Any]()
        var outCount : UInt32 = 0
        if let properties = class_copyPropertyList(resultClass.self, &outCount) {
            
            let entityClassName = getClassName(entity: (entity as! NSObject).classForCoder)
            let columnToPropertyMappings = mappings.getColumnToPropertyMappings(className: entityClassName)
            
            for i : UInt32 in 0..<outCount {
                if let key = NSString(cString: property_getName(properties[Int(i)]), encoding: String.Encoding.utf8.rawValue) as String?, let value = (entity as! NSObject).value(forKey: key) {
                    if let mappedKey = columnToPropertyMappings.getKey(forValue: key) {
                        entityDictionary[mappedKey] = value
                    }
                    else {
                        entityDictionary[key] = value
                    }
                    if let objectId = storedObjects.getObjectId(forObject: entity as! AnyHashable) {
                        entityDictionary["objectId"] = objectId
                    }
                }
            }
        }
        return entityDictionary
    }
    
    func dictionaryToEntity(dictionary: [String: Any], className: String) -> Any? {
        if tableName == "Users" {
            return processResponse.adaptToBackendlessUser(responseResult: dictionary)
        }
        var resultEntityTypeName = ""
        let classMappings = mappings.getTableToClassMappings()
        if classMappings.keys.contains(tableName) {
            resultEntityTypeName = classMappings[tableName]!
        }
        else {
            resultEntityTypeName = className
        }
        var resultEntityType = NSClassFromString(resultEntityTypeName) as? NSObject.Type
        if resultEntityType == nil {
            let nameArray = resultEntityTypeName.components(separatedBy: ".")
            resultEntityTypeName = nameArray.last!       
            resultEntityType = NSClassFromString(resultEntityTypeName) as? NSObject.Type
        }
        if let resultEntityType = resultEntityType {
            let entity = resultEntityType.init()
            let entityFields = getClassProperties(entity: entity)
            
            let entityClassName = getClassName(entity: entity.classForCoder)
            let columnToPropertyMappings = mappings.getColumnToPropertyMappings(className: entityClassName)
            for dictionaryField in dictionary.keys {
                
                if !(dictionary[dictionaryField] is NSNull) {
                    if columnToPropertyMappings.keys.contains(dictionaryField) {
                        entity.setValue(dictionary[dictionaryField], forKey: columnToPropertyMappings[dictionaryField]!)
                    }
                    else if entityFields.contains(dictionaryField) {
                        
                        if let relationDictionary = dictionary[dictionaryField] as? [String: Any] {
                            if let relationClassName = getClassName(className: relationDictionary["___class"] as! String) {
                                if relationDictionary["___class"] as? String == "Users",
                                    let userObject = processResponse.adaptToBackendlessUser(responseResult: relationDictionary) {
                                    entity.setValue(userObject as! BackendlessUser, forKey: dictionaryField)
                                }
                                else if relationDictionary["___class"] as? String == "GeoPoint",
                                    let geoPointObject = processResponse.adaptToGeoPoint(geoDictionary: relationDictionary) {
                                    entity.setValue(geoPointObject, forKey: dictionaryField)
                                }
                                else if let relationObject = dictionaryToEntity(dictionary: relationDictionary, className: relationClassName) {
                                    entity.setValue(relationObject, forKey: dictionaryField)
                                }
                            }
                        }
                            
                        else if let relationArrayOfDictionaries = dictionary[dictionaryField] as? [[String: Any]] {
                            var relationsArray = [Any]()
                            for relationDictionary in relationArrayOfDictionaries {
                                if let relationClassName = getClassName(className: relationDictionary["___class"] as! String) {
                                    if relationDictionary["___class"] as? String == "Users",
                                        let userObject = processResponse.adaptToBackendlessUser(responseResult: relationDictionary) {
                                        relationsArray.append(userObject as! BackendlessUser)
                                    }
                                    if relationDictionary["___class"] as? String == "GeoPoint",
                                        let geoPointObject = processResponse.adaptToGeoPoint(geoDictionary: relationDictionary) {
                                        relationsArray.append(geoPointObject)
                                    }
                                    else if let relationObject = dictionaryToEntity(dictionary: relationDictionary, className: relationClassName) {
                                        relationsArray.append(relationObject)
                                    }
                                }
                                entity.setValue(relationsArray, forKey: dictionaryField)
                            }
                        }
                        else {
                            entity.setValue(dictionary[dictionaryField], forKey: dictionaryField)
                        }
                    }
                }
            }
            if let objectId = dictionary["objectId"] as? String {
                storedObjects.rememberObjectId(objectId: objectId, forObject: entity)
            }
            return entity
        }
        return nil
    }
    
    func getObjectId(entity: Any) -> String? {
        if let objectId = storedObjects.getObjectId(forObject: entity as! AnyHashable) {
            return objectId
        }
        return nil
    }
    
    private func dataToNSNumber(data: Data) -> NSNumber {
        if let stringValue = String(bytes: data, encoding: .utf8) {
            return (NSNumber(value: Int(stringValue)!))
        }
        return 0
    }
    
    private func stringToUrlString(originalString: String) -> String {
        if let resultString = originalString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
            return resultString
        }
        return originalString
    }
    
    private func arrayToString(array: [String]) -> String {
        var resultString = ""
        for i in 0..<array.count {
            resultString += array[i] + ","
        }
        if resultString.count >= 1 {
            resultString.removeLast(1)
        }
        return resultString
    }
}
