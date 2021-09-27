//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSLocation

public struct AWSLocationGeoPluginConfiguration {

    let region: AWSRegionType
    let defaultMap: String?
    let maps: [String: Geo.MapStyle]
    let defaultSearchIndex: String?
    let searchIndices: [String]

    init(_ configJSON: JSONValue) throws {
        let configObject = try AWSLocationGeoPluginConfiguration.getConfigObject(section: "awsLocationGeoPlugin",
                                                                              configJSON: configJSON)
        let regionInfo = try AWSLocationGeoPluginConfiguration.getRegion(configObject)

        let region = regionInfo.type
        let regionName = regionInfo.name
        
        var maps = [String: Geo.MapStyle]()
        var defaultMap: String?
        if let mapsConfigJSON = configObject["maps"] {
            let mapsConfigObject = try AWSLocationGeoPluginConfiguration.getConfigObject(section: "maps",
                                                                                      configJSON: mapsConfigJSON)
            maps = try AWSLocationGeoPluginConfiguration.getMaps(mapConfig: mapsConfigObject, regionName: regionName)
            defaultMap = try AWSLocationGeoPluginConfiguration.getDefault(item: "map",
                                                                       configObject: mapsConfigObject)
            guard let map = defaultMap, maps[map] != nil else {
                throw PluginError.pluginConfigurationError(
                    GeoPluginErrorConstant.invalidDefaultMap.errorDescription,
                    GeoPluginErrorConstant.invalidDefaultMap.recoverySuggestion
                )
            }
        }

        var searchIndices = [String]()
        var defaultSearchIndex: String?
        if let searchConfigJSON = configObject["searchIndices"] {
            let searchConfigObject = try AWSLocationGeoPluginConfiguration.getConfigObject(section: "searchIndices",
                                                                                        configJSON: searchConfigJSON)
            searchIndices = try AWSLocationGeoPluginConfiguration.getItemsStrings(section: "searchIndices",
                                                                                  configObject: searchConfigObject)
            defaultSearchIndex = try AWSLocationGeoPluginConfiguration.getDefault(item: "search index",
                                                                               configObject: searchConfigObject)
            
            guard let index = defaultSearchIndex, searchIndices.contains(index) else {
                throw PluginError.pluginConfigurationError(
                    GeoPluginErrorConstant.invalidDefaultSearchIndex.errorDescription,
                    GeoPluginErrorConstant.invalidDefaultSearchIndex.recoverySuggestion
                )
            }
        }

        self.init(region: region,
                  defaultMap: defaultMap,
                  maps: maps,
                  defaultSearchIndex: defaultSearchIndex,
                  searchIndices: searchIndices)
    }

    init(region: AWSRegionType,
         defaultMap: String?,
         maps: [String: Geo.MapStyle],
         defaultSearchIndex: String?,
         searchIndices: [String]) {
        self.region = region
        self.defaultMap = defaultMap
        self.maps = maps
        self.defaultSearchIndex = defaultSearchIndex
        self.searchIndices = searchIndices
    }

    // MARK: - Private helper methods

    private static func getRegion(_ configObject: [String: JSONValue]) throws -> (name: String, type: AWSRegionType) {
        guard let regionJSON = configObject["region"] else {
            throw PluginError.pluginConfigurationError(
                GeoPluginErrorConstant.missingRegion.errorDescription,
                GeoPluginErrorConstant.missingRegion.recoverySuggestion
            )
        }

        guard case let .string(region) = regionJSON else {
            throw PluginError.pluginConfigurationError(
                GeoPluginErrorConstant.invalidRegion.errorDescription,
                GeoPluginErrorConstant.invalidRegion.recoverySuggestion
            )
        }

        if region.isEmpty {
            throw PluginError.pluginConfigurationError(
                GeoPluginErrorConstant.emptyRegion.errorDescription,
                GeoPluginErrorConstant.emptyRegion.recoverySuggestion
            )
        }

        let regionType = region.aws_regionTypeValue()
        guard regionType != AWSRegionType.Unknown else {
            throw PluginError.pluginConfigurationError(
                GeoPluginErrorConstant.invalidRegion.errorDescription,
                GeoPluginErrorConstant.invalidRegion.recoverySuggestion
            )
        }

        return (region, regionType)
    }

    private static func getDefault(item: String, configObject: [String: JSONValue]) throws -> String {
        guard let defaultJSON = configObject["default"] else {
            throw PluginError.pluginConfigurationError(
                "Default \(item) is missing.",
                "Add default \(item) to the configuration."
            )
        }

        guard case let .string(defaultItem) = defaultJSON else {
            throw PluginError.pluginConfigurationError(
                "Default \(item) is not a string.",
                "Ensure default \(item) is a string."
            )
        }

        if defaultItem.isEmpty {
            throw PluginError.pluginConfigurationError(
                "Default \(item) is specified but is empty.",
                "Default \(item) should not be empty."
            )
        }

        return defaultItem
    }

    private static func getConfigObject(section: String, configJSON: JSONValue) throws -> [String: JSONValue] {
        guard case let .object(configObject) = configJSON else {
            throw PluginError.pluginConfigurationError(
                "Configuration at `\(section)` is not a dictionary literal.",
                "Make sure the value for the `\(section)` is a dictionary literal."
            )
        }
        return configObject
    }
    
    private static func getItemsJSON(section: String, configObject: [String: JSONValue]) throws -> JSONValue {
        guard let itemsJSON = configObject["items"] else {
            throw PluginError.pluginConfigurationError(
                "Configuration for `\(section)` is missing `items`.",
                "Add `items` to the \(section) configuration."
            )
        }
        return itemsJSON
    }
    
    private static func getItemsObject(section: String, configObject: [String: JSONValue]) throws -> [String: JSONValue] {
        let itemsJSON = try getItemsJSON(section: section, configObject: configObject)
        guard case let .object(itemsObject) = itemsJSON else {
            throw PluginError.pluginConfigurationError(
                "Configuration at `\(section)`, `items` is not a dictionary literal.",
                "Make sure the value for `\(section)`, `items` is a dictionary literal."
            )
        }
        return itemsObject
    }
    
    private static func getItemsStrings(section: String, configObject: [String: JSONValue]) throws -> [String] {
        let itemsJSON = try getItemsJSON(section: section, configObject: configObject)
        guard case let .array(itemsArray) = itemsJSON else {
            throw PluginError.pluginConfigurationError(
                "Configuration at `\(section)`, `items` is not an array literal.",
                "Make sure the value for `\(section)`, `items` is an array literal."
            )
        }
        let itemStrings: [String] = try itemsArray.map { item in
            guard case let .string(itemString) = item else {
                throw PluginError.pluginConfigurationError(
                    "Configuration at `\(section)`, `items` is not a String array.",
                    "Make sure the value for `\(section)`, `items` is a String array."
                )
            }
            return itemString
        }
        return itemStrings
    }

    // MARK: - Maps
    private static func getMaps(mapConfig: [String: JSONValue], regionName: String) throws -> [String: Geo.MapStyle] {
        let section = "maps"
        let mapItemsObject = try getItemsObject(section: section, configObject: mapConfig)
        
        let mapTuples:[(String, Geo.MapStyle)] = try mapItemsObject.map { mapName, itemJSON in
            guard case let .string(style) = itemJSON else {
                throw PluginError.pluginConfigurationError(
                    "Configuration value at `\(section)`, `items`, `mapName` is not a string.",
                    "Ensure value value at `\(section)`, `items`, `mapName` is a string."
                )
            }
            
            let url = URL(string: "https://maps.geo.\(regionName).amazonaws.com/maps/v0/maps/\(mapName)/style-descriptor")
            guard let styleURL = url else {
                throw PluginError.pluginConfigurationError(
                    "Failed to create style URL for map \(mapName). This should not happen.",
                    "Check settings for map \(mapName)."
                )
            }

            let mapStyle = Geo.MapStyle.init(mapName: mapName, style: style, styleURL: styleURL)
            
            return (mapName, mapStyle)
        }
        let mapStyles = Dictionary(uniqueKeysWithValues: mapTuples)
        
        return mapStyles
    }
}
