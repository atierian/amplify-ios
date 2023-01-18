//
//  File.swift
//
//
//  Created by Saultz, Ian on 11/8/22.
//

import Foundation
import CommonCrypto
import zlib

enum EventStreamCoding {
    static func encode(chunk: Data, headers: [String: String]) -> Data {
        var headersLen = 0
        for (key, value) in headers {
            headersLen += Data(key.utf8).count
            headersLen += Data(value.utf8).count
            headersLen += 4
        }

        let payloadLength = chunk.count
        let headerLength = headersLen
        let messageLength = 16 + payloadLength + headerLength

        var resultData = Data.init(capacity: messageLength)

        var messageLengthToEncode = UInt32(messageLength)
        messageLengthToEncode = CFSwapInt32HostToBig(messageLengthToEncode)
        let messageLengthToEncodeBytes: [UInt8] = withUnsafeBytes(of: &messageLengthToEncode, Array.init)
        resultData.append(contentsOf: messageLengthToEncodeBytes)

        var headerLengthToEncode = UInt32(headerLength)
        headerLengthToEncode = CFSwapInt32HostToBig(headerLengthToEncode)
        let headerLengthToEncodeBytes: [UInt8] = withUnsafeBytes(of: &headerLengthToEncode, Array.init)
        resultData.append(contentsOf: headerLengthToEncodeBytes)

        let preludeData = [UInt8](resultData[0..<8])
        let crc = crc32(0, preludeData, uInt(preludeData.count))
        var crcInt = CFSwapInt32HostToBig(UInt32(crc))
        let crcIntBytes: [UInt8] = withUnsafeBytes(of: &crcInt, Array.init)
        resultData.append(contentsOf: crcIntBytes)

        for (key, value) in headers {
            let headerKeyLen: UInt8 = UInt8(Data(key.utf8).count)
            var headerValLen: UInt16 = UInt16(Data(value.utf8).count)
            headerValLen = CFSwapInt16(headerValLen)
            let headerValLenBytes: [UInt8] = withUnsafeBytes(of: &headerValLen, Array.init)

            resultData.append(headerKeyLen)

            let headerKeyData = Data(key.utf8)
            resultData.append(contentsOf: headerKeyData)

            let headerType: UInt8 = 7
            resultData.append(headerType)
            resultData.append(contentsOf: headerValLenBytes)
            let headerValueData = Data(value.utf8)
            resultData.append(contentsOf: headerValueData)
        }

        resultData.append(contentsOf: chunk)
        let resultDataBytes = [UInt8](resultData)
        let crcMessage = crc32(0, resultDataBytes, uInt(resultDataBytes.count))
        var crcMessageInt = CFSwapInt32HostToBig(UInt32(crcMessage))

        let crcMessageIntBytes: [UInt8] = withUnsafeBytes(of: &crcMessageInt, Array.init)

        resultData.append(contentsOf: crcMessageIntBytes)
        return resultData
    }

    static func decode<T: Codable>(data: Data, as type: T.Type, nest: Bool = false) throws -> Message {
        assert(data.count >= 16)
        var data = data[...]
        let totalByteLength = try Data(data
            .readBytes(count: 4))
            .withUnsafeBytes { $0.load(as: Int32.self) }
            .byteSwapped
//        data[0...3]

        let headerByteLength = try Data(data
            .readBytes(count: 4))
            .withUnsafeBytes { $0.load(as: Int32.self) }
            .byteSwapped
//        data[0...3]

        let preludeCRC = try Data(data
            .readBytes(count: 4))
            .withUnsafeBytes { $0.load(as: Int32.self) }
            .byteSwapped
        // [8...11]

        let headerBytes = Data(try data.readBytes(count: Int(headerByteLength)))

        let headers = try headers(from: headerBytes)

        let payloadBytes = Data(try data.readBytes(count: data.count - 4))

        let payload: String
        if nest {
            let a = try decode(data: payloadBytes, as: Int.self)
            payload = a.payload
        } else {
            payload = createPayload(from: payloadBytes)
        }

        let messageCRC = Data(data)
            .withUnsafeBytes { $0.load(as: Int32.self) }
            .byteSwapped

        let message = Message(
            totalByteLength: totalByteLength,
            headersByteLength: headerByteLength,
            preludeCRC: preludeCRC,
            headers: headers,
            payload: payload,
            messageCRC: messageCRC
        )

        return message
    }

    private static func createPayload(from data: Data) -> String {
        let payload = String(decoding: data, as: UTF8.self)
        // TODO: decode in to strongly typed object
        return payload
    }

    private static func headers(from data: Data) throws -> [Message.Header] {
        var data = data[...]
        var headers = [Message.Header]()

        while data.count > 0 {
            let nameByteLength = try Int(data.readByte())
            let nameBytes = try data.readBytes(count: nameByteLength)
            let name = String(
                decoding: nameBytes,
                as: UTF8.self
            )

            let valueType = try data.readByte()
            let valueLength: Int16

            if valueType == 7 || valueType == 6 {
                valueLength = try Data(data.readBytes(count: 2))
                    .withUnsafeBytes { $0.load(as: Int16.self) }.byteSwapped
            } else {
                valueLength = Int16(valueType)
            }

            let bytes = Data(try data.readBytes(count: Int(valueLength)))

            let value: Any
            switch valueType {
            case 0:
                value = true
            case 1:
                value = false
            case 2:
                value = bytes.first!
            case 3:
                value = bytes.withUnsafeBytes { $0.load(as: Int16.self) }.byteSwapped
            case 4:
                value = bytes.withUnsafeBytes { $0.load(as: Int32.self) }.byteSwapped
            case 5:
                value = bytes.withUnsafeBytes { $0.load(as: Int64.self) }.byteSwapped
            case 6:
                value = [UInt8](bytes)
            case 7:
                value = String(
                    decoding: bytes,
                    as: UTF8.self
                )
            case 8:
                value = bytes.withUnsafeBytes { $0.load(as: Int64.self) }.byteSwapped
            case 9:
                value = bytes.withUnsafeBytes { $0.load(as: UUID.self) }
            default:
                value = "something went wrong - incorrect value type"
            }

            let v = String(reflecting: value)

            let header = Message.Header(
                nameByteLength: nameByteLength,
                name: name,
                valueType: .init(rawValue: valueType)!,
                valueByteLength: valueLength,
                value: v
            )

            headers.append(header)
        }
        return headers
    }
}

extension EventStreamCoding {
    struct Message: Codable {
        let totalByteLength: Int32
        let headersByteLength: Int32
        let preludeCRC: Int32 // GZIP CRC32
        let headers: [Header]
        let payload: String
        let messageCRC: Int32 // GZIP CRC32
    }
}

extension EventStreamCoding.Message {
    struct Header: Codable {
        let nameByteLength: Int
        let name: String
        let valueType: ValueType
        let valueByteLength: Int16
        let value: String
    }
}

extension EventStreamCoding.Message.Header {
    enum ValueType: UInt8, Codable {
        case `true` = 0
        case `false` = 1
        case byte = 2
        case short = 3
        case integer = 4
        case long = 5
        case byteArray = 6
        case string = 7
        case timestamp = 8
        case uuid = 9
    }
}

extension Data {
    enum ReadByteError: Error {
        case malformed
    }

    @discardableResult
    fileprivate mutating func readByte() throws -> UInt8 {
        guard let first = first else { throw ReadByteError.malformed }
        self.removeFirst()
        return first
    }

    @discardableResult
    fileprivate mutating func readBytes(count: Int) throws -> Data {
        guard self.count >= count else { throw ReadByteError.malformed }
        defer { removeFirst(count) }
        return prefix(count)
    }
}
