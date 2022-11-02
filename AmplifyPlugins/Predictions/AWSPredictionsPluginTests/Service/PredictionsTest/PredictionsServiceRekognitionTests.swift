//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSRekognition
import CoreML
import Amplify
import Foundation
@testable import AWSPredictionsPlugin

// swiftlint:disable file_length type_body_length
class PredictionsServiceRekognitionTests: XCTestCase {

    var predictionsService: AWSPredictionsService!
    let mockRekognition = MockRekognitionBehavior()
    var mockConfigurationJSON = """
    {
        "defaultRegion": "us-west-2"
    }
    """

    override func setUp() {

    }

    func setUpAmplify(withCollection: Bool = false) {

        if withCollection {
            // set test collection id to invoke collection method of rekognition
            mockConfigurationJSON = """
            {
            "defaultRegion": "us-west-2",
            "identify": {
            "identifyEntities": {
            "collectionId": "TestCollection",
            "maxFaces": 50,
            "region": "us-west-2"
            }
            }
            }
            """
        }

        do {
//            let clientDelegate = NativeWSTranscribeStreamingClientDelegate()
//            let dispatchQueue = DispatchQueue(label: "TranscribeStreamingTests")
//            let nativeWebSocketProvider = NativeWebSocketProvider(clientDelegate: clientDelegate,
//                                                                  callbackQueue: dispatchQueue)
            let mockConfiguration = try JSONDecoder().decode(PredictionsPluginConfiguration.self,
                                                             from: mockConfigurationJSON.data(using: .utf8)!)
            predictionsService = AWSPredictionsService(identifier: "",
                                                       awsTranslate: MockTranslateBehavior(),
                                                       awsRekognition: mockRekognition,
                                                       awsTextract: MockTextractBehavior(),
                                                       awsComprehend: MockComprehendBehavior(),
                                                       awsPolly: MockPollyBehavior(),
//                                                       awsTranscribeStreaming: MockTranscribeBehavior(),
//                                                       nativeWebSocketProvider: nativeWebSocketProvider,
//                                                       transcribeClientDelegate: clientDelegate,
                                                       configuration: mockConfiguration)
        } catch {
            print(error)
            XCTFail("Initialization of the text failed")
        }
    }

    /// Test whether we can make a successfull rekognition call to identify labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyLabelsService() async throws {
        setUpAmplify()

        let mockResponse = DetectLabelsOutputResponse(labels: .init())
        mockRekognition.setLabelsResponse(result: mockResponse)

        guard let url = Bundle.module.url(forResource: "TestImages/testImageLabels", withExtension: "jpg") else {
            return XCTFail("Unable to find image")
        }

        let result = try await predictionsService.detectLabels(image: url, type: .labels)
        let labelResult = result as? IdentifyLabelsResult
        let labels = IdentifyLabelsResultTransformers.processLabels(mockResponse.labels!)
        XCTAssertEqual(labelResult?.labels, labels, "Labels should be the same")
    }

    /// Test whether error is correctly propogated
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyLabelsServiceWithError() async throws {
        setUpAmplify()

        let mockError = NSError()
        mockRekognition.setError(error: mockError)
        let url = URL(fileURLWithPath: "")

        do {
            let result = try await predictionsService.detectLabels(image: url, type: .labels)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether error is correctly propogated
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error because response was nil
    ///
    func testIdentifyLabelsServiceWithNilResponse() async throws {
        setUpAmplify()
        mockRekognition.setLabelsResponse(result: nil)

        guard let url = Bundle.module.url(forResource: "TestImages/testImageLabels", withExtension: "jpg") else {
            return XCTFail("Unable to find image")
        }

        do {
            let result = try await predictionsService.detectLabels(image: url, type: .labels)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether we can make a successful rekognition call to identify moderation labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyModerationLabelsService() async throws {
        setUpAmplify()

        let mockResponse = DetectModerationLabelsOutputResponse(moderationLabels: .init())
        mockRekognition.setModerationLabelsResponse(result: mockResponse)
        guard let url = Bundle.module.url(forResource: "TestImages/testImageLabels", withExtension: "jpg") else {
            return XCTFail("Unable to find image")
        }

        let result = try await predictionsService.detectLabels(image: url, type: .moderation)
        let labelResult = result as? IdentifyLabelsResult
        let labels = IdentifyLabelsResultTransformers.processModerationLabels(mockResponse.moderationLabels!)
        XCTAssertEqual(
            labelResult?.labels,
            labels,
            "Labels should be the same"
        )
        XCTAssertNotNil(
            labelResult?.unsafeContent,
            "unsafe content should have a boolean in it since we called moderation labels"
        )

    }

    /// Test whether error is prograted correctly when making a rekognition call to identify moderation labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyModerationLabelsServiceWithError() async throws {
        setUpAmplify()

        let mockError = NSError()
        mockRekognition.setError(error: mockError)
        let url = URL(fileURLWithPath: "")

        do {
            let result = try await predictionsService.detectLabels(image: url, type: .moderation)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether we can make a successful rekognition call to identify moderation labels but receive a nil response
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a service error because response is nil
    ///
    func testIdentifyModerationLabelsServiceWithNilResponse() async throws {
        setUpAmplify()
        mockRekognition.setModerationLabelsResponse(result: nil)

        guard let url = Bundle.module.url(forResource: "TestImages/testImageLabels", withExtension: "jpg") else {
            return XCTFail("Unable to find image")
        }

        do {
            let result = try await predictionsService.detectLabels(image: url, type: .moderation)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether we can make a successful rekognition call to identify all labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyAllLabelsService() async throws {
        setUpAmplify()

        let mockLabelsResponse = DetectLabelsOutputResponse(labels: .init())
        let mockModerationResponse = DetectModerationLabelsOutputResponse(moderationLabels: .init())

        mockRekognition.setAllLabelsResponse(labelsResult: mockLabelsResponse, moderationResult: mockModerationResponse)

        guard let url = Bundle.module.url(forResource: "TestImages/testImageLabels", withExtension: "jpg") else {
            XCTFail("Unable to find image")
            return
        }

        let result = try await predictionsService.detectLabels(image: url, type: .all)
        let labelResult = result as? IdentifyLabelsResult
        let labels = IdentifyLabelsResultTransformers.processLabels(mockLabelsResponse.labels!)
        XCTAssertEqual(
            labelResult?.labels,
            labels,
            "Labels should be the same"
        )
        XCTAssertNotNil(
            labelResult?.unsafeContent,
            "unsafe content should have a boolean in it since we called all labels"
        )

    }

    /// Test whether error is prograted correctly when making a rekognition call to identify all labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a service error because response is nil
    ///
    func testIdentifyAllLabelsServiceWithNilResponse() async throws {
        setUpAmplify()

        mockRekognition.setAllLabelsResponse(labelsResult: nil, moderationResult: nil)

        guard let url = Bundle.module.url(forResource: "TestImages/testImageLabels", withExtension: "jpg") else {
            return XCTFail("Unable to find image")
        }

        do {
            let result = try await predictionsService.detectLabels(image: url, type: .all)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether error is prograted correctly when making a rekognition call to identify all labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    ///    - Set mockLabelsResponse as labelsResult, set moderationResult to be nil
    /// - Then:
    ///    - I should get back a service error because moderation response is nil
    ///
    func testIdentifyAllLabelsServiceWithNilModerationResponse() async throws {
        setUpAmplify()

        let mockLabelsResponse = DetectLabelsOutputResponse(labels: .init())
        mockRekognition.setAllLabelsResponse(labelsResult: mockLabelsResponse, moderationResult: nil)

        guard let url = Bundle.module.url(forResource: "TestImages/testImageLabels", withExtension: "jpg") else {
            return XCTFail("Unable to find image")
        }

        do {
            let result = try await predictionsService.detectLabels(image: url, type: .all)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether error is prograted correctly when making a rekognition call to identify all labels
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyAllLabelsServiceWithError() async throws {
        setUpAmplify()
        let mockError = NSError()
        mockRekognition.setError(error: mockError)
        let url = URL(fileURLWithPath: "")

        do {
            let result = try await predictionsService.detectLabels(image: url, type: .all)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether we can make a successfull rekognition call to identify entities
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyEntitiesService() async throws {
        setUpAmplify()
        let mockResponse = DetectFacesOutputResponse(faceDetails: .init())
        mockRekognition.setFacesResponse(result: mockResponse)

        guard let url = Bundle.module.url(forResource: "TestImages/testImageEntities", withExtension: "jpg") else {
            return XCTFail("Unable to find image")
        }

        let result = try await predictionsService.detectEntities(image: url)
        let entitiesResult = result as? IdentifyEntitiesResult
        let newFaces = IdentifyEntitiesResultTransformers.processFaces(mockResponse.faceDetails!)
        XCTAssertEqual(
            entitiesResult?.entities.count,
            newFaces.count,
            "Faces count number should be the same"
        )

    }

    /// Test whether error is correctly propogated for detecting entities
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyEntitiesServiceWithError() async throws {
        setUpAmplify()

        let mockError = NSError()
        mockRekognition.setError(error: mockError)
        let url = URL(fileURLWithPath: "")

        do {
            let result = try await predictionsService.detectEntities(image: url)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether error is correctly propogated for detecting entities when a nil response is received
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an nil request
    /// - Then:
    ///    - I should get back a service error because response is nil
    ///
    func testIdentifyEntitiesServiceWithNilResponse() async throws {
        setUpAmplify()
        mockRekognition.setFacesResponse(result: nil)

        guard let url = Bundle.module.url(forResource: "TestImages/testImageEntities", withExtension: "jpg") else {
            return XCTFail("Unable to find image")
        }
        do {
            let result = try await predictionsService.detectEntities(image: url)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether we can make a successfull rekognition call to identify entities from a collection
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyEntityMatchesService() async throws {
        setUpAmplify(withCollection: true)

        let mockResponse = SearchFacesByImageOutputResponse(faceMatches: .init())

        mockRekognition.setFacesFromCollection(result: mockResponse)

        guard let url = Bundle.module.url(forResource: "TestImages/testImageEntities", withExtension: "jpg") else {
            return XCTFail("Unable to find image")
        }

        let result = try await predictionsService.detectEntities(image: url)
        let newFaces = IdentifyEntitiesResultTransformers.processCollectionFaces(mockResponse.faceMatches!)
        let entitiesResult = result as? IdentifyEntityMatchesResult
        XCTAssertEqual(
            entitiesResult?.entities.count,
            newFaces.count,
            "Faces count number should be the same"
        )
    }

    /// Test whether error is correctly propogated for entity matches
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyEntityMatchesServiceWithError() async throws {
        setUpAmplify(withCollection: true)

        let mockError = NSError()
        mockRekognition.setError(error: mockError)
        let url = URL(fileURLWithPath: "")

        do {
            let result = try await predictionsService.detectEntities(image: url)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether error is correctly propogated for entity matches when request is nil
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke a valid request
    /// - Then:
    ///    - I should get back a service error and nil response
    ///
    func testIdentifyEntityMatchesServiceWithNilResponse() async throws {
        setUpAmplify(withCollection: true)
        mockRekognition.setFacesFromCollection(result: nil)

        guard let url = Bundle.module.url(forResource: "TestImages/testImageEntities", withExtension: "jpg") else {
            return XCTFail("Unable to find image")
        }

        do {
            let result = try await predictionsService.detectEntities(image: url)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether we can make a successfull rekognition call to identify plain text
    ///
    /// - Given: Predictions service with rekognition behavior
    /// - When:
    ///    - I invoke rekognition api in predictions service
    /// - Then:
    ///    - I should get back a result
    ///
    func testIdentifyPlainTextService() async throws {
        setUpAmplify()

        let mockResponse = DetectTextOutputResponse(textDetections: .init())

        mockRekognition.setText(result: mockResponse)

        guard let url = Bundle.module.url(forResource: "TestImages/testImageText", withExtension: "jpg") else {
            return XCTFail("Unable to find image")
        }

        let result = try await  predictionsService.detectText(image: url, format: .plain)
        let textResult = result as? IdentifyTextResult
        let newText = IdentifyTextResultTransformers.processText(mockResponse.textDetections!)
        XCTAssertEqual(
            textResult?.identifiedLines?.count,
            newText.identifiedLines?.count,
            "Text line count number should be the same"
        )

    }

    /// Test whether error is correctly propogated for text matches
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke an invalid request
    /// - Then:
    ///    - I should get back a service error
    ///
    func testIdentifyPlainTextServiceWithError() async throws {
        setUpAmplify()

        let mockError = NSError()
        mockRekognition.setError(error: mockError)
        let url = URL(fileURLWithPath: "")

        do {
            let result = try await predictionsService.detectText(image: url, format: .plain)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }

    /// Test whether error is correctly propogated for text matches and receive a nil response
    ///
    /// - Given: Predictions service with rekogniton behavior
    /// - When:
    ///    - I invoke a valid request
    /// - Then:
    ///    - I should get back a service error because there was a nil response
    ///
    func testIdentifyPlainTextServiceWithNilResponse() async throws {
        setUpAmplify()

        mockRekognition.setText(result: nil)
        guard let url = Bundle.module.url(forResource: "TestImages/testImageText", withExtension: "jpg") else {
            return XCTFail("Unable to find image")
        }

        do {
            let result = try await predictionsService.detectText(image: url, format: .plain)
            XCTFail("Should not produce result: \(result)")
        } catch {
            XCTAssertNotNil(error, "Should produce an error")
        }
    }
}
