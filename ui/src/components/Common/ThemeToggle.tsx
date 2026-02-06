import React from 'react';
import { useTheme } from '../../context/ThemeContext';
import { Sun, Moon } from './Icons';
import './ThemeToggle.css';

export const ThemeToggle: React.FC = () => {
  const { theme, toggleTheme } = useTheme();

  return (
    <button className="theme-toggle" onClick={toggleTheme} aria-label="Toggle theme">
      <div className={`toggle-track ${theme}`}>
        <div className="toggle-thumb">
          {theme === 'light' ? <Sun size={14} /> : <Moon size={14} />}
        </div>
      </div>
    </button>
  );
};
