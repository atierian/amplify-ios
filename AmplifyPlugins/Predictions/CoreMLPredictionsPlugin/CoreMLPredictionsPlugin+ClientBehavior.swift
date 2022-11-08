//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CoreGraphics
import Amplify

extension CoreMLPredictionsPlugin {

    public func convert(
        textToTranslate: String,
        language: LanguageType?,
        targetLanguage: LanguageType?,
        options: PredictionsTranslateTextRequest.Options?
    ) async throws -> TranslateTextResult {

        let options = options ?? PredictionsTranslateTextRequest.Options()
        let request = PredictionsTranslateTextRequest(
            textToTranslate: textToTranslate,
            targetLanguage: targetLanguage,
            language: language,
            options: options
        )
        _ = options
        _ = request

        let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
        let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
        let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
        throw predictionsError

        // TODO: Dispatch to Hub???
        // dispatch(result: .failure(predictionsError))
    }

    public func convert(
        textToSpeech: String,
        options: PredictionsTextToSpeechRequest.Options? = nil
    ) async throws -> TextToSpeechResult {
        let options = options ?? PredictionsTextToSpeechRequest.Options()
        let request = PredictionsTextToSpeechRequest(
            textToSpeech: textToSpeech,
            options: options
        )
        _ = options
        _ = request
        let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
        let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
        let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
        throw predictionsError

        // TODO: Dispatch to Hub???
        // dispatch(result: .failure(predictionsError))
    }

    public func convert(
        speechToText: URL,
        options: PredictionsSpeechToTextRequest.Options?,
        onEvent: @escaping (Event) -> Void
    ) async throws -> SpeechToTextResult {
        let options = options ?? PredictionsSpeechToTextRequest.Options()
        let request = PredictionsSpeechToTextRequest(speechToText: speechToText, options: options)
        let result = try await coreMLSpeech.getTranscription(
            request.speechToText
        )

        guard let result = result else {
            let errorDescription = CoreMLPluginErrorString.transcriptionNoResult.errorDescription
            let recovery = CoreMLPluginErrorString.transcriptionNoResult.recoverySuggestion
            let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
            // TODO: Dispatch to Hub???
            // self.dispatch(result: .failure(predictionsError))
            throw predictionsError
        }
        return result

        // TODO: Dispatch to Hub???
        // self.dispatch(result: .success(result))
    }

    public func identify(
        type: IdentifyAction,
        image: URL,
        options: PredictionsIdentifyRequest.Options?
    ) async throws -> IdentifyResult {
        let options = options ?? PredictionsIdentifyRequest.Options()
        let request = PredictionsIdentifyRequest(
            image: image,
            identifyType: type,
            options: options
        )

        guard let coreMLVisionAdapter = coreMLVision else {
            throw SomeError()
        }

        switch request.identifyType {
        case .detectCelebrity:
            let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
            let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
            let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
            throw predictionsError
            //            dispatch(result: .failure(predictionsError))
        case .detectText(let format):
            switch format {
            case .all, .table, .form:
                let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
                let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
                let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
                throw predictionsError
                //                dispatch(result: .failure(predictionsError))
            case .plain:
                guard  let result = coreMLVisionAdapter.detectText(request.image) else {
                    let errorDescription = CoreMLPluginErrorString.detectTextNoResult.errorDescription
                    let recovery = CoreMLPluginErrorString.detectTextNoResult.recoverySuggestion
                    let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
                    throw predictionsError
                    //                    dispatch(result: .failure(predictionsError))
                }
                return result
//                dispatch(result: .success(result))
            }
        case .detectEntities:
            guard let result = coreMLVisionAdapter.detectEntities(request.image) else {
                let errorDescription = CoreMLPluginErrorString.detectEntitiesNoResult.errorDescription
                let recovery = CoreMLPluginErrorString.detectEntitiesNoResult.recoverySuggestion
                let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
                throw predictionsError
                //                dispatch(result: .failure(predictionsError))
            }
            return result
//            dispatch(result: .success(result))
        case .detectLabels(let labelType):
            if labelType == .moderation { // coreml does not have an endpoint to detect moderation labels in images
                let errorDescription = CoreMLPluginErrorString.operationNotSupported.errorDescription
                let recovery = CoreMLPluginErrorString.operationNotSupported.recoverySuggestion
                let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
                throw predictionsError
//                dispatch(result: .failure(predictionsError))
            }
            guard  let result = coreMLVisionAdapter.detectLabels(request.image) else {
                let errorDescription = CoreMLPluginErrorString.detectLabelsNoResult.errorDescription
                let recovery = CoreMLPluginErrorString.detectLabelsNoResult.recoverySuggestion
                let predictionsError = PredictionsError.service(errorDescription, recovery, nil)
                throw predictionsError
                //                dispatch(result: .failure(predictionsError))
            }
            return result
//            dispatch(result: .success(result))
        }
    }

    public func interpret(
        text: String,
        options: PredictionsInterpretRequest.Options?
    ) async throws -> InterpretResult {
        let options = options ?? PredictionsInterpretRequest.Options()
        let request = PredictionsInterpretRequest(
            textToInterpret: text,
            options: options
        )

        guard let naturalLanguageAdapter = coreMLNaturalLanguage else {
            throw SomeError()
        }

        var interpretResultBuilder = InterpretResult.Builder()
        if let dominantLanguage = naturalLanguageAdapter.detectDominantLanguage(
            for: request.textToInterpret
        ) {
            let languageResult = LanguageDetectionResult(
                languageCode: dominantLanguage,
                score: nil
            )
            interpretResultBuilder.with(
                language: languageResult
            )
        }

        let syntaxToken = naturalLanguageAdapter.getSyntaxTokens(
            for: request.textToInterpret
        )

        interpretResultBuilder.with(syntax: syntaxToken)

        let entities = naturalLanguageAdapter
            .getEntities(
                for: request.textToInterpret
            )

        interpretResultBuilder.with(entities: entities)

        let sentiment = naturalLanguageAdapter.getSentiment(for: request.textToInterpret)
        let amplifySentiment: Sentiment
        switch sentiment {
        case 0.0:
            amplifySentiment = Sentiment(predominantSentiment: .neutral, sentimentScores: nil)
        case -1.0 ..< 0.0:
            amplifySentiment = Sentiment(predominantSentiment: .negative, sentimentScores: nil)
        case 0.0 ... 1.0:
            amplifySentiment = Sentiment(predominantSentiment: .positive, sentimentScores: nil)
        default:
            amplifySentiment = Sentiment(predominantSentiment: .mixed, sentimentScores: nil)
        }
        interpretResultBuilder.with(sentiment: amplifySentiment)

        let interpretResult = interpretResultBuilder.build()
        return interpretResult
//        dispatch(result: .success(interpretResult))
    }

}

// TODO: Remove
struct SomeError: Error {}
