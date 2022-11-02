//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTranslate
import Foundation
@testable import AWSPredictionsPlugin

class MockTranslateBehavior: AWSTranslateBehavior {

    var result: TranslateTextOutputResponse?
    var error: Error?

    func translateText(
        request: TranslateTextInput
    ) async throws -> TranslateTextOutputResponse {
        if let error = error { throw error }
        if let result = result { return result }
        throw NSError(domain: "", code: 42)
    }

    func getTranslate() -> TranslateClient {
        try! .init(region: "us-east-1")
    }

    public func setResult(result: TranslateTextOutputResponse?) {
        self.result = result
        error = nil
    }

    public func setError(error: Error) {
        result = nil
        self.error = error
    }
}
