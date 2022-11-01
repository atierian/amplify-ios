//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

protocol CoreMLPredictionBehavior: AnyObject {

//    typealias InterpretTextEventHandler = (InterpretEvent) -> Void
//    typealias InterpretEvent = PredictionsEvent<InterpretResult, PredictionsError>
//
//    typealias IdentifyEventHandler = (IdentifyEvent) -> Void
//    typealias IdentifyEvent = PredictionsEvent<IdentifyResult, PredictionsError>
//
//    typealias TranscribeEventHandler = (TranscribeEvent) -> Void
//    typealias TranscribeEvent = PredictionsEvent<SpeechToTextResult, PredictionsError>

    func comprehend(
        text: String
    ) async throws -> InterpretResult

    func identify(
        _ imageURL: URL,
        type: IdentifyAction
    ) async throws -> IdentifyResult


    // TODO: Transcribe
//    func transcribe(
//        _ speechToText: URL
//    ) async throws -> SpeechToTextResult

}
