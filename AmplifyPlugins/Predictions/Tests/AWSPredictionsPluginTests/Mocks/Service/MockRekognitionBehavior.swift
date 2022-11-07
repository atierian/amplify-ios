//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
//import AWSCore
import AWSRekognition
import Foundation
@testable import AWSPredictionsPlugin

class MockRekognitionBehavior: AWSRekognitionBehavior {

    var detectLabels: DetectLabelsOutputResponse?
    var moderationLabelsResponse: DetectModerationLabelsOutputResponse?
    var celebritiesResponse: RecognizeCelebritiesOutputResponse?
    var detectText: DetectTextOutputResponse?
    var facesResponse: DetectFacesOutputResponse?
    var facesFromCollection: SearchFacesByImageOutputResponse?
    var error: Error?

    func validate() throws {
        if let error = error { throw error }
    }

    func detectLabels(
        request: DetectLabelsInput
    ) async throws -> DetectLabelsOutputResponse {
        try validate()
        if let detectLabels = detectLabels {
            return detectLabels
        }
        throw NSError(domain: "", code: 42, userInfo: nil)
    }

    func detectModerationLabels(
        request: DetectModerationLabelsInput
    ) async throws -> DetectModerationLabelsOutputResponse {
        try validate()
        if let moderationLabelsResponse = moderationLabelsResponse {
            return moderationLabelsResponse
        }
        throw NSError(domain: "", code: 42, userInfo: nil)
    }

    func detectCelebs(
        request: RecognizeCelebritiesInput
    ) async throws -> RecognizeCelebritiesOutputResponse {
        try validate()
        if let celebritiesResponse = celebritiesResponse {
            return celebritiesResponse
        }
        throw NSError(domain: "", code: 42, userInfo: nil)
    }

    func detectText(
        request: DetectTextInput
    ) async throws -> DetectTextOutputResponse {
        try validate()
        if let detectText = detectText {
            return detectText
        }
        throw NSError(domain: "", code: 42, userInfo: nil)
    }

    func detectFaces(
        request: DetectFacesInput
    ) async throws -> DetectFacesOutputResponse {
        try validate()
        if let facesResponse = facesResponse {
            return facesResponse
        }
        throw NSError(domain: "", code: 42, userInfo: nil)
    }

    func detectFacesFromCollection(
        request: SearchFacesByImageInput
    ) async throws -> SearchFacesByImageOutputResponse {
        try validate()
        if let facesFromCollection = facesFromCollection {
            return facesFromCollection
        }
        throw NSError(domain: "", code: 42, userInfo: nil)
    }

    func getRekognition() -> RekognitionClient {
        return try! .init(region: "us-east-1")
    }

    public func setDetectCelebs(result: RecognizeCelebritiesOutputResponse) {
        celebritiesResponse = result
        error = nil
    }

    public func setFacesResponse(result: DetectFacesOutputResponse?) {
        facesResponse = result
        error = nil
    }

    public func setModerationLabelsResponse(result: DetectModerationLabelsOutputResponse?) {
        moderationLabelsResponse = result
        error = nil
    }

    public func setLabelsResponse(result: DetectLabelsOutputResponse?) {
        detectLabels = result
        error = nil
    }

    public func setAllLabelsResponse(
        labelsResult: DetectLabelsOutputResponse?,
        moderationResult: DetectModerationLabelsOutputResponse?
    ) {
        detectLabels = labelsResult
        moderationLabelsResponse = moderationResult
        error = nil
    }

    public func setFacesFromCollection(
        result: SearchFacesByImageOutputResponse?
    ) {
        facesFromCollection = result
        error = nil
    }

    public func setText(result: DetectTextOutputResponse?) {
        detectText = result
        error = nil
    }

    public func setError(error: Error) {
        celebritiesResponse = nil
        facesResponse = nil
        moderationLabelsResponse = nil
        facesFromCollection = nil
        detectText = nil
        detectLabels = nil
        self.error = error
    }

}
