//
//  MessageService.swift
//  OpenAria
//
//  消息发送和管理服务
//

import Foundation

class MessageService {
    // MARK: - Properties

    private let gatewayManager: GatewayManager
    private var messages: [String: [Message]] = [:]  // sessionId -> messages

    // MARK: - Initialization

    init(gatewayManager: GatewayManager) {
        self.gatewayManager = gatewayManager
    }

    // MARK: - Public Methods

    func sendMessage(params: MessageSendParams) async throws -> MessageSendResult {
        let messageId = UUID().uuidString

        // 创建消息对象
        let message = Message(
            messageId: messageId,
            role: .user,
            content: params.content,
            attachments: params.attachments,
            timestamp: currentTimestamp(),
            status: .sending
        )

        // 保存到本地
        addMessage(message, to: params.sessionId)

        // 发送到 Gateway
        do {
            try await gatewayManager.sendMessage(
                content: params.content,
                sessionId: params.sessionId
            )

            // 更新状态为已发送
            updateMessageStatus(messageId, in: params.sessionId, status: .sent)

            return MessageSendResult(messageId: messageId, status: "sent")
        } catch {
            // 更新状态为错误
            updateMessageStatus(messageId, in: params.sessionId, status: .error)
            throw error
        }
    }

    func listMessages(sessionId: String, limit: Int?, offset: Int?) -> MessageListResult {
        let sessionMessages = messages[sessionId] ?? []
        let limit = limit ?? 50
        let offset = offset ?? 0

        let start = min(offset, sessionMessages.count)
        let end = min(start + limit, sessionMessages.count)

        let paginatedMessages = Array(sessionMessages[start..<end])

        return MessageListResult(
            messages: paginatedMessages,
            total: sessionMessages.count
        )
    }

    func addReceivedMessage(_ message: Message, to sessionId: String) {
        addMessage(message, to: sessionId)
    }

    // MARK: - Private Methods

    private func addMessage(_ message: Message, to sessionId: String) {
        if messages[sessionId] == nil {
            messages[sessionId] = []
        }
        messages[sessionId]?.append(message)
    }

    private func updateMessageStatus(_ messageId: String, in sessionId: String, status: MessageStatus) {
        guard var sessionMessages = messages[sessionId] else { return }

        if let index = sessionMessages.firstIndex(where: { $0.messageId == messageId }) {
            var message = sessionMessages[index]
            message = Message(
                messageId: message.messageId,
                role: message.role,
                content: message.content,
                attachments: message.attachments,
                timestamp: message.timestamp,
                status: status
            )
            sessionMessages[index] = message
            messages[sessionId] = sessionMessages
        }
    }

    private func currentTimestamp() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
}
