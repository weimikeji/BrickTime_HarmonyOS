import { RouterManager } from '../router/RouterManager';
import { reminderService } from '../services/ReminderService';
import { storageService } from '../services/StorageService';
import { AppSettings, ReminderItem } from '../models/DataModels';
import { EventBus, Events } from '../services/EventBus';
import { AppNavigationBar } from '../components/AppNavigationBar';

interface ExportPayload {
  app: string;
  exportedAt: string;
  records: object[];
  tags: object[];
  stats: object;
  settings: AppSettings;
}

@Entry
@Component
export struct SettingsPage {
  private readonly privacyPolicyUrl: string = 'https://www.baidu.com';
  private readonly termsOfServiceUrl: string = 'https://www.baidu.com';
  private readonly aboutUsUrl: string = 'https://example.com/about';
  private readonly pageBackground: string = '#F7F8FB';
  private readonly surfaceColor: string = '#FFFFFF';
  private readonly titleColor: string = '#3B3D45';
  private readonly secondaryTextColor: string = '#99A3B6';
  private readonly mutedTextColor: string = '#BAC3D4';
  private readonly rowBorderColor: string = '#F2F4F8';
  private readonly cardShadow: string = '#14000000';
  private readonly destructiveColor: string = '#FF6C6C';
  private readonly versionText: string = '1.0.0';
  private readonly bundleNameText: string = 'com.wm.bricktime';
  private readonly dismissFocusId: string = 'settingsDismissFocus';

  @State settings: AppSettings = storageService.getSettings();
  @State activeSheet: string = '';
  @State exportContent: string = '';
  @State reminderPermissionStatus: string = '未开启';

  aboutToAppear() {
    EventBus.on(Events.SETTINGS_CHANGED, this.handleSettingsChanged);
    this.settings = storageService.getSettings();
    this.refreshRuntimeStatus();
  }

  aboutToDisappear() {
    EventBus.off(Events.SETTINGS_CHANGED, this.handleSettingsChanged);
  }

  private handleSettingsChanged = () => {
    this.settings = storageService.getSettings();
    this.refreshRuntimeStatus();
  };

  private saveSettings() {
    storageService.saveSettings(this.settings);
  }

  private updateSettings(nextSettings: AppSettings) {
    this.settings = nextSettings;
    this.saveSettings();
  }

  private refreshRuntimeStatus() {
    this.reminderPermissionStatus = reminderService.isReminderPermissionGranted() ? '已开启' : '未开启';
  }

  private cloneReminderItem(item: ReminderItem): ReminderItem {
    return {
      id: item.id,
      title: item.title,
      time: item.time
    };
  }

  private cloneSettings(): AppSettings {
    return {
      dailyReminder: this.settings.dailyReminder,
      reminderTime: this.settings.reminderTime,
      reminderTimes: this.settings.reminderTimes.map((item: ReminderItem): ReminderItem => this.cloneReminderItem(item)),
      hapticFeedback: this.settings.hapticFeedback,
      darkMode: this.settings.darkMode,
      themeColor: this.settings.themeColor,
      iCloudSync: this.settings.iCloudSync,
      faceIdLock: this.settings.faceIdLock,
      anonymousAnalytics: this.settings.anonymousAnalytics
    };
  }

  private toggleSetting(key: keyof AppSettings) {
    if (typeof this.settings[key] !== 'boolean') {
      return;
    }
    const nextSettings: AppSettings = this.cloneSettings();
    if (key === 'dailyReminder') {
      nextSettings.dailyReminder = !this.settings.dailyReminder;
    } else if (key === 'hapticFeedback') {
      nextSettings.hapticFeedback = !this.settings.hapticFeedback;
    } else if (key === 'darkMode') {
      nextSettings.darkMode = !this.settings.darkMode;
    } else if (key === 'iCloudSync') {
      nextSettings.iCloudSync = !this.settings.iCloudSync;
    } else if (key === 'faceIdLock') {
      nextSettings.faceIdLock = !this.settings.faceIdLock;
    } else if (key === 'anonymousAnalytics') {
      nextSettings.anonymousAnalytics = !this.settings.anonymousAnalytics;
    }
    this.updateSettings(nextSettings);
  }

  private openExportSheet() {
    const exportData: ExportPayload = {
      app: 'BrickTime',
      exportedAt: new Date().toISOString(),
      records: storageService.getRecords(),
      tags: storageService.getTags(),
      stats: storageService.getStats(),
      settings: storageService.getSettings()
    };
    this.exportContent = JSON.stringify(exportData, null, 2);
    this.activeSheet = 'export';
  }

  private showClearDataDialog() {
    AlertDialog.show({
      title: '清空所有数据',
      message: '确认后会删除记录、标签和成长统计，这个操作无法撤回。',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '清空',
        action: () => {
          storageService.clearAll();
          this.settings = storageService.getSettings();
        }
      }
    });
  }

  private showTextDialog(title: string, message: string) {
    AlertDialog.show({
      title: title,
      message: message,
      primaryButton: {
        value: '知道了',
        action: () => {
        }
      }
    });
  }

  private dismissKeyboard() {
    focusControl.requestFocus(this.dismissFocusId);
  }

  private openWebContent(title: string, url: string) {
    RouterManager.goToWebView(title, url);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column() {
          AppNavigationBar({
            title: '系统设置',
            titleColor: this.titleColor,
            surfaceColor: this.surfaceColor
          });

          Column() {
            this.SectionTitle('基础设置');
            this.BaseSection();

            this.SectionTitle('权限与隐私');
            this.PermissionSection()

            this.SectionTitle('关于应用');
            this.AboutSection();
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 32 });
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.pageBackground)
      .scrollBar(BarState.Off)
      .onClick(() => {
        this.dismissKeyboard();
      });

      if (this.activeSheet !== '') {
        this.ModalOverlay();
      }

      Column()
        .id(this.dismissFocusId)
        .focusable(true)
        .width(1)
        .height(1)
        .opacity(0);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.pageBackground)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.mutedTextColor)
      .margin({ left: 2, bottom: 10, top: 2 });
  }

  @Builder
  BaseSection() {
    Column() {
      this.SwitchRow('≋', '震动反馈', this.settings.hapticFeedback, () => {
        this.toggleSetting('hapticFeedback');
      });

      this.SimpleRow('⌫', '清空所有数据', true, () => {
        this.showClearDataDialog();
      }, true);
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(16)
    .padding({ left: 14, right: 14 })
    .shadow({ radius: 18, color: this.cardShadow, offsetX: 0, offsetY: 6 })
    .margin({ bottom: 18 });
  }

  @Builder
  PermissionSection() {
    Column() {
      this.ValueRow('◔', '通知权限', this.reminderPermissionStatus, () => {
        this.showTextDialog('通知权限', '提醒通知权限由提醒设置页按需申请。若当前显示未开启，请前往“提醒设置”打开每日提醒后完成授权。');
      });
      this.SimpleRow('▿', '隐私政策', false, () => {
        this.openWebContent('隐私政策', this.privacyPolicyUrl);
      });
      this.SimpleRow('◫', '使用条款', false, () => {
        this.openWebContent('使用条款', this.termsOfServiceUrl);
      }, true);
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(16)
    .padding({ left: 14, right: 14 })
    .shadow({ radius: 18, color: this.cardShadow, offsetX: 0, offsetY: 6 })
    .margin({ bottom: 18 });
  }

  @Builder
  AboutSection() {
    Column() {
      this.ValueRow('ⓘ', '版本号', this.versionText, () => {
      });
      this.SimpleRow('i', '关于我们', false, () => {
        this.openWebContent('关于我们', this.aboutUsUrl);
      }, true);
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(16)
    .padding({ left: 14, right: 14 })
    .shadow({ radius: 18, color: this.cardShadow, offsetX: 0, offsetY: 6 });
  }

  @Builder
  SwitchRow(icon: string, title: string, isOn: boolean, action: () => void, isLast: boolean = false) {
    Row() {
      this.LeadingIcon(icon, title === '清空所有数据');

      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.titleColor)
        .layoutWeight(1);

      this.SwitchView(isOn);
    }
    .width('100%')
    .height(50)
    .border({
      width: { bottom: isLast ? 0 : 1 },
      color: this.rowBorderColor
    })
    .onClick(() => {
      action();
    });
  }

  @Builder
  ValueRow(icon: string, title: string, value: string, action: () => void, isLast: boolean = false) {
    Row() {
      this.LeadingIcon(icon, false);

      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.titleColor)
        .layoutWeight(1);

      Text(value)
        .fontSize(13)
        .fontColor(this.secondaryTextColor)
        .margin({ right: 8 });

      Text('›')
        .fontSize(18)
        .fontColor(this.mutedTextColor);
    }
    .width('100%')
    .height(50)
    .border({
      width: { bottom: isLast ? 0 : 1 },
      color: this.rowBorderColor
    })
    .onClick(() => {
      action();
    });
  }

  @Builder
  SimpleRow(icon: string, title: string, isDestructive: boolean, action: () => void, isLast: boolean = false) {
    Row() {
      this.LeadingIcon(icon, isDestructive);

      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(isDestructive ? this.destructiveColor : this.titleColor)
        .layoutWeight(1);

      Text('›')
        .fontSize(18)
        .fontColor(this.mutedTextColor);
    }
    .width('100%')
    .height(50)
    .border({
      width: { bottom: isLast ? 0 : 1 },
      color: this.rowBorderColor
    })
    .onClick(() => {
      action();
    });
  }

  @Builder
  LeadingIcon(icon: string, isDestructive: boolean) {
    Text(icon)
      .width(20)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .textAlign(TextAlign.Center)
      .fontColor(isDestructive ? this.destructiveColor : '#9CA6B9')
      .margin({ right: 12 });
  }

  @Builder
  SwitchView(isOn: boolean) {
    Stack({ alignContent: isOn ? Alignment.End : Alignment.Start }) {
      Column()
        .width(30)
        .height(18)
        .backgroundColor(isOn ? this.settings.themeColor : '#E7EBF2')
        .borderRadius(9);

      Column()
        .width(14)
        .height(14)
        .backgroundColor('#FFFFFF')
        .borderRadius(7)
        .margin({ left: 2, right: 2 })
        .shadow({ radius: 6, color: '#18000000', offsetX: 0, offsetY: 1 });
    }
    .width(30)
    .height(18);
  }

  @Builder
  ModalOverlay() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#24000000')
        .onClick(() => {
          this.activeSheet = '';
        });

      this.ActiveSheetContent();
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  ActiveSheetContent() {
    if (this.activeSheet === 'export') {
      this.ExportSheet();
    }
  }

  @Builder
  SelectionSheet(title: string, options: string[], selected: string, action: (value: string) => void) {
    Column() {
      Column()
        .width(42)
        .height(5)
        .backgroundColor('#E5EAF3')
        .borderRadius(3)
        .margin({ top: 10, bottom: 18 });

      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor)
        .margin({ bottom: 16 });

      ForEach(options, (option: string) => {
        Row() {
          Text(option)
            .fontSize(16)
            .fontWeight(option === selected ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(option === selected ? this.settings.themeColor : this.titleColor)
            .layoutWeight(1);

          if (option === selected) {
            Text('✓')
              .fontSize(16)
              .fontColor(this.settings.themeColor);
          }
        }
        .width('100%')
        .height(46)
        .border({ width: { bottom: 1 }, color: '#F1F4F8' })
        .onClick(() => {
          action(option);
        });
      });
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 24, topRight: 24 })
    .padding({ left: 20, right: 20, bottom: 28 });
  }

  @Builder
  ExportSheet() {
    Column() {
      Column()
        .width(42)
        .height(5)
        .backgroundColor('#E5EAF3')
        .borderRadius(3)
        .margin({ top: 10, bottom: 18 });

      Text('导出数据')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor)
        .margin({ bottom: 10 });

      Text('以下为当前应用数据内容，可用于备份查看。')
        .fontSize(12)
        .fontColor(this.secondaryTextColor)
        .margin({ bottom: 14 });

      Scroll() {
        Text(this.exportContent)
          .width('100%')
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#6E7A90')
          .textAlign(TextAlign.Start);
      }
      .width('100%')
      .height(220)
      .backgroundColor('#F7F9FC')
      .borderRadius(16)
      .padding(14);

      Button('关闭')
        .width('100%')
        .height(44)
        .margin({ top: 18 })
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor(this.settings.themeColor)
        .borderRadius(24)
        .onClick(() => {
          this.activeSheet = '';
        });
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 24, topRight: 24 })
    .padding({ left: 20, right: 20, bottom: 28 });
  }
}
