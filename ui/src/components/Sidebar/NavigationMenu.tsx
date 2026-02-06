import React from 'react';
import { MessageSquare, CheckSquare, Library, Folder, Settings } from '../Common/Icons';
import './NavigationMenu.css';

export interface NavItem {
  name: string;
  icon: React.FC<{ size?: number }>;
  key: string;
}

interface NavigationMenuProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
}

const navItems: NavItem[] = [
  { name: '智能对话', icon: MessageSquare, key: 'Chat' },
  { name: '任务看板', icon: CheckSquare, key: 'Tasks' },
  { name: '知识库', icon: Library, key: 'Knowledge' },
  { name: '文件库', icon: Folder, key: 'Files' },
  { name: '设置', icon: Settings, key: 'Settings' },
];

export const NavigationMenu: React.FC<NavigationMenuProps> = ({
  activeTab,
  onTabChange,
}) => {
  return (
    <nav className="navigation-menu">
      {navItems.map((item) => (
        <button
          key={item.key}
          onClick={() => onTabChange(item.key)}
          className={`nav-item ${activeTab === item.key ? 'active' : ''}`}
        >
          <item.icon size={18} />
          <span className="nav-item-text">{item.name}</span>
        </button>
      ))}
    </nav>
  );
};
