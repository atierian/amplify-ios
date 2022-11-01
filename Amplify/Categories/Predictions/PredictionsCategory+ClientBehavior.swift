//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension PredictionsCategory: PredictionsCategoryBehavior {

    /// Synthesize the text to audio
    /// - Parameter textToSpeech: The text to be synthesized to audio
    /// - Parameter listener: Triggered when the event occurs
    /// - Parameter options: Parameters to specific plugin behavior
    public func convert(
        textToSpeech: String,
        options: PredictionsTextToSpeechRequest.Options? = nil
    ) async throws -> TextToSpeechResult {
        try await plugin.convert(
            textToSpeech: textToSpeech,
            options: options
        )

    }

    /// Translate the text to the language specified.
    /// - Parameter textToTranslate: The text to translate
    /// - Parameter language: The language of the text given
    /// - Parameter targetLanguage: The language to which the text should be translated
    /// - Parameter options: Parameters to specific plugin behavior
    /// - Parameter listener: Triggered when the event occurs
    public func convert(
        textToTranslate: String,
        language: LanguageType?,
        targetLanguage: LanguageType?,
        options: PredictionsTranslateTextRequest.Options? = nil
    ) async throws -> TranslateTextResult {
        try await plugin.convert(
            textToTranslate: textToTranslate,
            language: language,
            targetLanguage: targetLanguage,
            options: options
        )
    }

    /// Transcribe audio to text
    /// - Parameter speechToText: The url of the audio to be transcribed
    /// - Parameter listener: Triggered when the event occurs
    /// - Parameter options: Parameters to specific plugin behavior
    public func convert(
        speechToText: URL,
        options: PredictionsSpeechToTextRequest.Options?
    ) async throws -> SpeechToTextResult {
        try await plugin.convert(
            speechToText: speechToText,
            options: options
        )
    }

    /// Detect contents of an image based on `IdentifyAction`
    /// - Parameter type: The type of image detection you want to perform
    /// - Parameter image: The image you are sending
    /// - Parameter options: Parameters to specific plugin behavior
    /// - Parameter listener: Triggered when the event occurs
    public func identify(
        type: IdentifyAction,
        image: URL,
        options: PredictionsIdentifyRequest.Options? = nil
    ) async throws -> IdentifyResult {
        try await plugin.identify(
            type: type,
            image: image,
            options: options
        )
    }

    /// Interpret the text and return sentiment analysis, entity detection, language detection,
    /// syntax detection, key phrases detection
    /// - Parameter text: Text to interpret
    /// - Parameter options:Parameters to specific plugin behavior
    /// - Parameter options:Parameters to specific plugin behavior
    public func interpret(
        text: String,
        options: PredictionsInterpretRequest.Options? = nil
    ) async throws -> InterpretResult {
        try await plugin.interpret(
            text: text,
            options: options
        )
    }
}
