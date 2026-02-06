//
//  SessionManager.swift
//  openNanos
//
//  会话管理服务
//

import Foundation

class SessionManager {
    // MARK: - Properties

    private var sessions: [String: Session] = [:]

    // MARK: - Public Methods

    func createSession(title: String?) -> Session {
        let sessionId = UUID().uuidString
        let session = Session(
            sessionId: sessionId,
            title: title ?? "New Chat",
            createdAt: currentTimestamp(),
            lastMessageAt: nil,
            messageCount: 0
        )

        sessions[sessionId] = session
        print("Created session: \(sessionId)")

        return session
    }

    func listSessions() -> [Session] {
        return Array(sessions.values).sorted { $0.createdAt > $1.createdAt }
    }

    func deleteSession(id: String) throws -> [String: Bool] {
        guard sessions.removeValue(forKey: id) != nil else {
            throw RPCError(code: -32004, message: "Session not found")
        }

        print("Deleted session: \(id)")
        return ["deleted": true]
    }

    func getSession(id: String) -> Session? {
        return sessions[id]
    }

    func updateSession(id: String, lastMessageAt: Int64) {
        if var session = sessions[id] {
            session = Session(
                sessionId: session.sessionId,
                title: session.title,
                createdAt: session.createdAt,
                lastMessageAt: lastMessageAt,
                messageCount: session.messageCount + 1
            )
            sessions[id] = session
        }
    }

    // MARK: - Private Helpers

    private func currentTimestamp() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
}
