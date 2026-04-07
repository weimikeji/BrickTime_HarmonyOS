import { router } from '@kit.ArkUI';
import { storageService } from '../services/StorageService';
import { Record, Tag } from '../models/DataModels';
import { DateUtils } from '../utils/DateUtils';
import { RouterManager } from '../router/RouterManager';
import { TagStyleUtils } from '../utils/TagStyleUtils';
import { AppNavigationBar } from '../components/AppNavigationBar';

interface TagDetailRouteParams {
  tagId?: string;
}

@Entry
@Component
export struct TagDetailPage {
  private readonly pageBackground: string = '#F7F8FB';
  private readonly surfaceColor: string = '#FFFFFF';
  private readonly titleColor: string = '#3B3D45';
  private readonly secondaryTextColor: string = '#9AA3B7';
  private readonly mutedTextColor: string = '#C4CDDB';
  private readonly shadowColor: string = '#12000000';
  private readonly dismissFocusId: string = 'tagDetailDismissFocus';
  private readonly lineColor: string = '#EEF2F7';
  private readonly navigationHeight: number = 28;
  private readonly navigationGap: number = 18;

  @State tagId: string = '';
  @State tag: Tag | null = null;
  @State records: Record[] = [];
  @State today: string = DateUtils.getToday();

  aboutToAppear() {
    try {
      const params = router.getParams() as TagDetailRouteParams;
      if (params && params.tagId) {
        this.tagId = params.tagId;
      }
    } catch {
    }
    this.loadData();
  }

  private loadData() {
    const tags = storageService.getTags();
    this.tag = tags.find((item: Tag) => item.id === this.tagId) ?? null;
    this.records = storageService.getRecordsByDate(this.today)
      .filter((record: Record) => record.tagId === this.tagId)
      .sort((a: Record, b: Record) => b.createdAt - a.createdAt);
  }

  private getTagBackground(): string {
    if (!this.tag) {
      return '#F2F5FA';
    }
    return TagStyleUtils.getChipBackground(this.tag.color);
  }

  private getTagAccentColor(): string {
    if (!this.tag) {
      return '#63D5C2';
    }
    return this.tag.color;
  }

  private getDisplayDate(): string {
    const date = DateUtils.parseDate(this.today);
    return `${date.getMonth() + 1}月${date.getDate()}日`;
  }

  private getLatestTime(): string {
    if (this.records.length === 0) {
      return '--:--';
    }
    return this.getTimeText(this.records[0].createdAt);
  }

  private getTimeText(timestamp: number): string {
    const date = new Date(timestamp);
    const hour = String(date.getHours()).padStart(2, '0');
    const minute = String(date.getMinutes()).padStart(2, '0');
    return `${hour}:${minute}`;
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (!this.tag) {
        Column() {
          this.NavigationSpacer();
          this.EmptyState();
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .padding({ left: 12, right: 12 })
        .backgroundColor(this.pageBackground)
        .onClick(() => {
          focusControl.requestFocus(this.dismissFocusId);
        });
      } else {
        Scroll() {
          Column() {
            this.SummaryCard();
            this.RecordListCard();
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
          .padding({
            left: 12,
            right: 12,
            top: 10 + this.navigationHeight + this.navigationGap,
            bottom: 24
          });
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.pageBackground)
        .scrollBar(BarState.Off)
        .onClick(() => {
          focusControl.requestFocus(this.dismissFocusId);
        });
      }

      AppNavigationBar({
        title: this.tag?.name ?? '标签详情',
        titleColor: this.titleColor,
        surfaceColor: this.surfaceColor
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
  NavigationSpacer() {
    Blank()
      .width('100%')
      .height(10 + this.navigationHeight + this.navigationGap);
  }

  @Builder
  SummaryCard() {
    Column() {
      Row() {
        Text(`今天 · ${this.getDisplayDate()}`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.secondaryTextColor);

        Blank();

        Text(this.tag?.name ?? '标签')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTagAccentColor())
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor('#FFFFFF')
          .borderRadius(9);
      }
      .width('100%');

      Text(`${this.records.length}条记录 · 最近 ${this.getLatestTime()}`)
        .width('100%')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor)
        .margin({ top: 10, bottom: 14 });

      Row() {
        this.StatPill('已落下', `${this.records.length}条`);
        this.StatPill('最近一次', this.getLatestTime());
      }
      .width('100%');
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 16, bottom: 16 })
    .backgroundColor(this.getTagBackground())
    .borderRadius(24)
    .margin({ bottom: 12 })
    .border({ width: 1, color: TagStyleUtils.getChipBorder(this.getTagAccentColor()) })
    .shadow({
      radius: 16,
      color: this.shadowColor,
      offsetX: 0,
      offsetY: 6
    });
  }

  @Builder
  StatPill(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.secondaryTextColor);

      Text(value)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor)
        .margin({ top: 6 });
    }
    .layoutWeight(1)
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .margin({ left: 4, right: 4 })
    .shadow({ radius: 8, color: '#09000000', offsetX: 0, offsetY: 3 });
  }

  @Builder
  RecordListCard() {
    Column() {
      Text('今天的具体记录')
        .width('100%')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor)
        .margin({ bottom: 14 });

      if (this.records.length === 0) {
        Text('这个标签今天还没有留下具体内容')
          .width('100%')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.secondaryTextColor);
      } else {
        ForEach(this.records, (record: Record) => {
          this.RecordItem(record);
        });
      }
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(24)
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .border({ width: 1, color: this.lineColor })
    .shadow({
      radius: 14,
      color: this.shadowColor,
      offsetX: 0,
      offsetY: 6
    });
  }

  @Builder
  RecordItem(record: Record) {
    Column() {
      Row() {
        Text(this.getTimeText(record.createdAt))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.mutedTextColor);

        Blank();
      }
      .width('100%')
      .margin({ bottom: 8 });

      Text(record.content)
        .width('100%')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .lineHeight(21)
        .fontColor(this.titleColor)
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .border({
      width: { bottom: 1 },
      color: this.lineColor
    });
  }

  @Builder
  EmptyState() {
    Column() {
      Text('标签不存在')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.secondaryTextColor)
        .margin({ bottom: 16 });

      Button('返回首页')
        .width(120)
        .height(42)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor('#63D5C2')
        .borderRadius(21)
        .onClick(() => {
          RouterManager.goBack();
        });
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center);
  }
}
