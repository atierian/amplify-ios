//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSComprehend
@testable import AWSPredictionsPlugin

class MockComprehendBehavior: AWSComprehendBehavior {
    var sentimentResponse: AWSComprehend.DetectSentimentOutputResponse?
    var entitiesResponse: AWSComprehend.DetectEntitiesOutputResponse?
    var languageResponse: AWSComprehend.DetectDominantLanguageOutputResponse?
    var syntaxResponse: AWSComprehend.DetectSyntaxOutputResponse?
    var keyPhrasesResponse: AWSComprehend.DetectKeyPhrasesOutputResponse?
    var error: Error?

    func validate() throws {
        if let error = error { throw error }
    }

    func detectSentiment(request: AWSComprehend.DetectSentimentInput) async throws -> AWSComprehend.DetectSentimentOutputResponse {
        try validate()
        return sentimentResponse!
    }

    func detectEntities(request: AWSComprehend.DetectEntitiesInput) async throws -> AWSComprehend.DetectEntitiesOutputResponse {
        try validate()
        return entitiesResponse!
    }

    func detectLanguage(request: AWSComprehend.DetectDominantLanguageInput) async throws -> AWSComprehend.DetectDominantLanguageOutputResponse {
        try validate()
        return languageResponse!
    }

    func detectSyntax(request: AWSComprehend.DetectSyntaxInput) async throws -> AWSComprehend.DetectSyntaxOutputResponse {
        try validate()
        return syntaxResponse!
    }

    func detectKeyPhrases(request: AWSComprehend.DetectKeyPhrasesInput) async throws -> AWSComprehend.DetectKeyPhrasesOutputResponse {
        try validate()
        return keyPhrasesResponse!
    }

    func getComprehend() -> AWSComprehend.ComprehendClient {
        return try! .init(region: "us-east-1")
    }


    public func setResult(
        sentimentResponse: AWSComprehend.DetectSentimentOutputResponse? = nil,
        entitiesResponse: AWSComprehend.DetectEntitiesOutputResponse? = nil,
        languageResponse: AWSComprehend.DetectDominantLanguageOutputResponse? = nil,
        syntaxResponse: AWSComprehend.DetectSyntaxOutputResponse? = nil,
        keyPhrasesResponse: AWSComprehend.DetectKeyPhrasesOutputResponse? = nil
    ) {
        self.sentimentResponse = sentimentResponse
        self.entitiesResponse = entitiesResponse
        self.languageResponse = languageResponse
        self.syntaxResponse = syntaxResponse
        self.keyPhrasesResponse = keyPhrasesResponse
        error = nil
    }

    public func setError(error: Error) {
        sentimentResponse = nil
        entitiesResponse = nil
        languageResponse = nil
        syntaxResponse = nil
        keyPhrasesResponse = nil
        self.error = error
    }

}
