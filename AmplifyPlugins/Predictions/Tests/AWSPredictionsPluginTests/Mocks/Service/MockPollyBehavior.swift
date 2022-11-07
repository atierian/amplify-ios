//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPolly
@testable import AWSPredictionsPlugin

class MockPollyBehavior: AWSPollyBehavior {

    var result: SynthesizeSpeechOutputResponse?
    var error: Error?

    func validate() throws {
        if let error = error { throw error }
    }

    func synthesizeSpeech(
        request: SynthesizeSpeechInput
    ) async throws -> SynthesizeSpeechOutputResponse {
        try validate()
        return result!
    }

    func getPolly() -> PollyClient {
        return try! .init(region: "us-east-1")
    }

    public func setResult(result: SynthesizeSpeechOutputResponse) {
        self.result = result
        error = nil
    }

    public func setError(error: Error) {
        result = nil
        self.error = error
    }
}
