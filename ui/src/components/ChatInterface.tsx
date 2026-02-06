import { useState, useEffect, useRef } from 'react';
import { nativeBridge } from '../services/nativeBridge';
import type { Message } from '../types/rpc';
import './Chat.css';

export function ChatInterface() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [streamingContent, setStreamingContent] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, streamingContent]);

  useEffect(() => {
    // 监听 OpenClaw 的流式输出
    const handleChunk = (data: { content: string }) => {
      console.log('📥 Received chunk:', data.content);
      setStreamingContent(prev => prev + data.content);
    };

    const handleConnected = () => {
      console.log('✅ Connected to OpenClaw Gateway');
    };

    const handleDisconnected = () => {
      console.log('⚠️ Disconnected from OpenClaw Gateway');
    };

    const handleError = (data: { error: string }) => {
      console.error('❌ OpenClaw error:', data.error);
      setIsLoading(false);
    };

    // 注册事件监听
    nativeBridge.on('openclaw.message.chunk', handleChunk);
    nativeBridge.on('openclaw.connected', handleConnected);
    nativeBridge.on('openclaw.disconnected', handleDisconnected);
    nativeBridge.on('openclaw.error', handleError);

    // 清理监听器
    return () => {
      nativeBridge.off('openclaw.message.chunk', handleChunk);
      nativeBridge.off('openclaw.connected', handleConnected);
      nativeBridge.off('openclaw.disconnected', handleDisconnected);
      nativeBridge.off('openclaw.error', handleError);
    };
  }, []);

  const sendMessage = async () => {
    if (!inputValue.trim() || isLoading) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: inputValue,
      timestamp: Date.now(),
      status: 'sending'
    };

    setMessages(prev => [...prev, userMessage]);
    setInputValue('');
    setIsLoading(true);
    setStreamingContent('');

    try {
      // 通过 Native Bridge 发送消息到 OpenClaw
      await nativeBridge.sendMessage(inputValue);

      // 更新用户消息状态
      setMessages(prev => prev.map(msg =>
        msg.id === userMessage.id ? { ...msg, status: 'sent' } : msg
      ));

      // 等待流式输出完成（这里设置一个超时）
      // 实际应该监听 'openclaw.reply.end' 事件
      setTimeout(() => {
        if (streamingContent) {
          const assistantMessage: Message = {
            id: (Date.now() + 1).toString(),
            role: 'assistant',
            content: streamingContent,
            timestamp: Date.now(),
            status: 'sent'
          };

          setMessages(prev => [...prev, assistantMessage]);
          setStreamingContent('');
        }
        setIsLoading(false);
      }, 1000);

    } catch (error) {
      console.error('Failed to send message:', error);
      setMessages(prev => prev.map(msg =>
        msg.id === userMessage.id ? { ...msg, status: 'error' } : msg
      ));
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  return (
    <div className="chat-container">
      <div className="chat-header">
        <div className="chat-title">OpenAria</div>
        <div className="chat-status">
          <span className="status-dot"></span>
          <span className="status-text">在线</span>
        </div>
      </div>

      <div className="messages-container">
        {messages.length === 0 && (
          <div className="empty-state">
            <div className="empty-icon">💬</div>
            <div className="empty-text">开始对话</div>
            <div className="empty-hint">向 OpenAria 提问或发送消息</div>
          </div>
        )}

        {messages.map((message) => (
          <div
            key={message.id}
            className={`message-wrapper ${message.role === 'user' ? 'user-message' : 'assistant-message'}`}
          >
            <div className="message-bubble">
              <div className="message-content">{message.content}</div>
              <div className="message-time">
                {new Date(message.timestamp).toLocaleTimeString('zh-CN', {
                  hour: '2-digit',
                  minute: '2-digit'
                })}
              </div>
            </div>
          </div>
        ))}

        {/* 显示正在流式输出的内容 */}
        {streamingContent && (
          <div className="message-wrapper assistant-message">
            <div className="message-bubble">
              <div className="message-content">{streamingContent}</div>
              <div className="message-time">正在输入...</div>
            </div>
          </div>
        )}

        {/* 加载指示器 */}
        {isLoading && !streamingContent && (
          <div className="message-wrapper assistant-message">
            <div className="message-bubble loading">
              <div className="typing-indicator">
                <span></span>
                <span></span>
                <span></span>
              </div>
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      <div className="input-container">
        <textarea
          className="message-input"
          placeholder="输入消息..."
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onKeyPress={handleKeyPress}
          rows={1}
          disabled={isLoading}
        />
        <button
          className="send-button"
          onClick={sendMessage}
          disabled={!inputValue.trim() || isLoading}
        >
          <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <line x1="22" y1="2" x2="11" y2="13"></line>
            <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
          </svg>
        </button>
      </div>
    </div>
  );
}
