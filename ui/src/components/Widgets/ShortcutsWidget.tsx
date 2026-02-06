import React from 'react';
import { ChevronRight } from '../Common/Icons';
import './ShortcutsWidget.css';

interface Shortcut {
  label: string;
  variant?: 'primary' | 'secondary';
  onClick?: () => void;
}

interface ShortcutsWidgetProps {
  shortcuts?: Shortcut[];
}

const defaultShortcuts: Shortcut[] = [
  { label: '一键总结文档内容', variant: 'primary' },
  { label: '智能翻译模式', variant: 'secondary' },
];

export const ShortcutsWidget: React.FC<ShortcutsWidgetProps> = ({
  shortcuts = defaultShortcuts,
}) => {
  return (
    <div className="shortcuts-widget">
      {shortcuts.map((shortcut, index) => (
        <button
          key={index}
          onClick={shortcut.onClick}
          className={`shortcut-button ${shortcut.variant || 'secondary'}`}
        >
          <span className="shortcut-label">{shortcut.label}</span>
          <ChevronRight size={16} className="shortcut-icon" />
        </button>
      ))}
    </div>
  );
};
