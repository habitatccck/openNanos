import React from 'react';
import './CalendarWidget.css';

interface CalendarWidgetProps {
  currentDay?: number;
}

const weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const daysInMonth = Array.from({ length: 31 }, (_, i) => i + 1);

export const CalendarWidget: React.FC<CalendarWidgetProps> = ({
  currentDay = 8,
}) => {
  return (
    <div className="calendar-widget">
      <h4 className="calendar-title">CALENDAR</h4>
      <div className="calendar-grid">
        {/* Week days header */}
        {weekDays.map((day) => (
          <div key={day} className="calendar-weekday">
            {day}
          </div>
        ))}
        {/* Days */}
        {daysInMonth.map((day) => (
          <div
            key={day}
            className={`calendar-day ${day === currentDay ? 'active' : ''}`}
          >
            {day}
          </div>
        ))}
      </div>
    </div>
  );
};
