//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
//import AWSCore
import AWSRekognition
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
        return detectLabels!
    }

    func detectModerationLabels(
        request: DetectModerationLabelsInput
    ) async throws -> DetectModerationLabelsOutputResponse {
        try validate()
        return moderationLabelsResponse!
    }

    func detectCelebs(
        request: RecognizeCelebritiesInput
    ) async throws -> RecognizeCelebritiesOutputResponse {
        try validate()
        return celebritiesResponse!
    }

    func detectText(
        request: DetectTextInput
    ) async throws -> DetectTextOutputResponse {
        try validate()
        return detectText!
    }

    func detectFaces(
        request: DetectFacesInput
    ) async throws -> DetectFacesOutputResponse {
        try validate()
        return facesResponse!
    }

    func detectFacesFromCollection(
        request: SearchFacesByImageInput
    ) async throws -> SearchFacesByImageOutputResponse {
        try validate()
        return facesFromCollection!
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
