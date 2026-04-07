import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { storageService } from '../services/StorageService';
import { reminderService } from '../services/ReminderService';

const DOMAIN = 0x0001;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'BrickTime', 'onCreate');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    storageService.init(this.context).then(() => {
      reminderService.init(this.context);
      const settings = storageService.getSettings();
      if (settings.dailyReminder && reminderService.isReminderPermissionGranted()) {
        void reminderService.syncWithSettings(settings).catch(() => {
          hilog.warn(DOMAIN, 'BrickTime', 'sync reminder failed');
        });
      }
      windowStage.loadContent('pages/Index', (err) => {
        hilog.info(DOMAIN, 'BrickTime', 'loaded');
      });
    }).catch(() => {
      windowStage.loadContent('pages/Index', (err) => {
        hilog.info(DOMAIN, 'BrickTime', 'loaded');
      });
    });
  }
}
