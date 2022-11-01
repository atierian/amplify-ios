//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Behavior of the Predictions category that clients will use
public protocol PredictionsCategoryBehavior {

    /// Translate the text to the language specified.
    /// - Parameter textToTranslate: The text to translate
    /// - Parameter language: The language of the text given
    /// - Parameter targetLanguage: The language to which the text should be translated
    /// - Parameter options: Parameters to specific plugin behavior
    /// - Parameter listener: Triggered when the event occurs
    func convert(
        textToTranslate: String,
        language: LanguageType?,
        targetLanguage: LanguageType?,
        options: PredictionsTranslateTextRequest.Options?
    ) async throws -> TranslateTextResult

    /// Synthesize the text to audio
    /// - Parameter textToSpeech: The text to be synthesized to audio
    /// - Parameter listener: Triggered when the event occurs
    /// - Parameter options: Parameters to specific plugin behavior
    func convert(
        textToSpeech: String,
        options: PredictionsTextToSpeechRequest.Options?
    ) async throws -> TextToSpeechResult

    /// Transcribe audio to text
    /// - Parameter speechToText: The url of the audio to be transcribed
    /// - Parameter listener: Triggered when the event occurs
    /// - Parameter options: Parameters to specific plugin behavior
    func convert(
        speechToText: URL,
        options: PredictionsSpeechToTextRequest.Options?
    ) async throws -> SpeechToTextResult

    /// Detect contents of an image based on `IdentifyAction`
    /// - Parameter type: The type of image detection you want to perform
    /// - Parameter image: The image you are sending
    /// - Parameter options: Parameters to specific plugin behavior
    /// - Parameter listener: Triggered when the event occurs
    func identify(
        type: IdentifyAction,
        image: URL,
        options: PredictionsIdentifyRequest.Options?
    ) async throws -> IdentifyResult

    /// Interpret the text and return sentiment analysis, entity detection, language detection,
    /// syntax detection, key phrases detection
    /// - Parameter text: Text to interpret
    /// - Parameter options:Parameters to specific plugin behavior
    /// - Parameter options:Parameters to specific plugin behavior
    func interpret(
        text: String,
        options: PredictionsInterpretRequest.Options?
    ) async throws -> InterpretResult
}
