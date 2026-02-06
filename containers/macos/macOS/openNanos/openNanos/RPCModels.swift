//
//  RPCModels.swift
//  openNanos
//
//  RPC 协议数据模型
//

import Foundation

// MARK: - 基础协议

struct RPCRequest: Codable {
    let jsonrpc: String
    let id: RequestID
    let method: String
    let params: AnyCodable?

    enum RequestID: Codable {
        case string(String)
        case number(Int)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self = .string(string)
            } else if let number = try? container.decode(Int.self) {
                self = .number(number)
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "ID must be string or number"
                    )
                )
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .number(let value):
                try container.encode(value)
            }
        }
    }
}

struct RPCResponse: Codable {
    let jsonrpc: String
    let id: RPCRequest.RequestID
    let result: AnyCodable?
    let error: RPCError?

    init(id: RPCRequest.RequestID, result: Codable) {
        self.jsonrpc = "2.0"
        self.id = id
        self.result = AnyCodable(result)
        self.error = nil
    }

    init(id: RPCRequest.RequestID, error: RPCError) {
        self.jsonrpc = "2.0"
        self.id = id
        self.result = nil
        self.error = error
    }
}

struct RPCError: Codable, Error {
    let code: Int
    let message: String
    let data: AnyCodable?

    init(code: Int, message: String, data: Codable? = nil) {
        self.code = code
        self.message = message
        self.data = data.map { AnyCodable($0) }
    }
}

struct RPCNotification: Codable {
    let jsonrpc: String
    let method: String
    let params: AnyCodable

    init(method: String, params: Codable) {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = AnyCodable(params)
    }
}

// MARK: - AnyCodable 辅助类型

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported type"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Unsupported type: \(type(of: value))"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}

// MARK: - Gateway 相关模型

struct GatewayConnectParams: Codable {
    let url: String
    let apiKey: String?
}

struct GatewayConnectResult: Codable {
    let connected: Bool
    let gatewayVersion: String
    let userId: String?
}

struct GatewayStatus: Codable {
    let connected: Bool
    let url: String?
    let latency: Int?
    let lastError: String?
}

// MARK: - Session 相关模型

struct Session: Codable {
    let sessionId: String
    let title: String
    let createdAt: Int64
    let lastMessageAt: Int64?
    let messageCount: Int
}

struct SessionCreateParams: Codable {
    let title: String?
}

// MARK: - Message 相关模型

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

enum MessageStatus: String, Codable {
    case sending
    case sent
    case error
}

struct Attachment: Codable {
    let type: String  // "image" | "file"
    let data: String  // Base64
    let filename: String?
    let mimeType: String?
}

struct Message: Codable {
    let messageId: String
    let role: MessageRole
    let content: String
    let attachments: [Attachment]?
    let timestamp: Int64
    let status: MessageStatus?
}

struct MessageSendParams: Codable {
    let sessionId: String
    let content: String
    let attachments: [Attachment]?
}

struct MessageSendResult: Codable {
    let messageId: String
    let status: String  // "sent" | "pending"
}

struct MessageListParams: Codable {
    let sessionId: String
    let limit: Int?
    let offset: Int?
}

struct MessageListResult: Codable {
    let messages: [Message]
    let total: Int
}

// MARK: - Event 相关模型

struct MessageStreamingEvent: Codable {
    let sessionId: String
    let messageId: String
    let delta: String
    let done: Bool
}

struct GatewayStatusChangedEvent: Codable {
    let connected: Bool
    let reason: String?
}

struct ErrorOccurredEvent: Codable {
    let code: Int
    let message: String
    let context: AnyCodable?
}
