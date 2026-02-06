// JSON-RPC 2.0 Types
export interface RPCRequest {
  jsonrpc: '2.0';
  id: string | number;
  method: string;
  params?: any;
}

export interface RPCResponse {
  jsonrpc: '2.0';
  id: string | number;
  result?: any;
  error?: RPCError;
}

export interface RPCError {
  code: number;
  message: string;
  data?: any;
}

export interface Message {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: number;
  status?: 'sending' | 'sent' | 'error';
}

export interface Session {
  sessionId: string;
  title: string;
  createdAt: number;
  lastMessageAt?: number;
  messageCount: number;
}
