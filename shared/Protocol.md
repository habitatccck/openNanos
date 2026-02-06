# OpenAria 通信协议 v1.0

## 协议设计

OpenAria 使用 **JSON-RPC 2.0** 作为 UI 层和原生层之间的通信协议。

### 为什么选择 JSON-RPC？

1. ✅ 简单易懂，易于调试
2. ✅ 类型安全（通过 TypeScript）
3. ✅ 标准化协议，工具支持好
4. ✅ 支持批量请求和通知

---

## 基础协议

### 请求格式

```typescript
interface RPCRequest {
  jsonrpc: '2.0';
  id: string | number;        // 请求 ID，用于匹配响应
  method: string;              // 方法名
  params?: any;                // 参数（可选）
}
```

### 响应格式

```typescript
interface RPCResponse {
  jsonrpc: '2.0';
  id: string | number;        // 对应的请求 ID
  result?: any;                // 成功结果
  error?: RPCError;            // 错误信息
}

interface RPCError {
  code: number;                // 错误码
  message: string;             // 错误消息
  data?: any;                  // 附加数据
}
```

### 事件通知（服务端推送）

```typescript
interface RPCNotification {
  jsonrpc: '2.0';
  method: string;              // 事件名称
  params: any;                 // 事件数据
}
```

---

## MVP 方法定义

### 1. Gateway 连接管理

#### `gateway.connect`

连接到 OpenClaw Gateway。

**请求：**
```typescript
{
  jsonrpc: '2.0',
  id: 1,
  method: 'gateway.connect',
  params: {
    url: string;              // Gateway WebSocket URL
    apiKey?: string;          // API Key（可选）
  }
}
```

**响应：**
```typescript
{
  jsonrpc: '2.0',
  id: 1,
  result: {
    connected: true,
    gatewayVersion: string;
    userId?: string;
  }
}
```

**错误码：**
- `-32001`: 连接失败
- `-32002`: 认证失败
- `-32003`: 网络错误

---

#### `gateway.disconnect`

断开与 Gateway 的连接。

**请求：**
```typescript
{
  jsonrpc: '2.0',
  id: 2,
  method: 'gateway.disconnect'
}
```

**响应：**
```typescript
{
  jsonrpc: '2.0',
  id: 2,
  result: {
    disconnected: true
  }
}
```

---

#### `gateway.getStatus`

获取 Gateway 连接状态。

**请求：**
```typescript
{
  jsonrpc: '2.0',
  id: 3,
  method: 'gateway.getStatus'
}
```

**响应：**
```typescript
{
  jsonrpc: '2.0',
  id: 3,
  result: {
    connected: boolean;
    url?: string;
    latency?: number;         // 毫秒
    lastError?: string;
  }
}
```

---

### 2. 会话管理

#### `session.create`

创建新的聊天会话。

**请求：**
```typescript
{
  jsonrpc: '2.0',
  id: 4,
  method: 'session.create',
  params: {
    title?: string;           // 会话标题（可选）
  }
}
```

**响应：**
```typescript
{
  jsonrpc: '2.0',
  id: 4,
  result: {
    sessionId: string;
    title: string;
    createdAt: number;        // Unix timestamp (ms)
  }
}
```

---

#### `session.list`

获取所有会话列表。

**请求：**
```typescript
{
  jsonrpc: '2.0',
  id: 5,
  method: 'session.list'
}
```

**响应：**
```typescript
{
  jsonrpc: '2.0',
  id: 5,
  result: {
    sessions: Array<{
      sessionId: string;
      title: string;
      createdAt: number;
      lastMessageAt?: number;
      messageCount: number;
    }>
  }
}
```

---

#### `session.delete`

删除会话。

**请求：**
```typescript
{
  jsonrpc: '2.0',
  id: 6,
  method: 'session.delete',
  params: {
    sessionId: string;
  }
}
```

**响应：**
```typescript
{
  jsonrpc: '2.0',
  id: 6,
  result: {
    deleted: true
  }
}
```

---

### 3. 消息发送和接收

#### `message.send`

发送消息到 OpenClaw。

**请求：**
```typescript
{
  jsonrpc: '2.0',
  id: 7,
  method: 'message.send',
  params: {
    sessionId: string;
    content: string;
    attachments?: Array<{
      type: 'image' | 'file';
      data: string;           // Base64 编码
      filename?: string;
      mimeType?: string;
    }>;
  }
}
```

**响应：**
```typescript
{
  jsonrpc: '2.0',
  id: 7,
  result: {
    messageId: string;
    status: 'sent' | 'pending';
  }
}
```

---

#### `message.list`

获取会话的消息列表。

**请求：**
```typescript
{
  jsonrpc: '2.0',
  id: 8,
  method: 'message.list',
  params: {
    sessionId: string;
    limit?: number;           // 默认 50
    offset?: number;          // 默认 0
  }
}
```

**响应：**
```typescript
{
  jsonrpc: '2.0',
  id: 8,
  result: {
    messages: Array<{
      messageId: string;
      role: 'user' | 'assistant' | 'system';
      content: string;
      attachments?: Array<Attachment>;
      timestamp: number;
      status?: 'sending' | 'sent' | 'error';
    }>;
    total: number;
  }
}
```

---

### 4. 事件通知（服务端推送）

#### `message.received`

收到来自 OpenClaw 的消息。

**通知：**
```typescript
{
  jsonrpc: '2.0',
  method: 'message.received',
  params: {
    sessionId: string;
    messageId: string;
    role: 'assistant';
    content: string;
    timestamp: number;
  }
}
```

---

#### `message.streaming`

流式消息推送（AI 生成内容）。

**通知：**
```typescript
{
  jsonrpc: '2.0',
  method: 'message.streaming',
  params: {
    sessionId: string;
    messageId: string;
    delta: string;            // 增量内容
    done: boolean;            // 是否完成
  }
}
```

---

#### `gateway.statusChanged`

Gateway 连接状态变化。

**通知：**
```typescript
{
  jsonrpc: '2.0',
  method: 'gateway.statusChanged',
  params: {
    connected: boolean;
    reason?: string;
  }
}
```

---

#### `error.occurred`

发生错误。

**通知：**
```typescript
{
  jsonrpc: '2.0',
  method: 'error.occurred',
  params: {
    code: number;
    message: string;
    context?: any;
  }
}
```

---

## 错误码规范

| 错误码范围 | 含义 |
|-----------|------|
| -32700 | 解析错误（JSON 格式错误） |
| -32600 | 无效请求 |
| -32601 | 方法不存在 |
| -32602 | 无效参数 |
| -32603 | 内部错误 |
| -32000 ~ -32099 | 服务器自定义错误 |
| -32001 | Gateway 连接失败 |
| -32002 | 认证失败 |
| -32003 | 网络错误 |
| -32004 | 会话不存在 |
| -32005 | 消息发送失败 |

---

## TypeScript 类型定义

完整的类型定义将放在 `Shared/Protocol/types.ts` 中，供 UI 和原生层共同使用。

```typescript
// Shared/Protocol/types.ts

export const RPC_VERSION = '2.0';

// 基础协议
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

// Gateway 相关
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

// 会话相关
export interface Session {
  sessionId: string;
  title: string;
  createdAt: number;
  lastMessageAt?: number;
  messageCount: number;
}

// 消息相关
export interface Message {
  messageId: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  attachments?: Attachment[];
  timestamp: number;
  status?: 'sending' | 'sent' | 'error';
}

export interface Attachment {
  type: 'image' | 'file';
  data: string;
  filename?: string;
  mimeType?: string;
}

export interface MessageSendParams {
  sessionId: string;
  content: string;
  attachments?: Attachment[];
}

export interface MessageListParams {
  sessionId: string;
  limit?: number;
  offset?: number;
}

// 方法签名映射
export interface RPCMethods {
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

  'session.create': {
    params?: { title?: string };
    result: Session;
  };

  'session.list': {
    params?: never;
    result: { sessions: Session[] };
  };

  'session.delete': {
    params: { sessionId: string };
    result: { deleted: boolean };
  };

  'message.send': {
    params: MessageSendParams;
    result: { messageId: string; status: 'sent' | 'pending' };
  };

  'message.list': {
    params: MessageListParams;
    result: { messages: Message[]; total: number };
  };
}

// 事件类型
export interface RPCEvents {
  'message.received': Message;
  'message.streaming': {
    sessionId: string;
    messageId: string;
    delta: string;
    done: boolean;
  };
  'gateway.statusChanged': {
    connected: boolean;
    reason?: string;
  };
  'error.occurred': {
    code: number;
    message: string;
    context?: any;
  };
}
```

---

## 使用示例

### UI 层调用

```typescript
import { nativeBridge } from '@/bridge';

// 连接 Gateway
const result = await nativeBridge.invoke('gateway.connect', {
  url: 'ws://localhost:8080/gateway'
});

// 发送消息
const { messageId } = await nativeBridge.invoke('message.send', {
  sessionId: 'session-123',
  content: 'Hello, OpenClaw!'
});

// 监听事件
nativeBridge.on('message.received', (message) => {
  console.log('New message:', message);
});
```

### 原生层处理

```swift
// Swift
func handleRequest(_ request: RPCRequest) async -> RPCResponse {
    switch request.method {
    case "gateway.connect":
        let params = try decode(GatewayConnectParams.self, from: request.params)
        let result = try await gatewayManager.connect(url: params.url, apiKey: params.apiKey)
        return RPCResponse(id: request.id, result: result)

    case "message.send":
        let params = try decode(MessageSendParams.self, from: request.params)
        let result = try await messageService.send(params)
        return RPCResponse(id: request.id, result: result)

    default:
        return RPCResponse(id: request.id, error: RPCError(
            code: -32601,
            message: "Method not found: \(request.method)"
        ))
    }
}
```

---

**文档版本**: v1.0
**创建日期**: 2026-02-06
