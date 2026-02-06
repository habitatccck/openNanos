import React from 'react';
import { WeatherWidget } from './WeatherWidget';
import { ShortcutsWidget } from './ShortcutsWidget';
import { CalendarWidget } from './CalendarWidget';
import './WidgetSidebar.css';

export const WidgetSidebar: React.FC = () => {
  return (
    <aside className="widget-sidebar">
      <WeatherWidget />
      <ShortcutsWidget />
      <CalendarWidget />
    </aside>
  );
};
