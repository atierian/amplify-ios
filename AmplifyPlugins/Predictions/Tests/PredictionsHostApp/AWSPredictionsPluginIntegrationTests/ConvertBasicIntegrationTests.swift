//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSPredictionsPlugin

class ConvertBasicIntegrationTests: AWSPredictionsPluginTestBase {

    // this test only tests online functionality.
    // offline functionality cannot be tested through an
    // integration test because speech recognition through
    // CoreML has to be run on device only.
    func testConvertSpeechToText() async throws {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "audio", withExtension: "wav") else {
            return XCTFail("")
        }

        let options = PredictionsSpeechToTextRequest.Options(
            defaultNetworkPolicy: .auto,
            language: .usEnglish,
            pluginOptions: nil
        )

        let result = try await Amplify.Predictions.convert(
            speechToText: url,
            options: options
        )

        XCTAssertNotNil(result, "Result should contain value")
    }
}
