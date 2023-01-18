import AwsCommonRuntimeKit
import CryptoKit
import AWSClientRuntime
import ClientRuntime
import AWSPluginsCore
import Amplify
import Foundation

extension Data {
    public var prettyPrintedJSON: NSString? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .withoutEscapingSlashes]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }

        return prettyPrintedString
    }
}

fileprivate extension URL {
    var hostWithPort: String {
        let value: String
        switch (host, port) {
        case (.some(let h), .some(let p)):
            value = "\(h):\(String(p))"
        case (.some(let h), .none):
            value = h
        case (.none, .some):
            preconditionFailure("port shouldn't exist without host")
        case (.none, .none):
            value = ""

        }
        return value
    }
}

public struct Signer {
    public let credential: Credential
    let name: String
    let region: String

    public init(
        credential: Credential,
        name: String,
        region: String
    ) {
        self.credential = credential
        self.name = name
        self.region = region
        print("SIGNER CREDENTIALS: ", credential, name, region)
    }

    public func signURL(
        url: URL,
        method: String = "GET",
        body: BodyHashing? = nil,
        date: Date = .init(),
        expires: Int = 299
    ) -> URL {
        let hostHeader = ["host": "\(url.hostWithPort)"]
        let timestamp = Signer.timeStampDateFormatter().string(from: date)
        var signingData = SigningData(
            url: url,
            method: method,
            body: body,
            timestamp: timestamp,
            headers: hostHeader
        )

        let query = buildQuery(url, signingData: &signingData, expires: expires)

        let signedURL = URL(
            string: url.absoluteString.split(
                separator: "?"
            )[0] + "?" + query
        )!
        return signedURL
    }

    private func stringToSign(signingData: SigningData) -> Data {
        let stringToSign = "AWS4-HMAC-SHA256\n"
        + "\(signingData.timestamp)\n"
        + "\(signingData.date)/\(region)/\(name)/aws4_request\n"
        + SHA256.hash(data: canonicalRequest(signingData: signingData)).hexDigest()
        return Data(stringToSign.utf8)
    }

    private func canonicalRequest(signingData: SigningData) -> Data {
        let canonicalHeaders = signingData.headersToSign
            .map {
                "\($0.key.lowercased()):\($0.value.trimmingCharacters(in: .whitespaces))"
            }
            .sorted()
            .joined(separator: "\n")

        let canonicalRequest = "\(signingData.method)\n"
        + "\(percentEncode(signingData.unsignedURL.path, rule: .uriWithSlash))\n"
        + "\(signingData.unsignedURL.query ?? "")\n"
        + "\(canonicalHeaders)\n\n"
        + "\(signingData.signedHeaders)\n"
        + signingData.hashedPayload
        return Data(canonicalRequest.utf8)
    }

    private func sign(with signingData: SigningData, credentials: Credential) -> String {
        func data(_ s: String) -> Data { .init(s.utf8) }
        func hash<D: ContiguousBytes>(data: Data, key: D) -> HashedAuthenticationCode<SHA256> {
            HMAC<SHA256>.authenticationCode(
                for: data,
                using: SymmetricKey(data: key)
            )
        }

        let date = hash(
            data: data(signingData.date),
            key: Data("AWS4\(credentials.secretKey)".utf8)
        )
        let region = hash(data: data(region), key: date)
        let service = hash(data: data(name), key: region)
        let request = hash(data: data("aws4_request"), key: service)
        let signature = hash(data: stringToSign(signingData: signingData), key: request)
        let s = signature.hexDigest()

        if Self.priorSignature.isEmpty {
            Self.priorSignature = s
        }

        return s
    }

    private func _sign(
        region: String,
        secretKey: String,
        date: String,
        stringToSign: String
    ) -> String {
        func data(_ s: String) -> Data { .init(s.utf8) }
        func hash<D: ContiguousBytes>(data: Data, key: D) -> HashedAuthenticationCode<SHA256> {
            HMAC<SHA256>.authenticationCode(
                for: data,
                using: SymmetricKey(data: key)
            )
        }

        let date = hash(
            data: data(date),
            key: Data("AWS4\(secretKey)".utf8)
        )
        let region = hash(data: data(region), key: date)
        let service = hash(data: data(name), key: region)
        let requestType = hash(data: data("aws4_request"), key: service)
        let signature = hash(data: data(stringToSign), key: requestType)
        let s = signature.hexDigest()
        return s
    }

    private func buildQuery(
        _ url: URL,
        signingData: inout SigningData,
        expires: Int
    ) -> String {
        var query = url.query ?? ""
        if query.count > 0 { query += "&" }

        query += "X-Amz-Algorithm=AWS4-HMAC-SHA256"
        query += "&X-Amz-Credential=\(credential.accessKey)/\(signingData.date)/\(region)/\(name)/aws4_request"
        query += "&X-Amz-Date=\(signingData.timestamp)"
        query += "&X-Amz-Expires=\(expires)"
        query += "&X-Amz-SignedHeaders=\(signingData.signedHeaders)"
        query += "&X-Amz-Security-Token=\(percentEncode(credential.sessionToken, rule: .uri))"

        query = query.split(separator: "&")
            .sorted()
            .joined(separator: "&")

        query = percentEncode(query, rule: .query)

        signingData.unsignedURL = URL(
            string: url.absoluteString.split(separator: "?")[0] + "?" + query
        )! // TODO: Gracefully handle

        query += "&X-Amz-Signature=\(sign(with: signingData, credentials: credential))"
        return query
    }

    private func percentEncode(_ string: String, rule: PercentEncoding) -> String {
        string.addingPercentEncoding(
            withAllowedCharacters: rule.allowedCharacters
        ) ?? string
    }

    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    func data(_ s: String) -> Data { .init(s.utf8) }
    func hash<D: ContiguousBytes>(data: Data, key: D) -> HashedAuthenticationCode<SHA256> {
        HMAC<SHA256>.authenticationCode(
            for: data,
            using: SymmetricKey(data: key)
        )
    }

    func createSignature(
        region: String,
        secretKey: String,
        date: String
    ) -> Data {
        let secret = Data("AWS4\(secretKey)".utf8)
        let date = hash(data: data(date), key: secret)
        let region = hash(data: data(region), key: date)
        let service = hash(data: data(name), key: region)
        let requestType = hash(data: data("aws4_request"), key: service)
        return Data(requestType)
    }

    public func getSignedFrame(
        region: String,
        frame: Data,
//        secretKey: String,
        dateHeader: (key: String, value: Date)
    ) -> Data {
        print("Prior Signature: ", Self.priorSignature)
//        print("FRAME DATA: ", frame.map { $0 })
        print("FRAME DATA COUNT: ", frame.count)
//        print("FRAME DATA PRETTY: ", frame.prettyPrintedJSON as Any)
        let timestamp = timeFormatter.string(from: dateHeader.value)
        let datestamp = dateFormatter.string(from: dateHeader.value)
        let credentialScope = credentialScope(region: region, date: datestamp)
        let stringToSign = signStringWithPreviousSignature(
            datetime: timestamp,
            credentialScope: credentialScope,
            payload: frame,
            dateHeader: dateHeader
        )
        print("String to sign: ", stringToSign)
        let signatureKey = createSignature(
            region: region,
            secretKey: credential.secretKey,
            date: datestamp
        )
        let signature = Data(hash(data: data(stringToSign), key: signatureKey))
        let s = signature.hexDigest()
//        let signature = _sign(
//            region: region,
//            secretKey: secretKey,
//            date: datestamp,
//            stringToSign: stringToSign
//        )

//        let signature = HMAC<SHA256>.authenticationCode(
//            for: Data(stringToSign.utf8),
//            using: .init(data: signatureKey)
//        )
//        let signatureString = String(decoding: Data(signature), as: UTF8.self)
        print("Signature string: ", s)
        Self.priorSignature = s
        return signature
    }

    private static var priorSignature = ""

    func signStringWithPreviousSignature(
        datetime: String,
        credentialScope: String,
        payload: Data,
        dateHeader: (key: String, value: Date)
    ) -> String {
        let hashedPayload = SHA256.hash(data: payload).hexDigest()
        let encodedDateHeader = encodeDateHeader(dateHeader)
        let hashedDateHeader = SHA256.hash(data: encodedDateHeader).hexDigest()
        let stringToSign = [
            "AWS4-HMAC-SHA256-PAYLOAD",
            datetime,
            credentialScope,
            Self.priorSignature,
            hashedDateHeader,
            hashedPayload
        ]
            .joined(separator: "\n")

        return stringToSign
    }

    private func encodeDateHeader(_ dateHeader: (key: String, value: Date)) -> Data {
        let headerNameLength = UInt8(Data(dateHeader.key.utf8).count)
        let headerValueType = UInt8(8)
        var headerValue = UInt64(dateHeader.value.timeIntervalSince1970 * 1_000).byteSwapped
        let headerValueBytes: [UInt8] = withUnsafeBytes(of: &headerValue, Array.init)
        let headerKey = Data(dateHeader.key.utf8)

        var data = Data()
        data.append(headerNameLength)
        data.append(contentsOf: headerKey)
        data.append(headerValueType)
        data.append(contentsOf: headerValueBytes)
        return data
    }

    func credentialScope(region: String, date: String) -> String {
        [date, region, name, "aws4_request"].joined(separator: "/")
    }
}

extension Signer {
    struct SigningData {
        let url: URL
        let method: String
        let hashedPayload: String
        let timestamp: String
        let headersToSign: [String: String]
        let signedHeaders: String
        var unsignedURL: URL
        var date: String { .init(timestamp.prefix(8)) }

        init(
            url: URL,
            method: String,
            body: BodyHashing?,
            timestamp: String,
            headers: [String : String]
        ) {
            self.url = url.path.isEmpty
            ? url.appendingPathComponent("/")
            : url

            self.method = method
            self.timestamp = timestamp
            unsignedURL = self.url

            hashedPayload = Signer.hashedPayload(body)

            headersToSign = headers.filter {
                $0.key != "Authorization"
            }

            self.signedHeaders = headersToSign.keys
                .map { $0.lowercased() }
                .sorted()
                .joined(separator: ";")
        }
    }
}

extension Signer {
    public struct BodyHashing {
        let input: Data
        let hash: (Data) -> String

        static func string(_ string: String) -> BodyHashing {
            .init(
                input: Data(string.utf8),
                hash: { data in
                    SHA256.hash(data: data).hexDigest()
                }
            )
        }

        static func data(_ data: Data) -> BodyHashing {
            .init(
                input: data,
                hash: { data in
                    SHA256.hash(data: data).hexDigest()
                }
            )
        }
    }
}

extension Signer {
    struct PercentEncoding {
        let allowedCharacters: CharacterSet
        func encode(_ string: String) -> String {
            string.addingPercentEncoding(
                withAllowedCharacters: allowedCharacters
            ) ?? string
        }

        static let query = PercentEncoding(
            allowedCharacters: CharacterSet(charactersIn:"/;+").inverted
        )

        static let uri = PercentEncoding(
            allowedCharacters: CharacterSet(
                charactersIn:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
            )
        )

        static let uriWithSlash = PercentEncoding(
            allowedCharacters: CharacterSet(
                charactersIn:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~/"
            )
        )
    }
}

extension Signer {
    public struct Credential {
        let accessKey: String
        public let secretKey: String
        let sessionToken: String

        public init(accessKey: String, secretKey: String, sessionToken: String) {
            self.accessKey = accessKey
            self.secretKey = secretKey
            self.sessionToken = sessionToken
        }
    }
}

extension Signer {
    public enum BodyData {
        case string(String)
        case data(Data)
        case byteBuffer(ByteBuffer)
    }
}

extension Signer {
    static let hashedEmptyBody = SHA256.hash(data: [UInt8]()).hexDigest()

    static func hashedPayload(_ payload: BodyHashing?) -> String {
        guard let payload else { return hashedEmptyBody }
        let hash = payload.hash(payload.input)
        return hash
    }

    static private func timeStampDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
}

extension Sequence where Element == UInt8 {
    func hexDigest() -> String {
        map { String(format: "%02x", $0) }.joined()
    }
}
