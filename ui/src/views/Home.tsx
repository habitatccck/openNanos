import React, { useState, useEffect, useRef } from 'react';
import { AppLayout } from '../components/Layout/AppLayout';
import { Sidebar } from '../components/Sidebar/Sidebar';
import { WidgetSidebar } from '../components/Widgets/WidgetSidebar';
import { MessageList } from '../components/Chat/MessageList';
import { ChatInput } from '../components/Chat/ChatInput';
import { nativeBridge } from '../services/nativeBridge';
import type { Message } from '../components/Chat/MessageBubble';
import '../components/Chat/ChatArea.css';

export const Home: React.FC = () => {
  const [activeTab, setActiveTab] = useState('Chat');
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
      setStreamingContent((prev) => prev + data.content);
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

  const handleSendMessage = async (content: string) => {
    if (!content.trim() || isLoading) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content,
      timestamp: Date.now(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInputValue('');
    setIsLoading(true);
    setStreamingContent('');

    try {
      // 通过 Native Bridge 发送消息到 OpenClaw
      await nativeBridge.sendMessage(content);

      // 等待流式输出完成
      setTimeout(() => {
        if (streamingContent) {
          const assistantMessage: Message = {
            id: (Date.now() + 1).toString(),
            role: 'assistant',
            content: streamingContent,
            timestamp: Date.now(),
          };

          setMessages((prev) => [...prev, assistantMessage]);
          setStreamingContent('');
        }
        setIsLoading(false);
      }, 1000);
    } catch (error) {
      console.error('Failed to send message:', error);
      setIsLoading(false);
    }
  };

  return (
    <AppLayout>
      <Sidebar activeTab={activeTab} onTabChange={setActiveTab} />

      <main className="chat-area">
        <MessageList messages={messages} />

        {/* 显示正在流式输出的内容 */}
        {streamingContent && (
          <div className="message-bubble-wrapper assistant-message streaming">
            <div className="message-bubble">
              <div className="message-content">{streamingContent}</div>
            </div>
          </div>
        )}

        {/* 加载指示器 */}
        {isLoading && !streamingContent && (
          <div className="message-bubble-wrapper assistant-message">
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

        <ChatInput
          value={inputValue}
          onChange={setInputValue}
          onSend={() => handleSendMessage(inputValue)}
          disabled={isLoading}
        />
      </main>

      <WidgetSidebar />
    </AppLayout>
  );
};
