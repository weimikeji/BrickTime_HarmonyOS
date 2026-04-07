// 事件总线 - 组件间通信
type EventCallback = (data?: Record<string, ESObject>) => void;

class EventBusClass {
  private listeners: Map<string, EventCallback[]> = new Map();

  // 订阅事件
  on(event: string, callback: EventCallback): void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    this.listeners.get(event)!.push(callback);
  }

  // 取消订阅
  off(event: string, callback: EventCallback): void {
    const callbacks = this.listeners.get(event);
    if (callbacks) {
      const index = callbacks.indexOf(callback);
      if (index > -1) {
        callbacks.splice(index, 1);
      }
    }
  }

  // 发布事件
  emit(event: string, data?: Record<string, ESObject>): void {
    const callbacks = this.listeners.get(event);
    if (callbacks) {
      callbacks.forEach(callback => callback(data));
    }
  }

  // 清空所有事件
  clear(): void {
    this.listeners.clear();
  }
}

export const EventBus = new EventBusClass();

// 常用事件
export const Events = {
  RECORD_ADDED: 'record_added',
  RECORD_DELETED: 'record_deleted',
  RECORD_UPDATED: 'record_updated',
  TAG_UPDATED: 'tag_updated',
  STATS_UPDATED: 'stats_updated',
  SETTINGS_CHANGED: 'settings_changed',
  HOME_DRAWER_OPEN: 'home_drawer_open',
  HOME_DRAWER_CLOSE: 'home_drawer_close',
};
