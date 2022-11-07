//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPolly

extension AWSPredictionsPlugin {

    public func convert(
        textToTranslate: String,
        language: LanguageType?,
        targetLanguage: LanguageType?,
        options: PredictionsTranslateTextRequest.Options?
    ) async throws -> TranslateTextResult {
        let request = PredictionsTranslateTextRequest(
            textToTranslate: textToTranslate,
            targetLanguage: targetLanguage,
            language: language,
            options: options ?? PredictionsTranslateTextRequest.Options()
        )

        return try await predictionsService.translateText(
            text: request.textToTranslate,
            language: request.language,
            targetLanguage: request.targetLanguage
        )
    }

    public func convert(
        textToSpeech: String,
        options: PredictionsTextToSpeechRequest.Options?
    ) async throws -> TextToSpeechResult {
        let request = PredictionsTextToSpeechRequest(
            textToSpeech: textToSpeech,
            options: options ?? PredictionsTextToSpeechRequest.Options()
        )

        try request.validate()

        func reconcileVoiceID(
            voice: VoiceType?,
            config: PredictionsPluginConfiguration
        ) -> PollyClientTypes.VoiceId {
            if case .voice(let voice) = request.options.voiceType,
               let pollyVoiceID = PollyClientTypes.VoiceId(rawValue: voice) {
                return pollyVoiceID
            }

            if let configVoice = config.convert.speechGenerator?.voiceID,
               let pollyVoiceID = PollyClientTypes.VoiceId(rawValue: configVoice) {
                return pollyVoiceID
            }

            let defaultVoiceID = PollyClientTypes.VoiceId.ivy
            return defaultVoiceID
        }

        let voiceID = reconcileVoiceID(
            voice: request.options.voiceType,
            config: predictionsService.predictionsConfig
        )

        let result = try await predictionsService.synthesizeText(
            text: request.textToSpeech,
            voiceId: voiceID
        )

        return result
    }


    public func convert(
        speechToText: URL,
        options: PredictionsSpeechToTextRequest.Options?
    ) async throws -> SpeechToTextResult {

        // TODO: Transcribe
//        let request = PredictionsSpeechToTextRequest(
//            speechToText: speechToText,
//            options: options ?? PredictionsSpeechToTextRequest.Options()
//        )
//
//        let multiService = TranscribeMultiService(
//            coreMLService: coreMLService,
//            predictionsService: predictionsService
//        )
//
        // TODO: Only one transcription request can be sent at a time otherwise you receive an error
        throw NSError(domain: "", code: 42, userInfo: nil)
    }

    public func identify(
        type: IdentifyAction,
        image: URL,
        options: PredictionsIdentifyRequest.Options?
    ) async throws -> IdentifyResult {
        let options = options
        let request = PredictionsIdentifyRequest(
            image: image,
            identifyType: type,
            options: options ?? PredictionsIdentifyRequest.Options()
        )

        let multiService = IdentifyMultiService(
            coreMLService: coreMLService,
            predictionsService: predictionsService
        )

        try request.validate()

        multiService.setRequest(request)
        switch request.options.defaultNetworkPolicy {
        case .offline:
            let offlineResult = try await multiService.fetchOnlineResult()
            return offlineResult
        case .auto:
            // TODO: fetchMultiServiceResult is causing memory explosion. Seems to be due to the offlineResult fetching.

            let result = try await multiService.fetchOnlineResult()
            return result
//            let multiServiceResult = try await multiService.fetchMultiServiceResult()
//            return multiServiceResult
        }
    }

    /// Interprets the input text and detects sentiment, language, syntax, and key phrases
    ///
    /// - Parameter text: input text
    /// - Parameter options: Option for the plugin
    /// - Parameter resultListener: Listener to which events are send
    public func interpret(
        text: String,
        options: PredictionsInterpretRequest.Options?
    ) async throws -> InterpretResult {
        let request = PredictionsInterpretRequest(
            textToInterpret: text,
            options: options ?? PredictionsInterpretRequest.Options()
        )

        let multiService = InterpretTextMultiService(
            coreMLService: coreMLService,
            predictionsService: predictionsService
        )

        multiService.setTextToInterpret(text: request.textToInterpret)
        switch request.options.defaultNetworkPolicy {
        case .offline:
            let offlineResposne = try await multiService.fetchOfflineResult()
            return offlineResposne
        case .auto:
            let multiServiceResposne = try await multiService.fetchMultiServiceResult()
            return multiServiceResposne
        }
    }
}
