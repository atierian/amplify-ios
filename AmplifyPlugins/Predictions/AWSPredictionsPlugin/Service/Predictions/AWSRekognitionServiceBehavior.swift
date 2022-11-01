//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSRekognition
import Foundation

protocol AWSRekognitionServiceBehavior {

    typealias RekognitionServiceEventHandler = (RekognitionServiceEvent) -> Void
    typealias RekognitionServiceEvent = PredictionsEvent<IdentifyResult, PredictionsError>

    func detectLabels(
        image: URL,
        type: LabelType
    ) async throws -> IdentifyResult

    func detectCelebrities(
        image: URL
    ) async throws -> IdentifyResult

    func detectText(
        image: URL,
        format: TextFormatType
    ) async throws -> IdentifyResult

    func detectEntities(
        image: URL
    ) async throws -> IdentifyResult
}
