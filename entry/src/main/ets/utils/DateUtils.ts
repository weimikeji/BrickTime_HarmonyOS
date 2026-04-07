// 日期工具类
export class DateUtils {
  // 获取当前日期字符串
  static getToday(): string {
    const now = new Date();
    return this.formatDate(now);
  }

  // 格式化日期
  static formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  // 解析日期字符串
  static parseDate(dateStr: string): Date {
    const [year, month, day] = dateStr.split('-').map(Number);
    return new Date(year, month - 1, day);
  }

  // 获取周数
  static getWeekNumber(date: Date): number {
    const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    const dayNum = d.getUTCDay() || 7;
    d.setUTCDate(d.getUTCDate() + 4 - dayNum);
    const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
    return Math.ceil((((d.getTime() - yearStart.getTime()) / 86400000) + 1) / 7);
  }

  // 获取一周的日期
  static getWeekDays(weekNumber: number, year: number): string[] {
    const result: string[] = [];
    const firstDay = new Date(year, 0, 1);
    const pastDaysOfYear = (firstDay.getTime() - new Date(year, 0, 1).getTime()) / 86400000;
    const weekNum = weekNumber;
    const weekStart = firstDay.getTime() + (weekNum - 1) * 7 * 86400000;

    for (let i = 0; i < 7; i++) {
      const day = new Date(weekStart + i * 86400000);
      result.push(this.formatDate(day));
    }
    return result;
  }

  // 判断是否是同一天
  static isSameDay(date1: string, date2: string): boolean {
    return date1 === date2;
  }

  // 获取日期对应的星期几
  static getDayOfWeek(dateStr: string): number {
    const date = this.parseDate(dateStr);
    return date.getDay();
  }

  // 获取中文星期几
  static getDayOfWeekChinese(dateStr: string): string {
    const days = ['日', '一', '二', '三', '四', '五', '六'];
    const dayOfWeek = this.getDayOfWeek(dateStr);
    return days[dayOfWeek];
  }

  // 生成唯一ID
  static generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substring(2);
  }
}

// 获取数字数组的辅助函数
export function getNumberArray(length: number): number[] {
  const arr: number[] = [];
  for (let i = 0; i < length; i++) {
    arr.push(i);
  }
  return arr;
}
