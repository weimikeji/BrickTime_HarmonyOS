// 数据模型
export interface Record {
  id: string;
  content: string;
  tagId: string;
  createdAt: number;
  date: string;
  color: string;
}

export interface Tag {
  id: string;
  name: string;
  color: string;
  icon: string;
}

export interface DayData {
  date: string;
  records: Record[];
}

export interface WeekData {
  weekNumber: number;
  year: number;
  days: DayData[];
}

export interface StatsData {
  totalDays: number;
  completedDays: number;
  currentStreak: number;
  longestStreak: number;
  completionRate: number;
}

export interface ReminderItem {
  id: string;
  title: string;
  time: string;
}

export interface AppSettings {
  dailyReminder: boolean;
  reminderTime: string;
  reminderTimes: ReminderItem[];
  hapticFeedback: boolean;
  darkMode: boolean;
  themeColor: string;
  iCloudSync: boolean;
  faceIdLock: boolean;
  anonymousAnalytics: boolean;
}
