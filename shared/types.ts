// OpenAria 通信协议类型定义
// Version: 1.0

export const RPC_VERSION = '2.0';

// ============================================
// 基础协议类型
// ============================================

export interface RPCRequest {
  jsonrpc: typeof RPC_VERSION;
  id: string | number;
  method: string;
  params?: any;
}

export interface RPCResponse {
  jsonrpc: typeof RPC_VERSION;
  id: string | number;
  result?: any;
  error?: RPCError;
}

export interface RPCError {
  code: number;
  message: string;
  data?: any;
}

export interface RPCNotification {
  jsonrpc: typeof RPC_VERSION;
  method: string;
  params: any;
}

// ============================================
// Gateway 相关类型
// ============================================

export interface GatewayConnectParams {
  url: string;
  apiKey?: string;
}

export interface GatewayConnectResult {
  connected: boolean;
  gatewayVersion: string;
  userId?: string;
}

export interface GatewayStatus {
  connected: boolean;
  url?: string;
  latency?: number;
  lastError?: string;
}

// ============================================
// 会话相关类型
// ============================================

export interface Session {
  sessionId: string;
  title: string;
  createdAt: number;
  lastMessageAt?: number;
  messageCount: number;
}

export interface SessionCreateParams {
  title?: string;
}

export interface SessionDeleteParams {
  sessionId: string;
}

// ============================================
// 消息相关类型
// ============================================

export type MessageRole = 'user' | 'assistant' | 'system';
export type MessageStatus = 'sending' | 'sent' | 'error';
export type AttachmentType = 'image' | 'file';

export interface Attachment {
  type: AttachmentType;
  data: string;              // Base64 编码
  filename?: string;
  mimeType?: string;
}

export interface Message {
  messageId: string;
  role: MessageRole;
  content: string;
  attachments?: Attachment[];
  timestamp: number;
  status?: MessageStatus;
}

export interface MessageSendParams {
  sessionId: string;
  content: string;
  attachments?: Attachment[];
}

export interface MessageSendResult {
  messageId: string;
  status: 'sent' | 'pending';
}

export interface MessageListParams {
  sessionId: string;
  limit?: number;
  offset?: number;
}

export interface MessageListResult {
  messages: Message[];
  total: number;
}

// ============================================
// RPC 方法类型映射
// ============================================

export interface RPCMethods {
  // Gateway 方法
  'gateway.connect': {
    params: GatewayConnectParams;
    result: GatewayConnectResult;
  };

  'gateway.disconnect': {
    params?: never;
    result: { disconnected: boolean };
  };

  'gateway.getStatus': {
    params?: never;
    result: GatewayStatus;
  };

  // Session 方法
  'session.create': {
    params?: SessionCreateParams;
    result: Session;
  };

  'session.list': {
    params?: never;
    result: { sessions: Session[] };
  };

  'session.delete': {
    params: SessionDeleteParams;
    result: { deleted: boolean };
  };

  // Message 方法
  'message.send': {
    params: MessageSendParams;
    result: MessageSendResult;
  };

  'message.list': {
    params: MessageListParams;
    result: MessageListResult;
  };
}

// ============================================
// RPC 事件类型映射
// ============================================

export interface RPCEvents {
  // 收到新消息
  'message.received': Message;

  // 流式消息更新
  'message.streaming': {
    sessionId: string;
    messageId: string;
    delta: string;
    done: boolean;
  };

  // Gateway 状态变化
  'gateway.statusChanged': {
    connected: boolean;
    reason?: string;
  };

  // 错误发生
  'error.occurred': {
    code: number;
    message: string;
    context?: any;
  };
}

// ============================================
// 类型辅助工具
// ============================================

// 提取方法参数类型
export type RPCMethodParams<M extends keyof RPCMethods> = RPCMethods[M]['params'];

// 提取方法返回类型
export type RPCMethodResult<M extends keyof RPCMethods> = RPCMethods[M]['result'];

// 提取事件数据类型
export type RPCEventData<E extends keyof RPCEvents> = RPCEvents[E];

// 所有方法名的联合类型
export type RPCMethodName = keyof RPCMethods;

// 所有事件名的联合类型
export type RPCEventName = keyof RPCEvents;
