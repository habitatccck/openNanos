import React from 'react';
import { Send } from '../Common/Icons';
import './ChatInput.css';

interface ChatInputProps {
  value: string;
  onChange: (value: string) => void;
  onSend: () => void;
  placeholder?: string;
  disabled?: boolean;
}

export const ChatInput: React.FC<ChatInputProps> = ({
  value,
  onChange,
  onSend,
  placeholder = 'Ask me anything...',
  disabled = false,
}) => {
  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey && !disabled) {
      e.preventDefault();
      onSend();
    }
  };

  return (
    <div className="chat-input-container">
      {/* Voice Wave Animation */}
      <div className="voice-wave">
        {[1, 2, 3, 2, 4, 2, 1].map((height, index) => (
          <div
            key={index}
            className="wave-bar"
            style={{ height: `${height * 4}px` }}
          />
        ))}
      </div>

      {/* Input Field */}
      <div className="input-wrapper">
        <input
          type="text"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          onKeyPress={handleKeyPress}
          placeholder={placeholder}
          disabled={disabled}
          className="chat-input"
        />
        <button
          onClick={onSend}
          disabled={!value.trim() || disabled}
          className="send-button"
        >
          <Send size={18} />
        </button>
      </div>
    </div>
  );
};
