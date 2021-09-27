//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

typealias GeoPluginErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct GeoPluginErrorConstant {
    static let decodeConfigurationError: GeoPluginErrorString = (
        "Unable to decode configuration.",
        "Make sure the plugin configuration is JSONValue."
    )

    static let configurationObjectExpected: GeoPluginErrorString = (
        "Configuration was not a dictionary literal.",
        "Make sure the value for the plugin is a dictionary literal with keys."
    )

    static let missingRegion: GeoPluginErrorString = (
        "Region is missing",
        "Add region to the configuration"
    )

    static let invalidRegion: GeoPluginErrorString = (
        "Region is invalid",
        "Ensure Region is a valid region value"
    )

    static let emptyRegion: GeoPluginErrorString = (
        "Region is empty",
        "Ensure should not be empty"
    )

// MARK: - Maps
    static let mapsConfigurationExpected: GeoPluginErrorString = (
        "Configuration at `maps` is not a dictionary literal",
        "Make sure the value for the `maps` is a dictionary literal with `items` and `default`"
    )
    
    static let missingMapConfiguration: GeoPluginErrorString = (
        "Maps configuration is missing from amplifyconfiguration.json.",
        "Make amplifyconfiguration.json includes `maps` section."
    )

    static let missingDefaultMap: GeoPluginErrorString = (
        "Default map is missing.",
        "Add default map to the configuration."
    )

    static let invalidDefaultMap: GeoPluginErrorString = (
        "Default map is missing from of map items.",
        "Ensure default map in included in map items."
    )

    static let emptyDefaultMap: GeoPluginErrorString = (
        "Default map is specified but is empty.",
        "Default map should not be empty."
    )

// MARK: - Search
    static let missingSearchConfiguration: GeoPluginErrorString = (
        "Search configuration is missing from amplifyconfiguration.json.",
        "Make amplifyconfiguration.json includes `searchIndices` section."
    )
    
    static let searchConfigurationExpected: GeoPluginErrorString = (
        "Configuration at `searchIndices` is not a dictionary literal.",
        "Make sure the value for the `searchIndices` is a dictionary literal with `items` and `default`"
    )

    static let missingDefaultSearchIndex: GeoPluginErrorString = (
        "Default search index is missing.",
        "Add default search index to the configuration."
    )

    static let invalidDefaultSearchIndex: GeoPluginErrorString = (
        "Default search index is missing from of search indices items.",
        "Ensure default search index in included in search indices items."
    )

    static let emptyDefaultSearchIndex: GeoPluginErrorString = (
        "Default search index is specified but is empty.",
        "Default search index should not be empty."
    )
}
