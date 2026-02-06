import React from 'react';
import { MarkdownRenderer } from '../MarkdownRenderer';
import './MessageBubble.css';

export interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: number;
}

interface MessageBubbleProps {
  message: Message;
}

export const MessageBubble: React.FC<MessageBubbleProps> = ({ message }) => {
  return (
    <div className={`message-bubble-wrapper ${message.role}`}>
      <div className="message-bubble">
        {message.role === 'assistant' ? (
          <MarkdownRenderer content={message.content} theme="light" />
        ) : (
          <div className="message-text">{message.content}</div>
        )}
      </div>
    </div>
  );
};
