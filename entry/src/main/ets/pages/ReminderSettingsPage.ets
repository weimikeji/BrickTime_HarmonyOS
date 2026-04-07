import { reminderService } from '../services/ReminderService';
import { storageService } from '../services/StorageService';
import { AppSettings, ReminderItem } from '../models/DataModels';
import { EventBus, Events } from '../services/EventBus';
import { AppNavigationBar } from '../components/AppNavigationBar';

interface BusinessErrorInfo {
  code?: number;
  message?: string;
}

@Entry
@Component
export struct ReminderSettingsPage {
  private readonly pageBackground: string = '#F7F8FB';
  private readonly surfaceColor: string = '#FFFFFF';
  private readonly titleColor: string = '#3B3D45';
  private readonly secondaryTextColor: string = '#99A3B6';
  private readonly mutedTextColor: string = '#BAC3D4';
  private readonly rowBorderColor: string = '#F2F4F8';
  private readonly cardShadow: string = '#14000000';
  private readonly dangerColor: string = '#FF6C6C';
  private readonly dismissFocusId: string = 'reminderDismissFocus';

  @State settings: AppSettings = storageService.getSettings();
  @State activeSheet: string = '';
  @State editingReminderId: string = '';
  @State draftTitle: string = '';
  @State draftTime: string = '21:00';

  aboutToAppear() {
    EventBus.on(Events.SETTINGS_CHANGED, this.handleSettingsChanged);
    this.settings = storageService.getSettings();
  }

  aboutToDisappear() {
    EventBus.off(Events.SETTINGS_CHANGED, this.handleSettingsChanged);
  }

  private handleSettingsChanged = () => {
    this.settings = storageService.getSettings();
  };

  private createTimeDate(time: string): Date {
    const parts = time.split(':');
    const hour = Number(parts[0]);
    const minute = Number(parts[1]);
    const date = new Date();
    date.setHours(Number.isNaN(hour) ? 21 : hour);
    date.setMinutes(Number.isNaN(minute) ? 0 : minute);
    date.setSeconds(0);
    date.setMilliseconds(0);
    return date;
  }

  private formatTime(hour: number, minute: number): string {
    const hourText = hour < 10 ? `0${hour}` : `${hour}`;
    const minuteText = minute < 10 ? `0${minute}` : `${minute}`;
    return `${hourText}:${minuteText}`;
  }

  private updateSettings(nextSettings: AppSettings) {
    this.settings = nextSettings;
    storageService.saveSettings(nextSettings);
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

  private toggleHapticFeedback() {
    const nextSettings = this.cloneSettings();
    nextSettings.hapticFeedback = !this.settings.hapticFeedback;
    this.updateSettings(nextSettings);
  }

  private buildReminderId(time: string): string {
    return `reminder-${Date.now()}-${time.replace(':', '-')}`;
  }

  private syncReminderSummary(nextSettings: AppSettings): AppSettings {
    const sorted = [...nextSettings.reminderTimes].sort((left: ReminderItem, right: ReminderItem) => {
      return left.time.localeCompare(right.time);
    });
    nextSettings.reminderTimes = sorted;
    nextSettings.reminderTime = sorted[0]?.time ?? '21:00';
    nextSettings.dailyReminder = sorted.length > 0 ? nextSettings.dailyReminder : false;
    return nextSettings;
  }

  private getErrorMessage(error: Object): string {
    const businessError = error as BusinessErrorInfo;
    if (businessError.code === 1700002 || businessError.code === 17700002) {
      const messageText = businessError.message && businessError.message.trim() !== ''
        ? businessError.message
        : '系统里已有未清理完成的提醒。';
      return `系统提醒数量超出限制。\n错误码：${businessError.code}\n${messageText}`;
    }
    const codeText = businessError.code !== undefined ? `错误码：${businessError.code}` : '错误码未知';
    const messageText = businessError.message && businessError.message.trim() !== ''
      ? businessError.message
      : '系统没有返回更详细的信息。';
    return `${codeText}\n${messageText}`;
  }

  private async syncReminderSchedule(nextSettings: AppSettings): Promise<void> {
    if (!nextSettings.dailyReminder) {
      await reminderService.disableDailyReminder();
      return;
    }
    await reminderService.updateReminderTime(nextSettings);
  }

  private async handleReminderToggle() {
    const nextSettings = this.cloneSettings();
    if (this.settings.dailyReminder) {
      nextSettings.dailyReminder = false;
      this.updateSettings(nextSettings);
      await reminderService.disableDailyReminder();
      return;
    }

    try {
      nextSettings.dailyReminder = true;
      const enabled = await reminderService.enableDailyReminder(nextSettings);
      if (!enabled) {
        this.showTextDialog('提醒未开启', '系统通知授权或提醒权限还没有开启，所以还不能为你创建本地提醒。你可以再试一次，系统会弹出授权提示。');
        return;
      }
      this.updateSettings(nextSettings);
    } catch (error) {
      this.showTextDialog('提醒创建失败', `系统提醒暂时没有创建成功。\n${this.getErrorMessage(error as Object)}`);
    }
  }

  private openReminderSheet(reminderId: string = '') {
    this.editingReminderId = reminderId;
    const currentReminder = this.settings.reminderTimes.find((item: ReminderItem) => item.id === reminderId);
    this.draftTitle = currentReminder?.title ?? '';
    this.draftTime = currentReminder?.time ?? '21:00';
    this.activeSheet = 'reminder';
  }

  private updateDraftTime(hour: number, minute: number) {
    this.draftTime = this.formatTime(hour, minute);
  }

  private async saveReminderDraft() {
    const title = this.draftTitle.trim();
    if (title === '') {
      this.showTextDialog('请输入标题', '给这条提醒起个标题，通知来了你会更容易分辨。');
      return;
    }

    const nextSettings = this.cloneSettings();
    const duplicatedReminder = nextSettings.reminderTimes.find((item: ReminderItem) => {
      return item.time === this.draftTime && item.id !== this.editingReminderId;
    });
    if (duplicatedReminder) {
      this.showTextDialog('时间已存在', '这个提醒时间已经添加过了，换一个时间试试。');
      return;
    }

    if (this.editingReminderId === '') {
      const createdReminder: ReminderItem = {
        id: this.buildReminderId(this.draftTime),
        title: title,
        time: this.draftTime
      };
      nextSettings.reminderTimes.push(createdReminder);
    } else {
      nextSettings.reminderTimes = nextSettings.reminderTimes.map((item: ReminderItem): ReminderItem => {
        if (item.id === this.editingReminderId) {
          const updatedReminder: ReminderItem = {
            id: item.id,
            title: title,
            time: this.draftTime
          };
          return updatedReminder;
        }
        return this.cloneReminderItem(item);
      });
    }

    this.syncReminderSummary(nextSettings);
    this.updateSettings(nextSettings);
    this.activeSheet = '';
    this.editingReminderId = '';
    this.draftTitle = '';

    try {
      await this.syncReminderSchedule(nextSettings);
    } catch (error) {
      this.showTextDialog('提醒更新时间失败', `时间已经保存，但本地通知暂时没有更新成功。\n${this.getErrorMessage(error as Object)}`);
    }
  }

  private async removeReminder(reminderId: string) {
    const nextSettings = this.cloneSettings();
    if (nextSettings.reminderTimes.length <= 1) {
      this.showTextDialog('至少保留一个', '如果你不想接收提醒，可以直接关闭“每日提醒”。');
      return;
    }

    nextSettings.reminderTimes = nextSettings.reminderTimes.filter((item: ReminderItem) => item.id !== reminderId);
    this.syncReminderSummary(nextSettings);
    this.updateSettings(nextSettings);

    try {
      await this.syncReminderSchedule(nextSettings);
    } catch (error) {
      this.showTextDialog('提醒删除失败', `列表已经更新，但本地通知暂时没有同步成功。\n${this.getErrorMessage(error as Object)}`);
    }
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

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column() {
          AppNavigationBar({
            title: '提醒设置',
            titleColor: this.titleColor,
            surfaceColor: this.surfaceColor
          });

          Column() {
            this.NotificationSection();
            this.TipsCard();
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 32 });
        }
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .width('100%');
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
  NotificationSection() {
    Column() {
      this.SwitchRow('◔', '每日提醒', this.settings.dailyReminder, () => {
        this.handleReminderToggle();
      });
      this.SwitchRow('≋', '震动反馈', this.settings.hapticFeedback, () => {
        this.toggleHapticFeedback();
      }, true);
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(16)
    .padding({ left: 14, right: 14 })
    .shadow({ radius: 18, color: this.cardShadow, offsetX: 0, offsetY: 6 })
    .margin({ bottom: 14 });

    Column() {
      this.ReminderListHeader();

      ForEach(this.settings.reminderTimes, (item: ReminderItem) => {
        this.ReminderTimeRow(item);
      });

      this.AddReminderRow();
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(16)
    .padding({ left: 14, right: 14, top: 4, bottom: 4 })
    .shadow({ radius: 18, color: this.cardShadow, offsetX: 0, offsetY: 6 });
  }

  @Builder
  ReminderListHeader() {
    Row() {
      Text('提醒时间')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.titleColor)
        .layoutWeight(1);

      Text(`${this.settings.reminderTimes.length} 个`)
        .fontSize(12)
        .fontColor(this.secondaryTextColor);
    }
    .width('100%')
    .height(48)
    .border({ width: { bottom: 1 }, color: this.rowBorderColor });
  }

  @Builder
  ReminderTimeRow(item: ReminderItem) {
    Row() {
      Column()
        .width(10)
        .height(10)
        .borderRadius(5)
        .backgroundColor(this.settings.dailyReminder ? this.settings.themeColor : '#D4D9E3')
        .margin({ right: 12 });

      Text(item.time)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.titleColor)
        .width(64);

      Text(item.title)
        .fontSize(14)
        .fontColor(this.titleColor)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: 12 });

      Text('编辑')
        .fontSize(13)
        .fontColor(this.secondaryTextColor)
        .margin({ right: 14 });

      Button() {
        this.TrashIcon(this.dangerColor);
      }
      .width(30)
      .height(30)
      .backgroundColor('#FFF1F1')
      .borderRadius(15)
      .onClick(() => {
        this.removeReminder(item.id);
      });
    }
    .width('100%')
    .height(52)
    .border({ width: { bottom: 1 }, color: this.rowBorderColor })
    .onClick(() => {
      this.openReminderSheet(item.id);
    });
  }

  @Builder
  AddReminderRow() {
    Row() {
      Text('+')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.settings.themeColor)
        .margin({ right: 12 });

      Text('新增提醒时间')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.settings.themeColor)
        .layoutWeight(1);

      Text('›')
        .fontSize(18)
        .fontColor(this.mutedTextColor);
    }
    .width('100%')
    .height(52)
    .onClick(() => {
      this.openReminderSheet();
    });
  }

  @Builder
  TrashIcon(color: string) {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(11)
        .height(10)
        .border({ width: 1.6, color: color })
        .borderRadius(2)
        .translate({ y: 2 });

      Column()
        .width(13)
        .height(1.6)
        .backgroundColor(color)
        .borderRadius(1)
        .translate({ y: -5 });

      Column()
        .width(6)
        .height(1.6)
        .backgroundColor(color)
        .borderRadius(1)
        .translate({ y: -7 });
    }
  }

  @Builder
  TipsCard() {
    Column() {
      Text('到达提醒时间后，系统会通过本地推送通知你。你可以添加多个时间点，适合早中晚多次提醒。')
        .fontSize(13)
        .lineHeight(20)
        .fontColor(this.secondaryTextColor);

      Text('第一次开启时，系统会弹出通知授权提示；只有授权成功后，到点才会真正提醒。')
        .fontSize(12)
        .fontColor(this.mutedTextColor)
        .margin({ top: 10 });

      Text('点进时间行可以编辑，右侧删除按钮可以移除某个提醒。')
        .fontSize(12)
        .fontColor(this.mutedTextColor)
        .margin({ top: 8 });
    }
    .width('100%')
    .backgroundColor('#F1F8F6')
    .borderRadius(16)
    .padding(16)
    .margin({ top: 16 });
  }

  @Builder
  SwitchRow(icon: string, title: string, isOn: boolean, action: () => void, isLast: boolean = false) {
    Row() {
      this.LeadingIcon(icon);

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
  LeadingIcon(icon: string) {
    Text(icon)
      .width(20)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .textAlign(TextAlign.Center)
      .fontColor('#9CA6B9')
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
          this.editingReminderId = '';
          this.draftTitle = '';
        });

      this.EditorSheet();
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  EditorSheet() {
    Column() {
      Column()
        .width(42)
        .height(5)
        .backgroundColor('#E5EAF3')
        .borderRadius(3)
        .margin({ top: 10, bottom: 18 });

      Text(this.editingReminderId === '' ? '新增提醒' : '编辑提醒')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor)
        .margin({ bottom: 16 });

      Text('提醒标题')
        .width('100%')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.secondaryTextColor)
        .margin({ bottom: 10 });

      TextInput({ placeholder: '例如：喝水、复盘、运动', text: $$this.draftTitle })
        .width('100%')
        .height(44)
        .fontSize(14)
        .fontColor(this.titleColor)
        .placeholderColor(this.secondaryTextColor)
        .backgroundColor('#F7F9FC')
        .borderRadius(12)
        .padding({ left: 14, right: 14 })
        .margin({ bottom: 18 });

      Text('提醒时间')
        .width('100%')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.secondaryTextColor)
        .margin({ bottom: 10 });

      Column() {
        TimePicker({
          selected: this.createTimeDate(this.draftTime),
          format: TimePickerFormat.HOUR_MINUTE
        })
          .useMilitaryTime(true)
          .loop(true)
          .backgroundColor('#F7F9FC')
          .borderRadius(12)
          .onChange((value: TimePickerResult) => {
            this.updateDraftTime(value.hour, value.minute);
          });
      }
      .width('100%')
      .height(180)
      .backgroundColor('#F7F9FC')
      .borderRadius(16)
      .padding({ left: 8, right: 8, top: 8, bottom: 8 });

      Text(`当前时间：${this.draftTime}`)
        .fontSize(12)
        .fontColor(this.secondaryTextColor)
        .margin({ top: 12, bottom: 18 });

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.secondaryTextColor)
          .backgroundColor('#F5F7FA')
          .borderRadius(24)
          .onClick(() => {
            this.activeSheet = '';
            this.editingReminderId = '';
            this.draftTitle = '';
          });

        Button(this.editingReminderId === '' ? '创建' : '保存')
          .layoutWeight(1)
          .height(44)
          .margin({ left: 12 })
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor(this.settings.themeColor)
          .borderRadius(24)
          .onClick(() => {
            this.saveReminderDraft();
          });
      }
      .width('100%');
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 24, topRight: 24 })
    .padding({ left: 20, right: 20, bottom: 28 });
  }
}
