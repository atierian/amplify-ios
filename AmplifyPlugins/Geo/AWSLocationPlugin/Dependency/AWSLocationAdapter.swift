//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCore
import AWSLocation
import AWSPluginsCore
import Foundation

/// Conforms to AWSLocationBehavior which uses an instance of the AWSLocation to perform its methods.
///
/// This class acts as a wrapper to expose AWSLocation functionality through an instance over a singleton,
/// and allows for mocking in unit tests. The methods contain no other logic other than calling the
/// same method using the AWSLocation instance.
class AWSLocationAdapter: AWSLocationBehavior {

    /// Underlying AWSLocation service client instance.
    let location: AWSLocation

    /// Initializer
    /// - Parameter location: AWSLocation instance to use.
    init(location: AWSLocation) {
        self.location = location
    }

    /// Provides access to the underlying AWSLocation service client.
    /// - Returns: AWSLocation service client instance.
    func getEscapeHatch() -> AWSLocation {
        location
    }

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
                                                         Error?) -> Void)?) {
        location.searchPlaceIndex(forText: forText, completionHandler: completionHandler)
    }

    /// Reverse geocodes a given coordinate and returns a legible address. Allows you to
    /// search for Places or points of interest near a given position.
    /// - Parameters:
    ///   - forPosition: A container for the necessary parameters to execute the
    ///   SearchPlaceIndexForPosition service method.
    ///   - completionHandler: The completion handler to call when the search request is
    ///   complete.
    func searchPlaceIndex(forPosition: AWSLocationSearchPlaceIndexForPositionRequest,
                          completionHandler: ((AWSLocationSearchPlaceIndexForPositionResponse?,
                                                         Error?) -> Void)?) {
        location.searchPlaceIndex(forPosition: forPosition, completionHandler: completionHandler)
    }
}
