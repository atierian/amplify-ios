//
//  File.swift
//  
//
//  Created by Saultz, Ian on 11/8/22.
//

import Foundation

public struct ClientSessionInformationEvent: Codable {
    public init(
        deviceInformation: ClientSessionInformationEvent.DeviceInformation,
        challenge: ClientSessionInformationEvent.Challenge

    ) {
        self.deviceInformation = deviceInformation
        self.challenge = challenge
    }

    let deviceInformation: DeviceInformation
    let challenge: Challenge

    enum CodingKeys: String, CodingKey {
        case deviceInformation = "DeviceInformation"
        case challenge = "Challenge"
    }
}

extension ClientSessionInformationEvent {
    public struct DeviceInformation: Codable {
        public init(
            videoHeight: Double,
            videoWidth: Double
        ) {
            self.videoHeight = videoHeight
            self.videoWidth = videoWidth
        }

        let videoHeight: Double
        let videoWidth: Double

        enum CodingKeys: String, CodingKey {
            case videoHeight = "VideoHeight"
            case videoWidth = "VideoWidth"
        }
    }

    public struct Challenge: Codable {
        public init(
            faceMovementAndLightChallenge: ClientSessionInformationEvent.Challenge.FaceMovementAndLightChallenge
        ) {
            self.faceMovementAndLightChallenge = faceMovementAndLightChallenge
        }

        let faceMovementAndLightChallenge: FaceMovementAndLightChallenge

        enum CodingKeys: String, CodingKey {
            case faceMovementAndLightChallenge = "FaceMovementAndLightChallenge"
        }
    }
}

extension ClientSessionInformationEvent.Challenge {
    public struct FaceMovementAndLightChallenge: Codable {
        public init(
            challengeID: String,
            targetFacePosition: ClientSessionInformationEvent.Challenge.FaceMovementAndLightChallenge.FacePosition,
            initialFacePosition: ClientSessionInformationEvent.Challenge.FaceMovementAndLightChallenge.FacePosition,
            recordingTimestamps: ClientSessionInformationEvent.Challenge.FaceMovementAndLightChallenge.RecordingTimestamps,
            colorSequence: ClientSessionInformationEvent.Challenge.FaceMovementAndLightChallenge.ColorSequence
        ) {
            self.challengeID = challengeID
            self.targetFacePosition = targetFacePosition
            self.initialFacePosition = initialFacePosition
            self.recordingTimestamps = recordingTimestamps
            self.colorSequence = colorSequence
        }

        let challengeID: String
        let targetFacePosition: FacePosition
        let initialFacePosition: FacePosition
        let recordingTimestamps: RecordingTimestamps
        let colorSequence: ColorSequence

        enum CodingKeys: String, CodingKey {
            case challengeID = "ChallengeId"
            case targetFacePosition = "TargetFacePosition"
            case initialFacePosition = "InitialFacePosition"
            case recordingTimestamps = "RecordingTimestamps"
            case colorSequence = "ColorSequence"
        }
    }
}

extension ClientSessionInformationEvent.Challenge.FaceMovementAndLightChallenge {

    public struct FacePosition: Codable {
        public init(
            height: Double,
            width: Double,
            top: Double,
            left: Double
        ) {
            self.height = height
            self.width = width
            self.top = top
            self.left = left
        }

        let height: Double
        let width: Double
        let top: Double
        let left: Double

        enum CodingKeys: String, CodingKey {
            case height = "Height"
            case width = "Width"
            case top = "Top"
            case left = "Left"
        }
    }

    public struct RecordingTimestamps: Codable {
        public init(
            videoStart: Int,
            initialFaceDetected: Int,
            faceDetectedInTargetPositionStart: Int,
            faceDetectedInTargetPositionEnd: Int
        ) {
            self.videoStart = videoStart
            self.initialFaceDetected = initialFaceDetected
            self.faceDetectedInTargetPositionStart = faceDetectedInTargetPositionStart
            self.faceDetectedInTargetPositionEnd = faceDetectedInTargetPositionEnd
        }

        let videoStart: Int
        let initialFaceDetected: Int
        let faceDetectedInTargetPositionStart: Int
        let faceDetectedInTargetPositionEnd: Int

        enum CodingKeys: String, CodingKey {
            case videoStart = "VideoStart"
            case initialFaceDetected = "InitialFaceDetected"
            case faceDetectedInTargetPositionStart = "FaceDetectedInTargetPositionStart"
            case faceDetectedInTargetPositionEnd = "FaceDetectedInTargetPositionEnd"
        }
    }

    public struct ColorSequence: Codable {
        public init(
            colorTimestamps: [ClientSessionInformationEvent.Challenge.FaceMovementAndLightChallenge.ColorSequence.ColorTimestamp]
        ) {
            self.colorTimestamps = colorTimestamps
        }

        let colorTimestamps: [ColorTimestamp]

        enum CodingKeys: String, CodingKey {
            case colorTimestamps = "ColorTimestampList"
        }
    }
}

extension ClientSessionInformationEvent.Challenge.FaceMovementAndLightChallenge.ColorSequence {

    public struct ColorTimestamp: Codable {
        public init(
            color: ClientSessionInformationEvent.Challenge.FaceMovementAndLightChallenge.ColorSequence.ColorTimestamp.FreshnessColorEnum,
            timestamp: Int
        ) {
            self.color = color
            self.timestamp = timestamp
        }

        let color: FreshnessColorEnum
        let timestamp: Int

        enum CodingKeys: String, CodingKey {
            case color = "Color"
            case timestamp = "Timestamp"
        }
    }
}

extension ClientSessionInformationEvent.Challenge.FaceMovementAndLightChallenge.ColorSequence.ColorTimestamp {

    public struct FreshnessColorEnum: Codable {
        public init() {}
    }
}
