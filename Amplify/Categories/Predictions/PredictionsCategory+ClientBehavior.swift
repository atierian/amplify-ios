//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class Foo {
    func convert<Input, Options, Output>(
        _ request: Request<Input, Options, Output>,
        options: Options
    ) async throws -> Output {
        try await request.output(request.input, options)
    }

    struct Request<Input, Options, Output> {
        let input: Input
        let output: (Input, Options) async throws -> Output
    }

    func fo() async throws {
        let result = try await convert(
            .textToSpeech("Hello, world"),
            options: .init()
        )
        _ = result

        let result2 = try await convert(
            .textToTranslate(
                "Hello, world!",
                from: .english,
                to: .acoli
            ),
            options: .init()
        )
        _ = result2

        let result3 = try await convert(
            .speechToText(
                .init(string: "")!,
                onEvent: { event in

                }
            ),
            options: .init()
        )
        _ = result3
    }
}

class Bar {
    func identify<Action, Input, Options, Output>(
        _ request: Request<Action, Input, Options, Output>,
        in image: Input,
        options: Options
    ) async throws -> Output {
        try await request.output(request.action, request.input, options)
    }

    struct Request<Action, Input, Options, Output> {
        let action: Action
        let input: Input
        let output: (Action, Input, Options) async throws -> Output
    }

    struct Action {
        enum Kind {
            case detectCelebrity
            case detectLabels(LabelType)
            case detectEntities
            case detectText(TextFormatType)
        }
    }
}



extension Bar.Request where Action == IdentifyAction,
                            Input == URL,
                            Options == PredictionsIdentifyRequest.Options,
                            Output == IdentifyTextResult {
    static func text(
        basis: TextFormatType,
        image: URL,
        options: PredictionsIdentifyRequest.Options
    ) -> Self {
        .init(
            action: .detectText(basis),
            input: image,
            output: { action, input, options in
                fatalError()
//                try await Amplify.Predictions.plugin
//                    .identify(type: action, image: input, options: options)
            }
        )
    }
}

extension Foo.Request where
    Input == String,
    Options == PredictionsTextToSpeechRequest.Options,
    Output == TextToSpeechResult {
        static func textToSpeech(_ text: String) -> Self {
            .init(
                input: text,
                output: { input, options in
                    try await Amplify.Predictions.plugin
                        .convert(textToSpeech: input, options: options)
                }
            )
        }
}

extension Foo.Request where Input == (String, LanguageType, LanguageType),
                            Options == PredictionsTranslateTextRequest.Options,
                            Output == TranslateTextResult {

    static func textToTranslate(
        _ text: String,
        from language: LanguageType,
        to targetLanguage: LanguageType
    ) -> Self {
        .init(
            input: (text, language, targetLanguage),
            output: { (input, options) in
                let (text, language, targetLanguage) = input
                return try await Amplify.Predictions.plugin
                    .convert(
                        textToTranslate: text,
                        language: language,
                        targetLanguage: targetLanguage,
                        options: options)
            })
    }
}

public struct Event {
    public init() {}
}
class SpeechToTextSession {}
extension Foo.Request where Input == (URL, (Event) -> Void),
                            Options == PredictionsSpeechToTextRequest.Options,
                            Output == SpeechToTextResult {
    static func speechToText(_ url: URL, onEvent: @escaping (Event) -> Void) -> Self {
        .init(
            input: (url, onEvent),
            output: { input, options in
                let (url, onEvent) = input
                return try await Amplify.Predictions.plugin
                    .convert(speechToText: url, options: options, onEvent: onEvent)
            }
        )
    }
}

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
        options: PredictionsSpeechToTextRequest.Options? = nil,
        onEvent: @escaping (Event) -> Void
    ) async throws -> SpeechToTextResult {
        try await plugin.convert(
            speechToText: speechToText,
            options: options,
            onEvent: onEvent
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
