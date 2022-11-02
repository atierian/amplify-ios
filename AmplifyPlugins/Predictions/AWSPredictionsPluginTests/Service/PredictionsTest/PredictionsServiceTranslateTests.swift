//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSTranslate
import Amplify
@testable import AWSPredictionsPlugin

class PredictionsServiceTranslateTests: XCTestCase {

    var predictionsService: AWSPredictionsService!
    let mockTranslate = MockTranslateBehavior()

    override func setUp() {
        let mockConfigurationJSON = """
        {
            "defaultRegion": "us_east_1"
        }
        """.data(using: .utf8)!
        do {
//            let clientDelegate = NativeWSTranscribeStreamingClientDelegate()
            let dispatchQueue = DispatchQueue(label: "TranscribeStreamingTests")
//            let nativeWebSocketProvider = NativeWebSocketProvider(clientDelegate: clientDelegate,
//                                                                  callbackQueue: dispatchQueue)
            let mockConfiguration = try JSONDecoder().decode(PredictionsPluginConfiguration.self,
                                                             from: mockConfigurationJSON)
            predictionsService = AWSPredictionsService(identifier: "",
                                                       awsTranslate: mockTranslate,
                                                       awsRekognition: MockRekognitionBehavior(),
                                                       awsTextract: MockTextractBehavior(),
                                                       awsComprehend: MockComprehendBehavior(),
                                                       awsPolly: MockPollyBehavior(),
//                                                       awsTranscribeStreaming: MockTranscribeBehavior(),
//                                                       nativeWebSocketProvider: nativeWebSocketProvider,
//                                                       transcribeClientDelegate: clientDelegate,
                                                       configuration: mockConfiguration)
        } catch {
            XCTFail("Initialization of the test failed")
        }
    }

    /// Test whether we can make a successful translate call
    ///
    /// - Given: Predictions service with translate behavior
    /// - When:
    ///    - I invoke translate api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testTranslateService() async throws {
        let mockResponse = TranslateTextOutputResponse(translatedText: "translated text here")
        mockTranslate.setResult(result: mockResponse)

        let result = try await predictionsService.translateText(
            text: "Hello there",
            language: .english,
            targetLanguage: .italian
        )
        XCTAssertEqual(
            result.text,
            mockResponse.translatedText,
            "Translated text should be same"
        )
    }

    /// Test whether error is correctly propogated
    ///
    /// - Given: Predictions service with translate behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testTranslateServiceWithError() async throws {
        let mockError = NSError()
        mockTranslate.setError(error: mockError)

        let errorReceived = expectation(description: "Error should be returned")

        do {
            let result = try await predictionsService.translateText(
                text: "",
                language: .english,
                targetLanguage: .italian
            )
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test if language from configuration is picked up
    ///
    /// - Given: Predictions service with translate behavior. And source, target lanugage
    /// is set in configuration
    /// - When:
    ///    - Invoke translate text
    /// - Then:
    ///    - I should get a successful result
    ///
    func testLanguageFromConfiguration() async throws {
        let mockConfigurationJSON = """
        {
            "defaultRegion": "us-east-1",
            "convert": {
                "translateText": {
                    "region": "us-east-1",
                    "sourceLang": "en",
                    "targetLang": "it"
                }
            }
        }
        """.data(using: .utf8)!
        do {
//            let clientDelegate = NativeWSTranscribeStreamingClientDelegate()
            let dispatchQueue = DispatchQueue(label: "TranscribeStreamingTests")
//            let nativeWebSocketProvider = NativeWebSocketProvider(clientDelegate: clientDelegate,
//                                                                  callbackQueue: dispatchQueue)
            let mockConfiguration = try JSONDecoder().decode(PredictionsPluginConfiguration.self,
                                                             from: mockConfigurationJSON)
            predictionsService = AWSPredictionsService(identifier: "",
                                                       awsTranslate: mockTranslate,
                                                       awsRekognition: MockRekognitionBehavior(),
                                                       awsTextract: MockTextractBehavior(),
                                                       awsComprehend: MockComprehendBehavior(),
                                                       awsPolly: MockPollyBehavior(),
//                                                       awsTranscribeStreaming: MockTranscribeBehavior(),
//                                                       nativeWebSocketProvider: nativeWebSocketProvider,
//                                                       transcribeClientDelegate: clientDelegate,
                                                       configuration: mockConfiguration)
        } catch {
            XCTFail("Initialization of the text failed. \(error)")
        }

        let mockResponse = TranslateTextOutputResponse(translatedText: "translated text here")
        mockTranslate.setResult(result: mockResponse)

        let result = try await predictionsService.translateText(
            text: "Hello there",
            language: nil,
            targetLanguage: nil
        )

        XCTAssertEqual(
            result.text,
            mockResponse.translatedText,
            "Translated text should be same"
        )
    }

    /// Test if the source language is nil error is thrown
    ///
    /// - Given: Predictions service with translate behavior
    /// - When:
    ///    - I invoke translate text with source language is nil
    /// - Then:
    ///    - I should get back an error
    ///
    func testNilSourceLanguageError() async throws {
        let mockResponse = TranslateTextOutputResponse(translatedText: "translated text here")
        mockTranslate.setResult(result: mockResponse)
        do {
            let result = try await predictionsService.translateText(
                text: "",
                language: nil,
                targetLanguage: .italian
            )

            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test if the target is nil and configuration is not set
    ///
    /// - Given: Predictions service with translate behavior
    /// - When:
    ///    - I invoke translate text with target language nil
    /// - Then:
    ///    - I should get back an error
    ///
    func testNilTargetLanguageError() async throws {
        let mockResponse = TranslateTextOutputResponse(translatedText: "translated text here")
        mockTranslate.setResult(result: mockResponse)

        do {
            let result = try await predictionsService.translateText(
                text: "",
                language: .english,
                targetLanguage: nil
            )

            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test if the service returns nil, we get an error back
    ///
    /// - Given: Predictions service with translate behavior
    /// - When:
    ///    - Invoke translate text and if service return nil result
    /// - Then:
    ///    - I should get an error back
    ///
    func testNilResult() async throws {
        mockTranslate.setResult(result: nil)

        do {
            let result = try await predictionsService.translateText(
                text: "",
                language: .english,
                targetLanguage: .spanish
            )
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test if the service returns nil for translated text, we get an error back
    ///
    /// - Given: Predictions service with translate behavior
    /// - When:
    ///    - Invoke translate text and if service return nil result
    /// - Then:
    ///    - I should get an error back
    ///
    func testNilTranslatedTextResult() async throws {
        let mockResponse = TranslateTextOutputResponse()
        mockTranslate.setResult(result: mockResponse)


        do {
            let result = try await predictionsService.translateText(
                text: "",
                language: .english,
                targetLanguage: .spanish
            )
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test if the target language is set
    ///
    /// - Given: Predictions service with translate behavior
    /// - When:
    ///    - Invoke translate text
    /// - Then:
    ///    - The target language should be set
    ///
    func testTargetLanguageTranslateService() async throws {
        let mockResponse = TranslateTextOutputResponse(translatedText: "translated text here")
        mockTranslate.setResult(result: mockResponse)

        let result = try await predictionsService.translateText(
            text: "Hello there",
            language: .english,
            targetLanguage: .malayalam
        )
        XCTAssertEqual(
            result.text,
            mockResponse.translatedText,
            "Translated text should be same"
        )
        XCTAssertEqual(result.targetLanguage, .malayalam)
    }
}
