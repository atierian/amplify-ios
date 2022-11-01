//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import CoreMLPredictionsPlugin

class CoreMLPredictionService: CoreMLPredictionBehavior {

    let coreMLPlugin: CoreMLPredictionsPlugin

    init(configuration: Any?) throws {
        self.coreMLPlugin = CoreMLPredictionsPlugin()
        try coreMLPlugin.configure(using: configuration)
    }

    func comprehend(
        text: String
    ) async throws -> InterpretResult {
        return try await coreMLPlugin.interpret(
            text: text,
            options: PredictionsInterpretRequest.Options()
        )
    }

    func identify(
        _ imageURL: URL,
        type: IdentifyAction
    ) async throws -> IdentifyResult {
        try await coreMLPlugin.identify(
            type: type,
            image: imageURL,
            options: PredictionsIdentifyRequest.Options()
        )
    }

    // TODO: Transribe
//    func transcribe(
//        _ speechToText: URL
//    ) async throws -> SpeechToTextResult {
//        try await coreMLPlugin.convert(
//            speechToText: speechToText,
//            options: PredictionsSpeechToTextRequest.Options()
//        )
//    }
}
