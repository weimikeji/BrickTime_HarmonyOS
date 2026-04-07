import { storageService } from '../services/StorageService';
import { AppSettings, ReminderItem } from '../models/DataModels';
import { AppNavigationBar } from '../components/AppNavigationBar';

interface ThemeOption {
  name: string;
  color: string;
  description: string;
}

@Entry
@Component
export struct ThemeSettingsPage {
  private readonly pageBackground: string = '#F7F8FB';
  private readonly surfaceColor: string = '#FFFFFF';
  private readonly titleColor: string = '#3B3D45';
  private readonly secondaryTextColor: string = '#99A3B6';
  private readonly mutedTextColor: string = '#BAC3D4';
  private readonly rowBorderColor: string = '#F2F4F8';
  private readonly cardShadow: string = '#14000000';
  private readonly dismissFocusId: string = 'themeDismissFocus';

  @State settings: AppSettings = storageService.getSettings();

  aboutToAppear() {
    this.settings = storageService.getSettings();
  }

  private getThemeOptions(): ThemeOption[] {
    return [
      { name: '薄荷绿', color: '#63D5C2', description: '轻盈、干净，适合日常长期使用。' },
      { name: '晴空蓝', color: '#7FB7FF', description: '更明亮一点，页面会显得清爽通透。' },
      { name: '海盐青', color: '#72CFC5', description: '带一点海风感，柔和但不发灰。' },
      { name: '晨露绿', color: '#8BD8AE', description: '清透偏嫩，像清晨叶面上的水汽。' },
      { name: '雾霭蓝', color: '#8FB7E8', description: '安静耐看，适合偏克制的清新感。' },
      { name: '浅茶杏', color: '#F2B38F', description: '有一点暖意，让页面显得更柔软。' },
      { name: '樱雾粉', color: '#E8AFC2', description: '轻甜但不艳，适合更细腻的气质。' },
      { name: '柔雾紫', color: '#B08CFF', description: '柔和偏安静，适合偏沉浸的氛围。' },
      { name: '月灰蓝', color: '#9BAFC8', description: '偏中性、干净，整体会更克制一些。' },
      { name: '暖橙色', color: '#FF9A5E', description: '更有活力，适合想要明显反馈感的场景。' }
    ];
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

  private applyTheme(color: string) {
    const nextSettings = this.cloneSettings();
    nextSettings.themeColor = color;
    this.settings = nextSettings;
    storageService.saveSettings(nextSettings);
  }

  private dismissKeyboard() {
    focusControl.requestFocus(this.dismissFocusId);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column() {
          AppNavigationBar({
            title: '主题风格',
            titleColor: this.titleColor,
            surfaceColor: this.surfaceColor
          });

          Column() {
            this.PreviewCard();

            ForEach(this.getThemeOptions(), (option: ThemeOption) => {
              this.ThemeOptionRow(option);
            });
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 56 });
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.pageBackground)
      .scrollBar(BarState.Off)
      .onClick(() => {
        this.dismissKeyboard();
      });

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
  PreviewCard() {
    Column() {
      Text('当前主题')
        .width('100%')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.secondaryTextColor);

      Row() {
        Column()
          .width(18)
          .height(18)
          .backgroundColor(this.settings.themeColor)
          .borderRadius(9)
          .margin({ right: 12 });

        Column() {
          Text(this.getThemeOptions().find((item: ThemeOption) => item.color === this.settings.themeColor)?.name ?? '默认主题')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.titleColor);

          Text('主题色会用于页面中的高亮与状态强调。')
            .fontSize(12)
            .fontColor(this.secondaryTextColor)
            .margin({ top: 4 });
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%')
      .margin({ top: 14 });
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(16)
    .padding(16)
    .shadow({ radius: 18, color: this.cardShadow, offsetX: 0, offsetY: 6 })
    .margin({ bottom: 18 });
  }

  @Builder
  ThemeOptionRow(option: ThemeOption) {
    Row() {
      Column()
        .width(18)
        .height(18)
        .backgroundColor(option.color)
        .borderRadius(9)
        .margin({ right: 12 });

      Column() {
        Text(option.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.titleColor);

        Text(option.description)
          .fontSize(12)
          .fontColor(this.secondaryTextColor)
          .margin({ top: 4 });
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);

      if (option.color === this.settings.themeColor) {
        Text('✓')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(option.color);
      }
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(16)
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .margin({ bottom: 12 })
    .shadow({ radius: 18, color: this.cardShadow, offsetX: 0, offsetY: 6 })
    .border({
      width: option.color === this.settings.themeColor ? 1.5 : 0,
      color: option.color === this.settings.themeColor ? option.color : this.rowBorderColor
    })
    .onClick(() => {
      this.applyTheme(option.color);
    });
  }
}
