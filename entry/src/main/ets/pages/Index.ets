import { TodayPage } from './TodayPage';
import { RecordPage } from './RecordPage';
import { GrowthPage } from './GrowthPage';
import { storageService } from '../services/StorageService';
import { AppSettings, Record, ReminderItem } from '../models/DataModels';
import { DateUtils } from '../utils/DateUtils';
import { RouterManager } from '../router/RouterManager';
import { EventBus, Events } from '../services/EventBus';
import { ThemeUtils } from '../utils/ThemeUtils';
import { reminderService } from '../services/ReminderService';

interface DrawerMenuItem {
  title: string;
  action: string;
}

interface BottomTabItem {
  title: string;
  badgeText?: string;
  showDot?: boolean;
}

@Entry
@Component
struct Index {
  private readonly pageBackground: string = '#F7F8FB';
  private readonly surfaceColor: string = '#FFFFFF';
  private readonly titleColor: string = '#3B3D45';
  private readonly secondaryTextColor: string = '#99A3B6';
  private readonly mutedTextColor: string = '#C7CFDC';
  private readonly cardShadow: string = '#14000000';
  private readonly dismissFocusId: string = 'indexDismissFocus';
  private readonly rowBorderColor: string = '#F2F4F8';
  private readonly dangerColor: string = '#FF6C6C';
  private readonly privacyPolicyUrl: string = 'https://www.baidu.com';
  private readonly termsOfServiceUrl: string = 'https://www.baidu.com';
  private readonly aboutUsUrl: string = 'https://example.com/about';
  private readonly tabBarHeight: number = 56;
  private readonly tabBarBottomInset: number = 14;
  private readonly tabBarHorizontalInset: number = 24;
  private readonly tabBarRadius: number = 20;
  private readonly tabSurfaceColor: string = '#FFFFFF';
  private readonly tabBorderColor: string = '#F1F4F8';
  private readonly tabInactiveColor: string = '#A7B1C2';
  private readonly tabLabelColor: string = '#94A0B5';
  private readonly tabSelectedLabelColor: string = '#4B5567';
  private readonly tabShadowColor: string = '#120B1A2B';
  private readonly tabBadgeColor: string = '#FF8D86';
  private readonly tabConfigs: BottomTabItem[] = [
    { title: '今日' },
    { title: '记录' },
    { title: '成长' }
  ];

  @State currentIndex: number = 0;
  @State showDrawer: boolean = false;
  @State allRecords: Record[] = [];
  @State themeColor: string = ThemeUtils.getThemeColor();
  @State settings: AppSettings = storageService.getSettings();
  @State reminderPermissionStatus: string = '未开启';
  @StorageProp('drawerTotalRecords') totalRecords: number = 0;
  @StorageProp('drawerStreakDays') streakDays: number = 0;
  @StorageProp('drawerRecentStatus') recentStatus: string = '未开始';
  @State drawerStatsRenderKey: string = 'drawer-stats-initial';
  @StorageProp('homeDrawerVisible') homeDrawerVisible: boolean = false;
  @StorageProp('homeTabBarHidden') homeTabBarHidden: boolean = false;
  @State todayTabScale: number = 1;
  @State recommendTabScale: number = 1;
  @State recordTabScale: number = 1;
  @State todayTabIconOffset: number = 0;
  @State recommendTabIconOffset: number = 0;
  @State recordTabIconOffset: number = 0;

  private settingsChangedHandler = () => {
    this.themeColor = ThemeUtils.getThemeColor();
    this.loadDrawerData();
  };

  private drawerOpenHandler = () => {
    this.loadDrawerData();
    this.showDrawer = true;
  };

  private drawerDataChangedHandler = () => {
    this.loadDrawerData();
  };

  aboutToAppear() {
    EventBus.on(Events.HOME_DRAWER_OPEN, this.drawerOpenHandler);
    EventBus.on(Events.SETTINGS_CHANGED, this.settingsChangedHandler);
    EventBus.on(Events.RECORD_ADDED, this.drawerDataChangedHandler);
    EventBus.on(Events.RECORD_UPDATED, this.drawerDataChangedHandler);
    EventBus.on(Events.RECORD_DELETED, this.drawerDataChangedHandler);
    EventBus.on(Events.TAG_UPDATED, this.drawerDataChangedHandler);
    this.loadDrawerData();
    this.themeColor = ThemeUtils.getThemeColor();
  }

  aboutToDisappear() {
    EventBus.off(Events.HOME_DRAWER_OPEN, this.drawerOpenHandler);
    EventBus.off(Events.SETTINGS_CHANGED, this.settingsChangedHandler);
    EventBus.off(Events.RECORD_ADDED, this.drawerDataChangedHandler);
    EventBus.off(Events.RECORD_UPDATED, this.drawerDataChangedHandler);
    EventBus.off(Events.RECORD_DELETED, this.drawerDataChangedHandler);
    EventBus.off(Events.TAG_UPDATED, this.drawerDataChangedHandler);
  }

  private loadDrawerData() {
    this.allRecords = storageService.getRecords();
    this.settings = storageService.getSettings();
    this.reminderPermissionStatus = reminderService.isReminderPermissionGranted() ? '已开启' : '未开启';
    this.totalRecords = this.computeTotalRecords(this.allRecords);
    this.streakDays = this.computeStreakDays(this.allRecords);
    this.recentStatus = this.computeRecentStatus(this.allRecords);
    AppStorage.setOrCreate('drawerTotalRecords', this.totalRecords);
    AppStorage.setOrCreate('drawerStreakDays', this.streakDays);
    AppStorage.setOrCreate('drawerRecentStatus', this.recentStatus);
    this.drawerStatsRenderKey = `${this.totalRecords}-${this.streakDays}-${this.recentStatus}-${Date.now()}`;
  }

  private getPrimaryMenu(): DrawerMenuItem[] {
    const items: DrawerMenuItem[] = [
      { title: '标签管理', action: 'tag' },
      { title: '提醒设置', action: 'reminder' },
      { title: '主题风格', action: 'theme' }
    ];
    return items;
  }

  private computeTotalRecords(records: Record[]): number {
    return records.length;
  }

  private computeRecentStatus(records: Record[]): string {
    const today = DateUtils.getToday();
    const todayCount = records.filter((record: Record) => record.date === today).length;
    if (todayCount > 0) {
      return '今天';
    }
    if (records.length === 0) {
      return '未开始';
    }
    const latest = [...records].sort((a: Record, b: Record) => b.createdAt - a.createdAt)[0];
    const date = DateUtils.parseDate(latest.date);
    return `${date.getMonth() + 1}.${date.getDate()}`;
  }

  private getActiveDays(records: Record[]): string[] {
    const uniqueDays: string[] = [];
    records.forEach((record: Record) => {
      if (!uniqueDays.includes(record.date)) {
        uniqueDays.push(record.date);
      }
    });
    uniqueDays.sort();
    return uniqueDays;
  }

  private computeStreakDays(records: Record[]): number {
    const activeDays = this.getActiveDays(records);
    if (activeDays.length === 0) {
      return 0;
    }

    let streak = 0;
    let expectedDate = DateUtils.parseDate(DateUtils.getToday());
    const activeSet = new Set<string>(activeDays);

    while (activeSet.has(DateUtils.formatDate(expectedDate))) {
      streak += 1;
      expectedDate = new Date(expectedDate.getTime() - 24 * 60 * 60 * 1000);
    }

    if (streak === 0) {
      const latest = DateUtils.parseDate(activeDays[activeDays.length - 1]);
      let fallback = latest;
      while (activeSet.has(DateUtils.formatDate(fallback))) {
        streak += 1;
        fallback = new Date(fallback.getTime() - 24 * 60 * 60 * 1000);
      }
    }
    return streak;
  }

  private closeDrawer() {
    this.showDrawer = false;
    AppStorage.setOrCreate('homeDrawerVisible', false);
  }

  private handleDrawerAction(action: string) {
    if (action === 'record') {
      this.closeDrawer();
      RouterManager.goToRecord();
      return;
    }
    if (action === 'tag') {
      this.closeDrawer();
      RouterManager.goToTagManage();
      return;
    }
    if (action === 'reminder') {
      this.closeDrawer();
      RouterManager.goToReminderSettings();
      return;
    }
    if (action === 'theme') {
      this.closeDrawer();
      RouterManager.goToThemeSettings();
      return;
    }
  }

  private showInfoDialog(title: string, message: string) {
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

  private cloneSettings(): AppSettings {
    return {
      dailyReminder: this.settings.dailyReminder,
      reminderTime: this.settings.reminderTime,
      reminderTimes: this.settings.reminderTimes.map((item: ReminderItem): ReminderItem => {
        return {
          id: item.id,
          title: item.title,
          time: item.time
        };
      }),
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
    this.settings = nextSettings;
    storageService.saveSettings(nextSettings);
  }

  private openWebContent(title: string, url: string) {
    this.closeDrawer();
    RouterManager.goToWebView(title, url);
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
          AppStorage.setOrCreate('drawerTotalRecords', 0);
          AppStorage.setOrCreate('drawerStreakDays', 0);
          AppStorage.setOrCreate('drawerRecentStatus', '未开始');
          storageService.clearAll();
          this.allRecords = [];
          this.totalRecords = 0;
          this.streakDays = 0;
          this.recentStatus = '未开始';
          this.drawerStatsRenderKey = `0-0-未开始-${Date.now()}`;
          this.settings = storageService.getSettings();
          this.loadDrawerData();
        }
      }
    });
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Stack() {
        if (this.currentIndex === 0) {
          TodayPage();
        } else if (this.currentIndex === 1) {
          RecordPage();
        } else {
          GrowthPage();
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.pageBackground)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .onClick(() => {
        this.dismissKeyboard();
      });

      if (!this.homeTabBarHidden) {
        Row() {
          this.BottomNav();
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Bottom)
        .zIndex(1);
      }

      if (this.showDrawer || this.homeDrawerVisible) {
        this.DrawerOverlay();
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
  DrawerOverlay() {
    Stack({ alignContent: Alignment.Start }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#22000000')
        .onClick(() => {
          this.closeDrawer();
        });

      this.SideDrawer();
    }
    .width('100%')
    .height('100%')
    .zIndex(20);
  }

  @Builder
  SideDrawer() {
    Scroll() {
      Column() {
        this.DrawerHeader();
        this.DrawerMenuSection();
        this.DrawerSettingsSection();

        Text('版本 1.0.0')
          .fontSize(11)
          .fontColor(this.mutedTextColor)
          .margin({ top: 18, bottom: 34 });
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 44, bottom: 40 });
    }
    .width('82%')
    .height('100%')
    .backgroundColor(this.surfaceColor)
    .scrollBar(BarState.Off);
  }

  @Builder
  DrawerHeader() {
    Column() {
      Stack() {
        Image($r('app.media.startIcon'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .borderRadius(20);

        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(ThemeUtils.withAlpha(this.themeColor, '08'))
          .borderRadius(20);
      }
      .width(64)
      .height(64)
      .clip(true)
      .borderRadius(20)
      .shadow({ radius: 16, color: ThemeUtils.withAlpha(this.themeColor, '12'), offsetX: 0, offsetY: 6 })
      .margin({ bottom: 18 });

      Text('积木玩家')
        .width('100%')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor);

      Text('你已经在慢慢搭建自己的节奏')
        .width('100%')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.secondaryTextColor)
        .margin({ top: 8 });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  DrawerStats() {
    Row() {
      this.StatsItem(`${this.streakDays}`, '连续天数');
      this.StatsItem(`${this.totalRecords}`, '累计记录');
      this.StatsItem(this.recentStatus, '最近活跃');
    }
    .width('100%')
    .height(92)
    .backgroundColor('#FBFCFE')
    .borderRadius(18)
    .padding({ left: 8, right: 8 })
    .margin({ top: 24 })
    .key(this.drawerStatsRenderKey)
    .shadow({ radius: 18, color: this.cardShadow, offsetX: 0, offsetY: 8 });
  }

  @Builder
  DrawerMenuSection() {
    Column() {
      this.DrawerSectionTitle('常用功能');

      Column() {
        ForEach(this.getPrimaryMenu(), (item: DrawerMenuItem, index: number) => {
          this.DrawerMenuRow(item, index === this.getPrimaryMenu().length - 1);
        });
      }
      .width('100%')
      .backgroundColor(this.surfaceColor)
      .borderRadius(16)
      .padding({ left: 14, right: 14 })
      .shadow({ radius: 18, color: this.cardShadow, offsetX: 0, offsetY: 6 });
    }
    .width('100%')
    .margin({ top: 18 });
  }

  @Builder
  StatsItem(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColor);

      Text(label)
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.secondaryTextColor)
        .margin({ top: 8 });
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  DrawerMenuRow(item: DrawerMenuItem, isLast: boolean = false) {
    Row() {
      Text(item.title)
        .layoutWeight(1)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.titleColor);

      Text('›')
        .fontSize(18)
        .fontColor(this.mutedTextColor);
    }
    .width('100%')
    .height(54)
    .border({
      width: { bottom: isLast ? 0 : 1 },
      color: this.rowBorderColor
    })
    .onClick(() => {
      this.handleDrawerAction(item.action);
    });
  }

  @Builder
  DrawerSettingsSection() {
    Column() {
      this.DrawerSectionTitle('快捷设置');
      Column() {
        this.DrawerSwitchRow('震动反馈', this.settings.hapticFeedback, () => {
          this.toggleHapticFeedback();
        });
        this.DrawerValueRow('通知权限', this.reminderPermissionStatus, () => {
          this.showInfoDialog('通知权限', '提醒通知权限由提醒设置页按需申请。若当前显示未开启，请前往“提醒设置”打开每日提醒后完成授权。');
        });
        this.DrawerActionRow('隐私政策', () => {
          this.openWebContent('隐私政策', this.privacyPolicyUrl);
        });
        this.DrawerActionRow('使用条款', () => {
          this.openWebContent('使用条款', this.termsOfServiceUrl);
        });
        this.DrawerActionRow('关于我们', () => {
          this.openWebContent('关于我们', this.aboutUsUrl);
        });
        this.DrawerActionRow('清空所有数据', () => {
          this.showClearDataDialog();
        }, true, true);
      }
      .width('100%')
      .backgroundColor(this.surfaceColor)
      .borderRadius(16)
      .padding({ left: 14, right: 14 })
      .shadow({ radius: 18, color: this.cardShadow, offsetX: 0, offsetY: 6 });
    }
    .width('100%')
    .margin({ top: 18 });
  }

  @Builder
  DrawerSectionTitle(title: string) {
    Text(title)
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.mutedTextColor)
      .margin({ left: 2, bottom: 10, top: 2 });
  }

  @Builder
  DrawerSwitchRow(title: string, isOn: boolean, action: () => void, isLast: boolean = false) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.titleColor)
        .layoutWeight(1);

      this.DrawerSwitchView(isOn);
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
  DrawerValueRow(title: string, value: string, action: () => void, isLast: boolean = false) {
    Row() {
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
  DrawerActionRow(title: string, action: () => void, isDestructive: boolean = false, isLast: boolean = false) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(isDestructive ? this.dangerColor : this.titleColor)
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
  DrawerSwitchView(isOn: boolean) {
    Stack({ alignContent: isOn ? Alignment.End : Alignment.Start }) {
      Column()
        .width(30)
        .height(18)
        .backgroundColor(isOn ? this.themeColor : '#E7EBF2')
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
  BottomNav() {
    Row() {
      ForEach(this.tabConfigs, (item: BottomTabItem, index: number) => {
        this.NavItem(item, index);
      });
    }
    .width('88%')
    .height(this.tabBarHeight)
    .margin({ top: 8, bottom: this.tabBarBottomInset })
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .backgroundColor(this.tabSurfaceColor)
    .borderRadius(this.tabBarRadius)
    .border({ width: 1, color: this.tabBorderColor })
    .shadow({
      radius: 20,
      color: this.tabShadowColor,
      offsetX: 0,
      offsetY: 10
    })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignSelf(ItemAlign.Center)
    .zIndex(1);
  }

  @Builder
  NavItem(item: BottomTabItem, index: number) {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(44)
          .height(30)
          .borderRadius(15)
          .backgroundColor(this.isTabSelected(index) ? ThemeUtils.withAlpha(this.themeColor, '18') : '#00FFFFFF')
          .animation({ duration: 220, curve: Curve.EaseInOut });

        this.NavIcon(item, index);
        this.TabBadge(item, index);
      }
      .width(48)
      .height(32);

      Text(item.title)
        .fontSize(11)
        .fontWeight(this.isTabSelected(index) ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.isTabSelected(index) ? this.tabSelectedLabelColor : this.tabLabelColor)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .margin({ top: 3 })
        .animation({ duration: 220, curve: Curve.EaseInOut });
    }
    .width(82)
    .height(this.tabBarHeight - 12)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(18)
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      this.selectTab(index);
    });
  }

  @Builder
  NavIcon(item: BottomTabItem, index: number) {
    Stack({ alignContent: Alignment.Center }) {
      if (index === 0) {
        this.TodayTabIcon(index);
      } else if (index === 1) {
        this.RecordTabIcon(index);
      } else {
        this.GrowthTabIcon(index);
      }
    }
    .width(22)
    .height(22)
    .translate({ y: this.getTabIconOffset(index) })
    .scale({ x: this.getTabScale(index), y: this.getTabScale(index) })
    .animation({ duration: 200, curve: Curve.EaseInOut });
  }

  @Builder
  TabBadge(item: BottomTabItem, index: number) {
    if (item.badgeText !== undefined && item.badgeText !== '') {
      Text(item.badgeText)
        .fontSize(9)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .padding({ left: 5, right: 5, top: 1, bottom: 1 })
        .backgroundColor(this.tabBadgeColor)
        .borderRadius(8)
        .position({ x: 30, y: 2 });
    } else if (item.showDot && index !== this.currentIndex) {
      Column()
        .width(6)
        .height(6)
        .borderRadius(3)
        .backgroundColor(this.tabBadgeColor)
        .position({ x: 31, y: 6 });
    }
  }

  @Builder
  TodayTabIcon(index: number) {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(18)
        .height(16)
        .border({
          color: this.getTabIconColor(index),
          width: 1.8
        })
        .borderRadius(4)
        .margin({ top: 3 });

      Row() {
        Column()
          .width(2.4)
          .height(4)
          .backgroundColor(this.getTabIconColor(index))
          .borderRadius(1.2);

        Blank();

        Column()
          .width(2.4)
          .height(4)
          .backgroundColor(this.getTabIconColor(index))
          .borderRadius(1.2);
      }
      .width(10)
      .position({ x: 6, y: 0 });

      Row()
        .width(18)
        .backgroundColor(this.getTabIconColor(index))
        .borderRadius(1)
        .height(1.8)
        .position({ x: 2, y: 8 });
    }
    .width(22)
    .height(22);
  }

  @Builder
  GrowthTabIcon(index: number) {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(18)
        .height(18)
        .border({
          color: this.getTabIconColor(index),
          width: 1.8
        })
        .borderRadius(4);

      Row() {
        this.GrowthBar(index, 6);
        this.GrowthBar(index, 10);
        this.GrowthBar(index, 13);
      }
      .width(10)
      .height(12)
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Bottom)
      .margin({ bottom: 3 });

      Row() {
        Column()
          .width(12)
          .height(1.8)
          .backgroundColor(this.getTabIconColor(index))
          .borderRadius(1);

        Column()
          .width(1.8)
          .height(12)
          .backgroundColor(this.getTabIconColor(index))
          .borderRadius(1)
          .margin({ left: -12, top: 0 });
      }
      .width(12)
      .height(12)
      .position({ x: 3, y: 3 });
    }
    .width(22)
    .height(22);
  }

  @Builder
  GrowthBar(index: number, height: number) {
    Column()
      .width(2)
      .height(height)
      .backgroundColor(this.getTabIconColor(index))
      .borderRadius(1);
  }

  @Builder
  RecordTabIcon(index: number) {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(18)
        .height(18)
        .border({
          color: this.getTabIconColor(index),
          width: 1.8
        })
        .borderRadius(4);

      Column() {
        this.RecordLine(index, 10);
        this.RecordLine(index, 10);
        this.RecordLine(index, 7);
      }
      .width(10)
      .height(9.5)
      .justifyContent(FlexAlign.SpaceBetween);
    }
    .width(22)
    .height(22);
  }

  @Builder
  RecordLine(index: number, width: number) {
    Row()
      .width(width)
      .height(1.8)
      .backgroundColor(this.getTabIconColor(index))
      .borderRadius(1);
  }

  private selectTab(index: number) {
    if (this.currentIndex === index) {
      this.playTabFeedback(index, true);
      return;
    }

    this.playTabFeedback(index, false);
    animateTo({ duration: 180, curve: Curve.EaseInOut }, () => {
      this.currentIndex = index;
    });
  }

  private isTabSelected(index: number): boolean {
    return this.currentIndex === index;
  }

  private getTabIconColor(index: number): string {
    return this.isTabSelected(index) ? this.themeColor : this.tabInactiveColor;
  }

  private playTabFeedback(index: number, selectedAgain: boolean) {
    this.setTabScale(index, 1.08);
    this.setTabIconOffset(index, index === 2 ? -2 : -1);

    animateTo({ duration: 110, curve: Curve.EaseOut }, () => {
      this.setTabScale(index, selectedAgain && index === 2 ? 1.05 : 1.08);
      this.setTabIconOffset(index, index === 2 ? -3 : -2);
    });

    animateTo({ duration: 210, curve: Curve.EaseInOut, delay: 90 }, () => {
      this.setTabScale(index, 1);
      this.setTabIconOffset(index, 0);
    });
  }

  private getTabScale(index: number): number {
    if (index === 0) {
      return this.todayTabScale;
    }
    if (index === 1) {
      return this.recommendTabScale;
    }
    return this.recordTabScale;
  }

  private setTabScale(index: number, value: number) {
    if (index === 0) {
      this.todayTabScale = value;
      return;
    }
    if (index === 1) {
      this.recommendTabScale = value;
      return;
    }
    this.recordTabScale = value;
  }

  private getTabIconOffset(index: number): number {
    if (index === 0) {
      return this.todayTabIconOffset;
    }
    if (index === 1) {
      return this.recommendTabIconOffset;
    }
    return this.recordTabIconOffset;
  }

  private setTabIconOffset(index: number, value: number) {
    if (index === 0) {
      this.todayTabIconOffset = value;
      return;
    }
    if (index === 1) {
      this.recommendTabIconOffset = value;
      return;
    }
    this.recordTabIconOffset = value;
  }
}
