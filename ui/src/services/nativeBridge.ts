import type { RPCRequest, RPCResponse } from '../types/rpc';

class NativeBridge {
  private requestId = 0;
  private pendingRequests = new Map<number, {
    resolve: (result: any) => void;
    reject: (error: any) => void;
  }>();

  // 事件监听器
  private eventListeners = new Map<string, Set<(data: any) => void>>();

  constructor() {
    // 监听来自 Native 的消息
    if (typeof window !== 'undefined') {
      window.addEventListener('message', this.handleMessage.bind(this));
    }
  }

  // 监听事件
  on(event: string, callback: (data: any) => void) {
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, new Set());
    }
    this.eventListeners.get(event)!.add(callback);
  }

  // 移除事件监听
  off(event: string, callback: (data: any) => void) {
    const listeners = this.eventListeners.get(event);
    if (listeners) {
      listeners.delete(callback);
    }
  }

  // 触发事件
  private emit(event: string, data: any) {
    const listeners = this.eventListeners.get(event);
    if (listeners) {
      listeners.forEach(callback => callback(data));
    }
  }

  private handleMessage(event: MessageEvent) {
    try {
      let data: any;

      // 处理字符串类型的 data
      if (typeof event.data === 'string') {
        data = JSON.parse(event.data);
      } else {
        data = event.data;
      }

      // 处理 RPC 响应
      if (data.jsonrpc === '2.0' && data.id !== undefined) {
        const pending = this.pendingRequests.get(data.id as number);
        if (pending) {
          this.pendingRequests.delete(data.id as number);

          if (data.error) {
            pending.reject(new Error(data.error.message));
          } else {
            pending.resolve(data.result);
          }
        }
        return;
      }

      // 处理事件通知
      if (data.type) {
        console.log(`📥 Event received: ${data.type}`, data.data);
        this.emit(data.type, data.data);
      }
    } catch (error) {
      console.error('Failed to handle message from native:', error);
    }
  }

  async invoke<T = any>(method: string, params?: any): Promise<T> {
    const id = ++this.requestId;

    const request: RPCRequest = {
      jsonrpc: '2.0',
      id,
      method,
      params,
    };

    return new Promise((resolve, reject) => {
      this.pendingRequests.set(id, { resolve, reject });

      // 发送到 Native
      if (typeof window !== 'undefined' && (window as any).webkit) {
        try {
          (window as any).webkit.messageHandlers.nativeBridge.postMessage(request);
        } catch (error) {
          this.pendingRequests.delete(id);
          reject(new Error('Failed to send message to native bridge'));
        }
      } else {
        // 开发模式：模拟响应
        console.warn('Native bridge not available, using mock response');
        setTimeout(() => {
          this.pendingRequests.delete(id);
          resolve({} as T);
        }, 100);
      }

      // 超时处理
      setTimeout(() => {
        if (this.pendingRequests.has(id)) {
          this.pendingRequests.delete(id);
          reject(new Error('Request timeout'));
        }
      }, 30000);
    });
  }

  // 发送消息到 OpenClaw
  async sendMessage(message: string, sessionId: string = 'agent:main:main'): Promise<void> {
    return this.invoke('sendMessage', { message, sessionId });
  }

  // 连接到 OpenClaw
  async connect(): Promise<void> {
    return this.invoke('connect');
  }

  // 断开连接
  async disconnect(): Promise<void> {
    return this.invoke('disconnect');
  }

  // 获取状态
  async getStatus(): Promise<any> {
    return this.invoke('getStatus');
  }
}

export const nativeBridge = new NativeBridge();
