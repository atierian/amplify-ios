//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import CoreMLPredictionsPlugin

class CoreMLPredictionsPluginTests: CoreMLPredictionsPluginTestBase {

    func testPluginInterpretText() async throws {
        let operation = try await coreMLPredictionsPlugin.interpret(
            text: "",
            options: nil
        )
        XCTAssertNotNil(operation, "Should return a valid operation")
        XCTAssertEqual(queue.size, 1)
    }

}
