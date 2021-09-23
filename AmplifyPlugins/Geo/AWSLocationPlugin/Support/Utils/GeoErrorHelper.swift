//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class GeoErrorHelper {
    static func getDefaultError(_ error: NSError) -> GeoError {
        let errorMessage = """
        Domain: [\(error.domain)
        Code: [\(error.code)
        LocalizedDescription: [\(error.localizedDescription)
        LocalizedFailureReason: [\(error.localizedFailureReason ?? "")
        LocalizedRecoverySuggestion: [\(error.localizedRecoverySuggestion ?? "")
        """

        return GeoError.unknown(errorMessage, "See underlying error.", error)
    }
}
