import { create } from 'zustand';

export interface AlertNotification {
  id: string;
  title: string;
  message: string;
  type: 'info' | 'success' | 'warning' | 'error';
  timestamp: Date;
}

interface NotificationState {
  notifications: AlertNotification[];
  addNotification: (notification: Omit<AlertNotification, 'id' | 'timestamp'>) => void;
  clearAll: () => void;
}

export const useNotificationStore = create<NotificationState>((set) => ({
  notifications: [
    {
      id: '1',
      title: 'Charger Online',
      message: 'Charger TX_AUS_DWTN_01 completed boot sequence successfully.',
      type: 'success',
      timestamp: new Date()
    },
    {
      id: '2',
      title: 'High Temperature Warning',
      message: 'Connector 1 on TX_AUS_NL_01 reports 65°C.',
      type: 'warning',
      timestamp: new Date(Date.now() - 5 * 60000)
    }
  ],
  addNotification: (notification) => set((state) => ({
    notifications: [
      {
        ...notification,
        id: Math.random().toString(),
        timestamp: new Date()
      },
      ...state.notifications
    ]
  })),
  clearAll: () => set({ notifications: [] }),
}));
