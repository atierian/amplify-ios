//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
//import AWSCore
import AWSTextract
@testable import AWSPredictionsPlugin

class MockTextractBehavior: AWSTextractBehavior {

    var analyzeDocument: AnalyzeDocumentOutputResponse?
    var detectDocumentText: DetectDocumentTextOutputResponse?
    var error: Error?

    func validate() throws {
        if let error = error { throw error }
    }

    func analyzeDocument(
        request: AnalyzeDocumentInput
    ) async throws -> AnalyzeDocumentOutputResponse {
        try validate()
        if let analyzeDocument = analyzeDocument { return analyzeDocument }
        throw NSError(domain: "", code: 42)
    }

    func detectDocumentText(
        request: DetectDocumentTextInput
    ) async throws -> DetectDocumentTextOutputResponse {
        try validate()
        if let detectDocumentText = detectDocumentText { return detectDocumentText }
        throw NSError(domain: "", code: 42)
    }

    func getTextract() -> TextractClient {
        try! .init(region: "us-east-1")
    }

    public func setAnalyzeDocument(result: AnalyzeDocumentOutputResponse?) {
        analyzeDocument = result
        error = nil
    }

    public func setDetectDocumentText(result: DetectDocumentTextOutputResponse?) {
        detectDocumentText = result
        error = nil
    }

    public func setError(error: Error) {
        analyzeDocument = nil
        detectDocumentText = nil
        self.error = error
    }
}
