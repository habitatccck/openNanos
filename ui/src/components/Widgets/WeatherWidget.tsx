import React from 'react';
import { Sun } from '../Common/Icons';
import './WeatherWidget.css';

interface WeatherWidgetProps {
  temperature?: number;
  location?: string;
}

export const WeatherWidget: React.FC<WeatherWidgetProps> = ({
  temperature = 18,
  location = 'San Francisco',
}) => {
  return (
    <div className="weather-widget">
      <div className="weather-content">
        <Sun className="weather-icon" size={32} />
        <div className="weather-info">
          <div className="temperature">{temperature}°C</div>
          <div className="location">{location}</div>
        </div>
      </div>
    </div>
  );
};
