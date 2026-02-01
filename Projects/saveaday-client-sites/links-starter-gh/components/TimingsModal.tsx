import React from 'react';
import { X, Clock } from 'lucide-react';
import { BusinessHour } from '../types';

interface TimingsModalProps {
  businessHours: BusinessHour[];
  isOpen: boolean;
  onClose: () => void;
  theme: any;
}

export const TimingsModal: React.FC<TimingsModalProps> = ({ businessHours, isOpen, onClose, theme }) => {
  if (!isOpen) return null;

  const daysMap = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const currentDayIndex = new Date().getDay();
  const currentDayName = daysMap[currentDayIndex];

  // Order days starting from Monday as per user data generally, or just standard week
  // The data has Mon, Tue... Sun.
  // Let's rely on the order provided in the array, but simpler: just render as is.
  // Actually, standard is usually Mon-Sun or Sun-Sat. The data provided starts with Mon.

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm animate-in fade-in duration-200">
      <div 
        className="relative w-full max-w-md bg-white rounded-2xl shadow-xl transform transition-all animate-in zoom-in-95 duration-200"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-100">
          <div className="flex items-center gap-3">
            <div className={`p-2 rounded-full ${theme.background && theme.background.startsWith('bg-') ? 'bg-slate-100' : 'bg-opacity-10'}`} style={!theme.background.startsWith('bg-') ? { backgroundColor: theme.background + '20' } : {}}>
              <Clock className="w-5 h-5 text-slate-700" />
            </div>
            <h3 className="text-xl font-bold text-slate-900">Business Hours</h3>
          </div>
          <button 
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-full transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-3">
          {businessHours.map((hours, index) => {
            const isToday = hours.day === currentDayName;
            
            return (
              <div 
                key={index}
                className={`flex justify-between items-center p-3 rounded-xl transition-colors ${
                  isToday 
                    ? 'bg-indigo-50 border border-indigo-100' 
                    : 'hover:bg-gray-50'
                }`}
              >
                <span className={`font-medium ${isToday ? 'text-indigo-700' : 'text-slate-600'}`}>
                  {hours.day}
                </span>
                
                <div className={`text-sm font-semibold ${isToday ? 'text-indigo-700' : 'text-slate-900'}`}>
                  {hours.isOpen ? (
                    <span>{hours.start} - {hours.end}</span>
                  ) : (
                    <span className="text-slate-400">Closed</span>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
