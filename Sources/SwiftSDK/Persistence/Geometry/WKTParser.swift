//
//  WKTParser.swift
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

@objcMembers public class WKTParser: NSObject {
    
    public static let shared = WKTParser()
    
    private override init() { }
    
    public func fromWkt(_ wkt: String) -> BLGeometry? {
        if wkt.contains(BLPoint.wktType) {
            return getPoint(wkt: wkt)
        }
        else if wkt.contains(BLLineString.wktType) {
            return getLineString(wkt: wkt)
        }
        else if wkt.contains(BLPolygon.wktType) {
            return getPolygon(wkt: wkt)
        }
        return nil
    }
    
    private func getPoint(wkt: String) -> BLPoint? {
        let scanner = Scanner(string: wkt)
        scanner.caseSensitive = false
        if scanner.scanString(BLPoint.wktType, into: nil) && scanner.scanString("(", into: nil) {
            var x: Double = 0
            var y: Double = 0
            scanner.scanDouble(&x)
            scanner.scanDouble(&y)
            return BLPoint(x: x, y: y)
        }
        return nil
    }

    private func getLineString(wkt: String) -> BLLineString? {
        let scanner = Scanner(string: wkt)
        scanner.caseSensitive = false
        if scanner.scanString(BLLineString.wktType, into: nil) && scanner.scanString("(", into: nil) {
            var coordinatesString: NSString?
            scanner.scanUpTo(")", into: &coordinatesString)
            let lineString = BLLineString()
            if let pointsCoordinatesString = coordinatesString?.components(separatedBy: ", ") {
                for pointCoordinatesString in pointsCoordinatesString {
                    let pointsCoordinates = pointCoordinatesString.components(separatedBy: " ")
                    if let xString = pointsCoordinates.first, let x = Double(xString),
                        let yString = pointsCoordinates.last, let y = Double(yString) {
                        lineString.points.append(BLPoint(x: x, y: y))
                    }
                }
            }
            return lineString
        }
        return nil
    }
    
    private func getPolygon(wkt: String) -> BLPolygon? {
        let scanner = Scanner(string: wkt)
        scanner.caseSensitive = false
        if scanner.scanString(BLPolygon.wktType, into: nil) && scanner.scanString("((", into: nil) {
            var coordinatesString: NSString?
            scanner.scanUpTo("))", into: &coordinatesString)
            
            var boundary: BLLineString?
            var holes: BLLineString?
            
            if let lineStringsStr = coordinatesString?.components(separatedBy: "), ") {
                if var boundaryString = lineStringsStr.first {
                    let lineString = BLLineString()
                    boundaryString = boundaryString.replacingOccurrences(of: "(", with: "")
                    boundaryString = boundaryString.replacingOccurrences(of: ")", with: "")
                    let points = boundaryString.components(separatedBy: ", ")
                    for point in points {
                        let coords = point.components(separatedBy: " ")
                        if let xString = coords.first, let x = Double(xString),
                            let yString = coords.last, let y = Double(yString) {
                            lineString.points.append(BLPoint(x: x, y: y))
                        }
                    }
                    boundary = lineString
                }
                
                if lineStringsStr.count == 2 {
                    var holesString = lineStringsStr[1]
                    let lineString = BLLineString()
                    holesString = holesString.replacingOccurrences(of: "(", with: "")
                    holesString = holesString.replacingOccurrences(of: ")", with: "")
                    let points = holesString.components(separatedBy: ", ")
                    for point in points {
                        let coords = point.components(separatedBy: " ")
                        if let xString = coords.first, let x = Double(xString),
                            let yString = coords.last, let y = Double(yString) {
                            lineString.points.append(BLPoint(x: x, y: y))
                        }
                    }
                    holes = lineString
                }
            }
            if boundary != nil {
                return BLPolygon(boundary: boundary!, holes: holes)
            }
        }
        return nil
    }
    
    func asWkt(geometry: BLGeometry) -> String? {
        if geometry is BLPoint {
            let point = geometry as! BLPoint
            return "\(BLPoint.wktType) (\(point.x) \(point.y))"
        }
        else if geometry is BLLineString {
            let lineString = geometry as! BLLineString
            var wktString = "\(BLLineString.wktType) ("
            for point in lineString.points {
                wktString += "\(point.x) \(point.y), "
            }
            wktString.removeLast(2)
            wktString += ")"
            return wktString
        }
        else if geometry is BLPolygon {
            let polygon = geometry as! BLPolygon
            var wktString = "\(BLPolygon.wktType) ("
            
            if let boundary = polygon.boundary, boundary.points.count > 0 {
                wktString += "("
                for point in boundary.points {
                    wktString += "\(point.x) \(point.y), "
                }
                wktString.removeLast(2)
                wktString += ")"
            }
            if let holes = polygon.holes, holes.points.count > 0 {
                wktString += ", ("
                for point in holes.points {
                    wktString += "\(point.x) \(point.y), "
                }
                wktString.removeLast(2)
                wktString += ")"
            }
            wktString += ")"
            return wktString
        }
        return nil
    }
}
