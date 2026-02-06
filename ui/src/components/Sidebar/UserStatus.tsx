import React from 'react';
import './UserStatus.css';

interface UserStatusProps {
  avatar?: string;
  status?: string;
  isOnline?: boolean;
}

export const UserStatus: React.FC<UserStatusProps> = ({
  avatar = '/api/placeholder/40/40',
  status = 'Listening...',
  isOnline = true,
}) => {
  return (
    <div className="user-status">
      <div className="user-avatar">
        <img src={avatar} alt="User Avatar" className="avatar-image" />
        {isOnline && <div className="status-indicator" />}
      </div>
      <span className="status-text">{status}</span>
    </div>
  );
};
