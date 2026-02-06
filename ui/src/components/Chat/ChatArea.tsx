import React, { useState } from 'react';
import { MessageList, type Message } from './MessageList';
import { ChatInput } from './ChatInput';
import './ChatArea.css';

interface ChatAreaProps {
  messages: Message[];
  onSendMessage: (content: string) => void;
}

export const ChatArea: React.FC<ChatAreaProps> = ({
  messages,
  onSendMessage,
}) => {
  const [inputValue, setInputValue] = useState('');

  const handleSend = () => {
    if (inputValue.trim()) {
      onSendMessage(inputValue);
      setInputValue('');
    }
  };

  return (
    <main className="chat-area">
      <MessageList messages={messages} />
      <ChatInput
        value={inputValue}
        onChange={setInputValue}
        onSend={handleSend}
      />
    </main>
  );
};
