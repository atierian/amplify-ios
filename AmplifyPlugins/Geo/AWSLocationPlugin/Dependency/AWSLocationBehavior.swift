//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSLocation

/// Behavior that `AWSLocationAdapter` will use.
/// This protocol allows a way to create a Mock and ensure the plugin implementation is testable.
protocol AWSLocationBehavior {

    // Get the lower level `AWSLocation` client.
    func getEscapeHatch() -> AWSLocation

    /// Geocodes free-form text, such as an address, name, city, or region to allow you
    /// to search for Places or points of interest. Includes the option to apply
    /// additional parameters to narrow your list of results.
    ///
    /// You can search for places near a given position using BiasPosition, or filter
    /// results within a bounding box using FilterBBox. Providing both parameters
    /// simultaneously returns an error.
    /// - Parameters:
    ///   - forText: A container for the necessary parameters to execute the
    ///   SearchPlaceIndexForText service method.
    ///   - completionHandler: The completion handler to call when the search request is
    ///   complete.
    func searchPlaceIndex(forText: AWSLocationSearchPlaceIndexForTextRequest,
                          completionHandler: ((AWSLocationSearchPlaceIndexForTextResponse?,
                                               Error?) -> Void)?)

    /// Reverse geocodes a given coordinate and returns a legible address. Allows you to
    /// search for Places or points of interest near a given position.
    /// - Parameters:
    ///   - forPosition: A container for the necessary parameters to execute the
    ///   SearchPlaceIndexForPosition service method.
    ///   - completionHandler: The completion handler to call when the search request is
    ///   complete.
    func searchPlaceIndex(forPosition: AWSLocationSearchPlaceIndexForPositionRequest,
                          completionHandler: ((AWSLocationSearchPlaceIndexForPositionResponse?,
                                               Error?) -> Void)?)
}
