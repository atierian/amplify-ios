//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class MockPredictionsCategoryPlugin: MessageReporter, PredictionsCategoryPlugin {

    func configure(using configuration: Any?) throws {
        notify()
    }

    func convert(
        textToSpeech: String,
        options: PredictionsTextToSpeechRequest.Options?
    ) async throws -> TextToSpeechResult {
        notify("textToSpeech")
        fatalError("Add the rest of implementation")
    }

    func convert(
        textToTranslate: String,
        language: LanguageType?,
        targetLanguage: LanguageType? = .italian,
        options: PredictionsTranslateTextRequest.Options?
    ) async throws -> TranslateTextResult {
        notify("textToTranslate")

        let request = PredictionsTranslateTextRequest(
            textToTranslate: textToTranslate,
            targetLanguage: targetLanguage ?? .italian,
            language: language ?? .english,
            options: options ?? PredictionsTranslateTextRequest.Options()
        )
        return .init(text: textToTranslate, targetLanguage: targetLanguage!)
    }

    // TODO: Transcribe
//    func convert(speechToText: URL,
//                 options: PredictionsSpeechToTextRequest.Options?,
//                 listener: PredictionsSpeechToTextOperation.ResultListener?) -> PredictionsSpeechToTextOperation {
//        notify("speechToText")
//        let request = PredictionsSpeechToTextRequest(speechToText: speechToText,
//                                                     options: options ?? PredictionsSpeechToTextRequest.Options())
//        return MockPredictionsSpeechToTextOperation(request: request)
//
//    }



    func identify(
        type: IdentifyAction,
        image: URL,
        options: PredictionsIdentifyRequest.Options?
    ) async throws -> IdentifyResult {
        notify("identifyLabels")
        let request = PredictionsIdentifyRequest(
            image: image,
            identifyType: type,
            options: options ?? PredictionsIdentifyRequest.Options()
        )
        throw NSError()
    }

    func interpret(
        text: String,
        options: PredictionsInterpretRequest.Options?
    ) async throws -> InterpretResult {
        notify("interpret")
        let request = PredictionsInterpretRequest(
            textToInterpret: text,
            options: options ?? PredictionsInterpretRequest.Options()
        )
        return InterpretResult.Builder().build()
    }

    func reset() {
        notify("reset")
    }

    var key: String {
        return "MockPredictionsCategoryPlugin"
    }
}

class MockSecondPredictionsCategoryPlugin: MockPredictionsCategoryPlugin {
    override var key: String {
        return "MockSecondPredictionsCategoryPlugin"
    }
}

//class MockPredictionsTranslateTextOperation: AmplifyOperation<
//    PredictionsTranslateTextRequest,
//    TranslateTextResult,
//    PredictionsError
//>, PredictionsTranslateTextOperation {
//
//    override func pause() {
//    }
//
//    override func resume() {
//    }
//
//    init(request: Request) {
//        super.init(categoryType: .predictions,
//                   eventName: HubPayload.EventName.Predictions.translate,
//                   request: request)
//    }
//
//}
//
//class MockPredictionsSpeechToTextOperation: AmplifyOperation<
//    PredictionsSpeechToTextRequest,
//    SpeechToTextResult,
//    PredictionsError
//>, PredictionsSpeechToTextOperation {
//
//    override func pause() {
//    }
//
//    override func resume() {
//    }
//
//    init(request: Request) {
//        super.init(categoryType: .predictions,
//                   eventName: HubPayload.EventName.Predictions.speechToText,
//                   request: request)
//    }
//
//}
//
//class MockPredictionsIdentifyOperation: AmplifyOperation<
//    PredictionsIdentifyRequest,
//    IdentifyResult,
//    PredictionsError
//>, PredictionsIdentifyOperation {
//
//    override func pause() {
//    }
//
//    override func resume() {
//    }
//
//    init(request: Request) {
//        super.init(categoryType: .predictions,
//                   eventName: HubPayload.EventName.Predictions.identifyLabels,
//                   request: request)
//    }
//
//}
//
//class MockPredictionsInterpretOperation: AmplifyOperation<
//    PredictionsInterpretRequest,
//    InterpretResult,
//    PredictionsError
//>, PredictionsInterpretOperation {
//
//    override func pause() {
//    }
//
//    override func resume() {
//    }
//
//    init(request: Request) {
//        super.init(categoryType: .predictions,
//                   eventName: HubPayload.EventName.Predictions.interpret,
//                   request: request)
//    }
//
//}
