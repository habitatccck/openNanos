//
//  RPCHandler.swift
//  openNanos
//
//  RPC 请求路由和处理
//

import Foundation

class RPCHandler {
    // MARK: - Services

    private let gatewayManager: GatewayManager
    private let sessionManager: SessionManager
    private let messageService: MessageService

    // MARK: - Initialization

    init() {
        self.gatewayManager = GatewayManager()
        self.sessionManager = SessionManager()
        self.messageService = MessageService(gatewayManager: gatewayManager)
    }

    // MARK: - Public Methods

    func handle(_ request: RPCRequest) async -> RPCResponse {
        do {
            let result = try await routeMethod(request.method, params: request.params)
            return RPCResponse(id: request.id, result: result)
        } catch let error as RPCError {
            return RPCResponse(id: request.id, error: error)
        } catch {
            return RPCResponse(
                id: request.id,
                error: RPCError(code: -32603, message: "Internal error: \(error.localizedDescription)")
            )
        }
    }

    // MARK: - Private Methods

    private func routeMethod(_ method: String, params: AnyCodable?) async throws -> Codable {
        switch method {
        // Gateway methods
        case "gateway.connect":
            let connectParams = try decode(GatewayConnectParams.self, from: params)
            return try await gatewayManager.connect(url: connectParams.url, apiKey: connectParams.apiKey)

        case "gateway.disconnect":
            return try await gatewayManager.disconnect()

        case "gateway.getStatus":
            return gatewayManager.getStatus()

        // Session methods
        case "session.create":
            let createParams = try? decode(SessionCreateParams.self, from: params)
            return sessionManager.createSession(title: createParams?.title)

        case "session.list":
            return ["sessions": sessionManager.listSessions()]

        case "session.delete":
            let sessionId = try decodeString(from: params, key: "sessionId")
            return try sessionManager.deleteSession(id: sessionId)

        // Message methods
        case "message.send":
            let sendParams = try decode(MessageSendParams.self, from: params)
            return try await messageService.sendMessage(params: sendParams)

        case "message.list":
            let listParams = try decode(MessageListParams.self, from: params)
            return messageService.listMessages(sessionId: listParams.sessionId, limit: listParams.limit, offset: listParams.offset)

        default:
            throw RPCError(code: -32601, message: "Method not found: \(method)")
        }
    }

    // MARK: - Decoding Helpers

    private func decode<T: Decodable>(_ type: T.Type, from params: AnyCodable?) throws -> T {
        guard let params = params else {
            throw RPCError(code: -32602, message: "Missing params")
        }

        let data = try JSONSerialization.data(withJSONObject: params.value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func decodeString(from params: AnyCodable?, key: String) throws -> String {
        guard let params = params,
              let dict = params.value as? [String: Any],
              let value = dict[key] as? String
        else {
            throw RPCError(code: -32602, message: "Missing or invalid parameter: \(key)")
        }
        return value
    }
}
