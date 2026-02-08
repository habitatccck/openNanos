import React, { useState, useEffect, useRef } from 'react';
import { AppLayout } from '../components/Layout/AppLayout';
import { Sidebar } from '../components/Sidebar/Sidebar';
import { WidgetSidebar } from '../components/Widgets/WidgetSidebar';
import { MessageList } from '../components/Chat/MessageList';
import { ChatInput } from '../components/Chat/ChatInput';
import { MarkdownRenderer } from '../components/MarkdownRenderer';
import { nativeBridge } from '../services/nativeBridge';
import type { Message } from '../components/Chat/MessageBubble';
import '../components/Chat/ChatArea.css';

const CURRENT_SESSION_ID = 'agent:main:main';

export const Home: React.FC = () => {
  const [activeTab, setActiveTab] = useState('Chat');
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [streamingContent, setStreamingContent] = useState('');
  const [isHistoryLoaded, setIsHistoryLoaded] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  const streamingMessageIdRef = useRef<string>('');

  const scrollToBottom = () => {
    if (scrollContainerRef.current) {
      scrollContainerRef.current.scrollTop = scrollContainerRef.current.scrollHeight;
    }
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, streamingContent]);

  // 从 OpenClaw 后端加载历史记录（唯一数据源）
  const loadHistoryFromOpenClaw = async () => {
    try {
      console.log('🔄 Loading history from OpenClaw...');
      const history = await nativeBridge.getSessionHistory(CURRENT_SESSION_ID);

      if (history && history.length > 0) {
        // 转换后端格式到前端 Message 格式
        const convertedMessages: Message[] = history
          .filter((item: any) => item.type === 'message' && item.message)
          .map((item: any) => ({
            id: item.id || Date.now().toString(),
            role: item.message.role,
            content: Array.isArray(item.message.content)
              ? item.message.content
                  .filter((c: any) => c.type === 'text')
                  .map((c: any) => c.text)
                  .join('\n')
              : item.message.content,
            timestamp: new Date(item.timestamp).getTime() || item.message.timestamp,
          }));

        // 按时间戳排序（从旧到新）
        convertedMessages.sort((a, b) => a.timestamp - b.timestamp);

        setMessages(convertedMessages);
        console.log('✅ Loaded history from OpenClaw:', convertedMessages.length, 'messages');
      } else {
        console.log('📭 No history found in OpenClaw');
        setMessages([]);
      }
    } catch (error) {
      console.error('❌ Failed to load history from OpenClaw:', error);
      setMessages([]);
    } finally {
      setIsHistoryLoaded(true);
    }
  };

  // 初始化：加载历史记录
  useEffect(() => {
    loadHistoryFromOpenClaw();
  }, []);

  useEffect(() => {
    // 监听 OpenClaw 的流式输出
    const handleChunk = (data: { content: string; messageId?: string }) => {
      console.log('📥 Received chunk:', data.content);
      setStreamingContent((prev) => prev + data.content);
    };

    const handleStreamEnd = (data: { messageId?: string; content?: string }) => {
      console.log('✅ Stream ended, finalizing message');

      // 立即将流式内容转为正式消息
      setStreamingContent((currentStreamContent) => {
        if (currentStreamContent.trim()) {
          const assistantMessage: Message = {
            id: data.messageId || streamingMessageIdRef.current || (Date.now() + 1).toString(),
            role: 'assistant',
            content: currentStreamContent,
            timestamp: Date.now(),
          };

          setMessages((prev) => [...prev, assistantMessage]);
        }
        return ''; // 清空流式内容
      });

      setIsLoading(false);
      streamingMessageIdRef.current = '';
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
      setStreamingContent('');
    };

    // 注册事件监听
    nativeBridge.on('openclaw.message.chunk', handleChunk);
    nativeBridge.on('openclaw.message.end', handleStreamEnd);
    nativeBridge.on('openclaw.stream.end', handleStreamEnd); // 兼容不同的事件名
    nativeBridge.on('openclaw.connected', handleConnected);
    nativeBridge.on('openclaw.disconnected', handleDisconnected);
    nativeBridge.on('openclaw.error', handleError);

    // 清理监听器
    return () => {
      nativeBridge.off('openclaw.message.chunk', handleChunk);
      nativeBridge.off('openclaw.message.end', handleStreamEnd);
      nativeBridge.off('openclaw.stream.end', handleStreamEnd);
      nativeBridge.off('openclaw.connected', handleConnected);
      nativeBridge.off('openclaw.disconnected', handleDisconnected);
      nativeBridge.off('openclaw.error', handleError);
    };
  }, []);

  const handleSendMessage = async (content: string) => {
    if (!content.trim()) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content,
      timestamp: Date.now(),
    };

    // 立即添加用户消息到列表（乐观更新）
    setMessages((prev) => [...prev, userMessage]);

    setInputValue('');
    setIsLoading(true);
    setStreamingContent('');
    streamingMessageIdRef.current = (Date.now() + 1).toString();

    try {
      // 通过 Native Bridge 发送消息到 OpenClaw
      await nativeBridge.sendMessage(content, CURRENT_SESSION_ID);
      console.log('📤 Message sent to OpenClaw');
    } catch (error) {
      console.error('❌ Failed to send message:', error);
      setIsLoading(false);
      setStreamingContent('');
    }
  };

  return (
    <AppLayout>
      <Sidebar activeTab={activeTab} onTabChange={setActiveTab} />

      <main className="chat-area">
        {!isHistoryLoaded ? (
          <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}>
            <div className="typing-indicator">
              <span></span>
              <span></span>
              <span></span>
            </div>
          </div>
        ) : (
          <>
            <div className="messages-scroll-container" ref={scrollContainerRef}>
              <div className="messages-content">
                {messages.map((message) => (
                  <div key={message.id} className={`message-bubble-wrapper ${message.role}`}>
                    <div className="message-bubble">
                      {message.role === 'assistant' ? (
                        <MarkdownRenderer content={message.content} theme="light" />
                      ) : (
                        <div className="message-text">{message.content}</div>
                      )}
                    </div>
                  </div>
                ))}

                {/* 显示正在流式输出的内容 */}
                {streamingContent && (
                  <div className="message-bubble-wrapper assistant streaming">
                    <div className="message-bubble">
                      <MarkdownRenderer content={streamingContent} theme="light" />
                    </div>
                  </div>
                )}

                {/* 加载指示器 */}
                {isLoading && !streamingContent && (
                  <div className="message-bubble-wrapper assistant">
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
            </div>

            <ChatInput
              value={inputValue}
              onChange={setInputValue}
              onSend={() => handleSendMessage(inputValue)}
              disabled={false}
            />
          </>
        )}
      </main>

      <WidgetSidebar />
    </AppLayout>
  );
};
