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
    let maps: [String: String]
    let defaultSearchIndex: String?
    let searchIndices: [String]

    init(_ configJSON: JSONValue) throws {
        let configObject = try AWSLocationGeoPluginConfiguration.getConfigObject(section: "awsLocationGeoPlugin",
                                                                              configJSON: configJSON)
        let region = try AWSLocationGeoPluginConfiguration.getRegion(configObject)

        var defaultMap: String?
        var maps = [String: String]()
        if let mapsConfigJSON = configObject["maps"] {
            let mapsConfigObject = try AWSLocationGeoPluginConfiguration.getConfigObject(section: "maps",
                                                                                      configJSON: mapsConfigJSON)
            defaultMap = try AWSLocationGeoPluginConfiguration.getDefault(item: "map",
                                                                       configObject: mapsConfigObject)
            maps = try AWSLocationGeoPluginConfiguration.getMaps(mapsConfigObject)
        }

        var defaultSearchIndex: String?
        var searchIndices = [String]()
        if let searchConfigJSON = configObject["searchIndices"] {
            let searchConfigObject = try AWSLocationGeoPluginConfiguration.getConfigObject(section: "searchIndices",
                                                                                        configJSON: searchConfigJSON)
            defaultSearchIndex = try AWSLocationGeoPluginConfiguration.getDefault(item: "search index",
                                                                               configObject: searchConfigObject)
            searchIndices = try AWSLocationGeoPluginConfiguration.getSearchIndices(searchConfigObject)
        }

        self.init(region: region,
                  defaultMap: defaultMap,
                  maps: maps,
                  defaultSearchIndex: defaultSearchIndex,
                  searchIndices: searchIndices)
    }

    init(region: AWSRegionType,
         defaultMap: String?,
         maps: [String: String],
         defaultSearchIndex: String?,
         searchIndices: [String]) {
        self.region = region
        self.defaultMap = defaultMap
        self.maps = maps
        self.defaultSearchIndex = defaultSearchIndex
        self.searchIndices = searchIndices
    }

    // MARK: - Private helper methods

    private static func getRegion(_ configObject: [String: JSONValue]) throws -> AWSRegionType {
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

        return regionType
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

    // MARK: - Maps
    private static func getMaps(_ mapConfig: [String: JSONValue]) throws -> [String: String] {
        // TODO: Implement this function
        return ["mapname": "style"]
    }

    // MARK: - Search
    private static func getSearchIndices(_ searchConfig: [String: JSONValue]) throws -> [String] {
        // TODO: Implement this function
        return ["searchIndex"]
    }
}
