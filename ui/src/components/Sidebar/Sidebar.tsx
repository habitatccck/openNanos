import React from 'react';
import { UserStatus } from './UserStatus';
import { NavigationMenu } from './NavigationMenu';
import { ThemeToggle } from '../Common/ThemeToggle';
import './Sidebar.css';

interface SidebarProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ activeTab, onTabChange }) => {
  return (
    <aside className="sidebar">
      <UserStatus />
      <NavigationMenu activeTab={activeTab} onTabChange={onTabChange} />
      <div className="sidebar-footer">
        <ThemeToggle />
        <div className="storage-info">
          Storage Used: 12.7GB / 256GB
        </div>
      </div>
    </aside>
  );
};
