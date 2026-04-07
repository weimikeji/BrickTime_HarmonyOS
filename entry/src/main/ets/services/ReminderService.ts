import { abilityAccessCtrl, Context, Permissions } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import notificationManager from '@ohos.notificationManager';
import reminderAgentManager from '@ohos.reminderAgentManager';
import { AppSettings, ReminderItem } from '../models/DataModels';

const DOMAIN = 0x0001;
const TAG = 'BrickTimeReminder';
const REMINDER_PERMISSION: Permissions = 'ohos.permission.PUBLISH_AGENT_REMINDER';
const REMINDER_REBUILD_DELAY_MS = 200;
const LEGACY_REMINDER_LIMIT_ERROR_CODE = 17700002;
const REMINDER_LIMIT_ERROR_CODE = 1700002;

interface ReminderBusinessError {
  code?: number;
  message?: string;
}

const REMINDER_PERMISSION_ERROR_CODE = 1701001;

class ReminderService {
  private context: Context | null = null;

  init(context: Context): void {
    this.context = context;
  }

  async syncWithSettings(settings: AppSettings): Promise<void> {
    if (!settings.dailyReminder) {
      await this.cancelAll();
      return;
    }

    if (!this.hasNotificationPermission() || !this.hasReminderPermission()) {
      hilog.info(DOMAIN, TAG, 'Notification or reminder permission not granted, skip silent sync');
      return;
    }
    await this.publishDailyReminders(settings.reminderTimes);
  }

  async enableDailyReminder(settings: AppSettings): Promise<boolean> {
    const notificationEnabled = await this.ensureNotificationPermission();
    if (!notificationEnabled) {
      return false;
    }

    const granted = await this.ensureReminderPermission();
    if (!granted) {
      return false;
    }
    await this.publishDailyReminders(settings.reminderTimes);
    return true;
  }

  async updateReminderTime(settings: AppSettings): Promise<void> {
    if (!settings.dailyReminder) {
      return;
    }

    const notificationEnabled = await this.ensureNotificationPermission();
    if (!notificationEnabled) {
      throw this.createBusinessError(REMINDER_PERMISSION_ERROR_CODE, '系统通知权限没有开启，本地提醒暂时无法同步。');
    }

    const reminderEnabled = await this.ensureReminderPermission();
    if (!reminderEnabled) {
      throw this.createBusinessError(REMINDER_PERMISSION_ERROR_CODE, '提醒权限没有开启，本地提醒暂时无法同步。');
    }

    await this.publishDailyReminders(settings.reminderTimes);
  }

  async disableDailyReminder(): Promise<void> {
    await this.clearAllReminders();
  }

  isReminderPermissionGranted(): boolean {
    return this.hasNotificationPermission() && this.hasReminderPermission();
  }

  private getAbilityInfo(): { bundleName: string; abilityName: string } | null {
    if (!this.context) {
      return null;
    }

    const abilityContext = this.context as Context & {
      abilityInfo?: {
        bundleName?: string;
        name?: string;
      };
      applicationInfo: {
        bundleName?: string;
        name: string;
      };
    };
    const bundleName = abilityContext.abilityInfo?.bundleName ?? abilityContext.applicationInfo.bundleName ?? '';
    const abilityName = abilityContext.abilityInfo?.name ?? 'EntryAbility';
    if (!bundleName || !abilityName) {
      hilog.error(DOMAIN, TAG, `ability info invalid, bundleName=${bundleName}, abilityName=${abilityName}`);
      return null;
    }
    return { bundleName, abilityName };
  }

  private parseTime(reminderTime: string): { hour: number; minute: number } {
    const parts = reminderTime.split(':');
    const hour = Number(parts[0]);
    const minute = Number(parts[1]);
    if (Number.isNaN(hour) || Number.isNaN(minute)) {
      return { hour: 21, minute: 0 };
    }
    return { hour, minute };
  }

  private createReminderDateTime(reminderTime: string): reminderAgentManager.LocalDateTime {
    const { hour, minute } = this.parseTime(reminderTime);
    const now = new Date();
    return {
      year: now.getFullYear(),
      month: now.getMonth() + 1,
      day: now.getDate(),
      hour: hour,
      minute: minute,
      second: 0
    };
  }

  private createBusinessError(code: number, message: string): ReminderBusinessError {
    return { code, message };
  }

  private hasNotificationPermission(): boolean {
    try {
      return notificationManager.isNotificationEnabledSync();
    } catch (error) {
      hilog.error(DOMAIN, TAG, `verify notification permission failed: ${JSON.stringify(error)}`);
      return false;
    }
  }

  private async ensureNotificationPermission(): Promise<boolean> {
    if (this.hasNotificationPermission()) {
      return true;
    }

    try {
      await notificationManager.requestEnableNotification();
    } catch (error) {
      hilog.error(DOMAIN, TAG, `request notification permission failed: ${JSON.stringify(error)}`);
    }

    return this.hasNotificationPermission();
  }

  private hasReminderPermission(): boolean {
    if (!this.context) {
      return false;
    }

    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const grantStatus = atManager.verifyAccessTokenSync(this.context.applicationInfo.accessTokenId, REMINDER_PERMISSION);
      return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `verify permission failed: ${JSON.stringify(error)}`);
      return false;
    }
  }

  private async ensureReminderPermission(): Promise<boolean> {
    if (!this.context) {
      return false;
    }

    if (this.hasReminderPermission()) {
      return true;
    }

    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(this.context, [REMINDER_PERMISSION]);
      return result.authResults.length > 0 &&
        result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `request permission failed: ${JSON.stringify(error)}`);
      return false;
    }
  }

  private async publishDailyReminders(reminders: ReminderItem[]): Promise<void> {
    const abilityInfo = this.getAbilityInfo();
    if (!abilityInfo) {
      return;
    }

    try {
      await this.rebuildReminders(reminders, abilityInfo);
    } catch (error) {
      const businessError = error as ReminderBusinessError;
      if (businessError.code === REMINDER_LIMIT_ERROR_CODE || businessError.code === LEGACY_REMINDER_LIMIT_ERROR_CODE) {
        hilog.warn(DOMAIN, TAG, 'reminder limit reached, retry after reset');
        await this.clearAllReminders();
        await this.waitForReminderReset();
        await this.rebuildReminders(reminders, abilityInfo);
        return;
      }
      hilog.error(DOMAIN, TAG, `publish reminder failed: ${JSON.stringify(error)}`);
      throw error as Error;
    }
  }

  private async cancelAll(): Promise<void> {
    try {
      await this.clearAllReminders();
    } catch (error) {
      hilog.error(DOMAIN, TAG, `cancel reminders failed: ${JSON.stringify(error)}`);
    }
  }

  private async clearAllReminders(): Promise<void> {
    const reminders = await reminderAgentManager.getAllValidReminders();
    for (let index = 0; index < reminders.length; index += 1) {
      await reminderAgentManager.cancelReminder(reminders[index].reminderId);
    }
    await reminderAgentManager.cancelAllReminders();
    await this.waitForReminderReset();
  }

  private async rebuildReminders(reminders: ReminderItem[], abilityInfo: { bundleName: string; abilityName: string }): Promise<void> {
    await this.cancelAll();
    for (let index = 0; index < reminders.length; index += 1) {
      const reminder = reminders[index];
      const reminderRequest: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: this.createReminderDateTime(reminder.time),
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        title: reminder.title,
        content: `${reminder.time} 到了，${reminder.title}`,
        expiredContent: `${reminder.time} 的提醒已错过，记得回来看看。`,
        wantAgent: {
          pkgName: abilityInfo.bundleName,
          abilityName: abilityInfo.abilityName
        }
      };
      const reminderId = await reminderAgentManager.publishReminder(reminderRequest);
      hilog.info(DOMAIN, TAG,
        `publish reminder success, id=${reminderId}, pkg=${abilityInfo.bundleName}, ability=${abilityInfo.abilityName}, time=${reminder.time}`);
    }
  }

  private async waitForReminderReset(): Promise<void> {
    await new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve();
      }, REMINDER_REBUILD_DELAY_MS);
    });
  }
}

export const reminderService = new ReminderService();
