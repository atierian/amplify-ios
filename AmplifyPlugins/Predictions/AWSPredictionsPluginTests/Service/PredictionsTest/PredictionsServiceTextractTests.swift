//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSTextract
import CoreML
import Amplify
import Foundation
@testable import AWSPredictionsPlugin

class PredictionsServiceTextractTests: XCTestCase {
    var predictionsService: AWSPredictionsService!
    let mockTextract = MockTextractBehavior()

    override func setUp() {
        let mockConfigurationJSON = """
        {
            "defaultRegion": "us-west-2"
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
                                                       awsTranslate: MockTranslateBehavior(),
                                                       awsRekognition: MockRekognitionBehavior(),
                                                       awsTextract: mockTextract,
                                                       awsComprehend: MockComprehendBehavior(),
                                                       awsPolly: MockPollyBehavior(),
//                                                       awsTranscribeStreaming: MockTranscribeBehavior(),
//                                                       nativeWebSocketProvider: nativeWebSocketProvider,
//                                                       transcribeClientDelegate: clientDelegate,
                                                       configuration: mockConfiguration)
        } catch {
            XCTFail("Initialization of the text failed")
        }
    }

    /// Test whether we can make a successfull textract call to identify tables
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke textract api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyTablesService() async throws {
        let mockResponse = AnalyzeDocumentOutputResponse(
            blocks: .init()
        )

        mockTextract.setAnalyzeDocument(result: mockResponse)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let resultReceived = expectation(description: "Transcription result should be returned")

        let result = try await predictionsService.detectText(image: url, format: .table) as? IdentifyDocumentTextResult
        let text = IdentifyTextResultTransformers.processText(mockResponse.blocks!)

        XCTAssertEqual(
            result?.identifiedLines.count,
            text.identifiedLines.count,
            "Line count should be the same"
        )
    }

    /// Test whether error is correctly propogated for text matches
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyTablesServiceWithError() async throws {
        mockTextract.setError(error: NSError())
        let url = URL(fileURLWithPath: "")
        let errorReceived = expectation(description: "Error should be returned")
        do {
            let result = try await predictionsService.detectText(image: url, format: .table)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether error is correctly propogated for text matches with nil response
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyTablesServiceWithNilResponse() async throws {
        mockTextract.setAnalyzeDocument(result: nil)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let errorReceived = expectation(description: "Error should be returned")

        do {
            let result = try await predictionsService.detectText(image: url, format: .table)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether we can make a successfull textract call to identify forms
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke textract api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyFormsService() async throws {
        let mockResponse = AnalyzeDocumentOutputResponse(blocks: .init())

        mockTextract.setAnalyzeDocument(result: mockResponse)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }

        let result = try await predictionsService.detectText(image: url, format: .form)
        let textResult = result as? IdentifyDocumentTextResult
        let text = IdentifyTextResultTransformers.processText(mockResponse.blocks!)
        XCTAssertEqual(
            textResult?.identifiedLines.count,
            text.identifiedLines.count,
            "Line count should be the same"
        )
    }

    /// Test whether error is correctly propogated for document text matches
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyFormsServiceWithError() async throws {
        let mockError = NSError()
        mockTextract.setError(error: mockError)
        let url = URL(fileURLWithPath: "")
        let errorReceived = expectation(description: "Error should be returned")
        do {
            let result = try await predictionsService.detectText(image: url, format: .form)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether error is correctly propogated for text matches with nil response
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke a normal request
    /// - Then:
    ///    - I should get back a service error because response is nil
    ///
    func testIdentifyFormsServiceWithNilResponse() async throws {
        mockTextract.setAnalyzeDocument(result: nil)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let errorReceived = expectation(description: "Error should be returned")

        do {
            let result = try await predictionsService.detectText(image: url, format: .form)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether we can make a successfull textract call to identify forms and tables
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke textract api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyAllTextService() async throws {
        let mockResponse = AnalyzeDocumentOutputResponse(blocks: .init())
        mockTextract.setAnalyzeDocument(result: mockResponse)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }

        let result = try await predictionsService.detectText(image: url, format: .all)
        let textResult = result as? IdentifyDocumentTextResult
        let text = IdentifyTextResultTransformers.processText(mockResponse.blocks!)
        XCTAssertEqual(
            textResult?.identifiedLines.count,
            text.identifiedLines.count,
            "Line count should be the same"
        )
    }

    /// Test whether error is correctly propogated for .all document text matches
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyAllTextServiceWithError() async throws {
        let mockError = NSError()
        mockTextract.setError(error: mockError)
        let url = URL(fileURLWithPath: "")
        do {
            let result = try await predictionsService.detectText(image: url, format: .all)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether error is correctly propogated for text matches with nil response
    ///
    /// - Given: Predictions service with textract behavior
    /// - When:
    ///    - I invoke a normal request
    /// - Then:
    ///    - I should get back a service error because response is nil
    ///
    func testIdentifyAllTextServiceWithNilResponse() async throws {
        mockTextract.setAnalyzeDocument(result: nil)
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: "testImageText", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }
        let errorReceived = expectation(description: "Error should be returned")

        do {
            let result = try await predictionsService.detectText(image: url, format: .all)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }
}
