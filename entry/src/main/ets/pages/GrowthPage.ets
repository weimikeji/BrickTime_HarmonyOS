import { storageService } from '../services/StorageService';
import { Record, StatsData, Tag } from '../models/DataModels';
import { DateUtils, getNumberArray } from '../utils/DateUtils';
import { EventBus, Events } from '../services/EventBus';
import { ThemeUtils } from '../utils/ThemeUtils';

interface HeatBrick {
  color: string;
  filled: boolean;
  count: number;
  date: string;
}

interface BehaviorStat {
  label: string;
  color: string;
  count: number;
  percent: number;
}

@Entry
@Component
export struct GrowthPage {
  private readonly pageBackground: string = '#F7F8FB';
  private readonly surfaceColor: string = '#FFFFFF';
  private readonly titleColor: string = '#3B3D45';
  private readonly secondaryTextColor: string = '#97A1B6';
  private readonly lightTextColor: string = '#B7C0D1';
  private readonly cardShadow: string = '#10000000';
  private readonly dismissFocusId: string = 'growthDismissFocus';
  private readonly tabBarSafeOffset: number = 80;

  @State stats: StatsData = {
    totalDays: 0,
    completedDays: 0,
    currentStreak: 0,
    longestStreak: 0,
    completionRate: 0,
  };
  @State records: Record[] = [];
  @State tags: Tag[] = [];
  @State heatBricks: HeatBrick[] = [];
  @State behaviorStats: BehaviorStat[] = [];
  @State themeColor: string = ThemeUtils.getThemeColor();

  aboutToAppear() {
    EventBus.on(Events.SETTINGS_CHANGED, this.handleSettingsChanged);
    this.themeColor = ThemeUtils.getThemeColor();
    this.loadData();
  }

  aboutToDisappear() {
    EventBus.off(Events.SETTINGS_CHANGED, this.handleSettingsChanged);
  }

  private handleSettingsChanged = () => {
    this.themeColor = ThemeUtils.getThemeColor();
    this.loadData();
  };

  private loadData() {
    this.records = storageService.getRecords();
    this.tags = storageService.getTags();
    this.stats = this.buildStats();
    this.heatBricks = this.buildHeatBricks();
    this.behaviorStats = this.buildBehaviorStats();
  }

  private getDailyCounts(): Map<string, number> {
    const map = new Map<string, number>();
    this.records.forEach((record: Record) => {
      map.set(record.date, (map.get(record.date) ?? 0) + 1);
    });
    return map;
  }

  private getSortedActiveDays(): string[] {
    const days = Array.from(this.getDailyCounts().keys());
    days.sort((left: string, right: string) => left.localeCompare(right));
    return days;
  }

  private buildStats(): StatsData {
    const activeDays = this.getSortedActiveDays();
    if (activeDays.length === 0) {
      return {
        totalDays: 0,
        completedDays: 0,
        currentStreak: 0,
        longestStreak: 0,
        completionRate: 0
      };
    }

    const currentStreak = this.getCurrentStreak(activeDays);
    const longestStreak = this.getLongestStreak(activeDays);
    const firstDate = DateUtils.parseDate(activeDays[0]);
    const today = DateUtils.parseDate(DateUtils.getToday());
    const spanDays = Math.max(1, Math.floor((today.getTime() - firstDate.getTime()) / 86400000) + 1);
    const completionRate = Math.min(100, Math.round((activeDays.length / spanDays) * 100));

    return {
      totalDays: activeDays.length,
      completedDays: activeDays.length,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      completionRate: completionRate
    };
  }

  private getCurrentStreak(activeDays: string[]): number {
    const activeSet = new Set<string>(activeDays);
    let streak = 0;
    let cursor = DateUtils.parseDate(DateUtils.getToday());

    while (activeSet.has(DateUtils.formatDate(cursor))) {
      streak += 1;
      cursor = new Date(cursor.getTime() - 86400000);
    }

    if (streak > 0) {
      return streak;
    }

    if (activeDays.length === 0) {
      return 0;
    }

    cursor = DateUtils.parseDate(activeDays[activeDays.length - 1]);
    while (activeSet.has(DateUtils.formatDate(cursor))) {
      streak += 1;
      cursor = new Date(cursor.getTime() - 86400000);
    }
    return streak;
  }

  private getLongestStreak(activeDays: string[]): number {
    if (activeDays.length === 0) {
      return 0;
    }

    let best = 1;
    let current = 1;
    for (let index = 1; index < activeDays.length; index++) {
      const prev = DateUtils.parseDate(activeDays[index - 1]);
      const next = DateUtils.parseDate(activeDays[index]);
      const diff = Math.floor((next.getTime() - prev.getTime()) / 86400000);
      if (diff === 1) {
        current += 1;
        if (current > best) {
          best = current;
        }
      } else {
        current = 1;
      }
    }
    return best;
  }

  private buildHeatBricks(): HeatBrick[] {
    const result: HeatBrick[] = [];
    const dailyCounts = this.getDailyCounts();
    let maxCount = 0;
    dailyCounts.forEach((count: number) => {
      if (count > maxCount) {
        maxCount = count;
      }
    });

    const today = DateUtils.parseDate(DateUtils.getToday());
    for (let index = 55; index >= 0; index--) {
      const date = new Date(today.getTime() - index * 86400000);
      const key = DateUtils.formatDate(date);
      const count = dailyCounts.get(key) ?? 0;
      result.push({
        date: key,
        count: count,
        filled: count > 0,
        color: this.getHeatColor(count, maxCount)
      });
    }
    return result;
  }

  private getHeatColor(count: number, maxCount: number): string {
    if (count <= 0) {
      return '#F8FAFD';
    }

    if (maxCount <= 1) {
      return ThemeUtils.withAlpha(this.themeColor, 'AA');
    }

    const ratio = count / maxCount;
    if (ratio >= 0.75) {
      return ThemeUtils.withAlpha(this.themeColor, 'CC');
    }
    if (ratio >= 0.5) {
      return ThemeUtils.withAlpha(this.themeColor, '99');
    }
    if (ratio >= 0.25) {
      return ThemeUtils.withAlpha(this.themeColor, '66');
    }
    return ThemeUtils.withAlpha(this.themeColor, '33');
  }

  private buildBehaviorStats(): BehaviorStat[] {
    const totalRecords = this.records.length;
    const result: BehaviorStat[] = [];

    this.tags.forEach((tag: Tag) => {
      const count = this.records.filter((record: Record) => record.tagId === tag.id).length;
      if (count <= 0) {
        return;
      }
      result.push({
        label: tag.name,
        color: tag.color,
        count: count,
        percent: totalRecords <= 0 ? 0 : Math.round((count / totalRecords) * 100)
      });
    });

    result.sort((left: BehaviorStat, right: BehaviorStat) => right.count - left.count);
    return result.slice(0, 4);
  }

  private getWeeklyRecordCount(): number {
    const today = DateUtils.parseDate(DateUtils.getToday()).getTime();
    return this.records.filter((record: Record) => {
      const diff = Math.floor((today - DateUtils.parseDate(record.date).getTime()) / 86400000);
      return diff >= 0 && diff < 7;
    }).length;
  }

  private getAverageRecordsPerDay(): string {
    if (this.stats.totalDays <= 0) {
      return '0.0';
    }
    return (this.records.length / this.stats.totalDays).toFixed(1);
  }

  private getMostActiveDate(): string {
    if (this.records.length === 0) {
      return '还没有开始';
    }

    const dailyCounts = this.getDailyCounts();
    let bestDate = '';
    let bestCount = 0;
    dailyCounts.forEach((count: number, date: string) => {
      if (count > bestCount) {
        bestCount = count;
        bestDate = date;
      }
    });

    if (bestDate === '') {
      return '还没有开始';
    }
    const date = DateUtils.parseDate(bestDate);
    return `${date.getMonth() + 1}月${date.getDate()}日`;
  }

  private getMostActiveCount(): number {
    let bestCount = 0;
    this.getDailyCounts().forEach((count: number) => {
      if (count > bestCount) {
        bestCount = count;
      }
    });
    return bestCount;
  }

  private getChampionTag(): BehaviorStat | undefined {
    return this.behaviorStats[0];
  }

  private getLatestActiveDateText(): string {
    const activeDays = this.getSortedActiveDays();
    if (activeDays.length === 0) {
      return '还没有开始';
    }
    const last = DateUtils.parseDate(activeDays[activeDays.length - 1]);
    return `${last.getMonth() + 1}月${last.getDate()}日`;
  }

  private getSummaryText(): string {
    if (this.records.length === 0) {
      return '你还没有留下成长记录，但每一个微小开始，都会慢慢积累成看得见的变化。';
    }

    return `你已经留下 ${this.records.length} 条记录，分布在 ${this.stats.totalDays} 天里，当前连续 ${this.stats.currentStreak} 天。碎片没有白白溜走，它们正在被你整理成自己的节奏。`;
  }

  private getFirstRecordText(): string {
    if (this.records.length === 0) {
      return '这是你的第一次成长页，等你开始记录以后，这里会慢慢长出属于你的长期轨迹。';
    }

    const sorted = [...this.records].sort((left: Record, right: Record) => left.createdAt - right.createdAt);
    const first = sorted[0];
    const tag = this.tags.find((item: Tag) => item.id === first.tagId)?.name ?? '记录';
    const preview = first.content.trim() === '' ? '你写下了一条新的开始。' : first.content.trim();
    return `${DateUtils.parseDate(first.date).getMonth() + 1}月${DateUtils.parseDate(first.date).getDate()}日你留下了第一条${tag}记录：“${preview}”`;
  }

  private getRhythmText(): string {
    if (this.records.length === 0) {
      return '节奏还没有形成，但它会从一次次很小的记录里慢慢长出来。';
    }

    if (this.stats.currentStreak >= 7) {
      return `你最近已经连续记录 ${this.stats.currentStreak} 天，这种稳定感很珍贵，说明你正在把“偶尔想起”变成“自然会做”。`;
    }

    if (this.getWeeklyRecordCount() >= 5) {
      return `过去 7 天你一共写下了 ${this.getWeeklyRecordCount()} 条记录，说明你已经在主动收拢日常的碎片，节奏正在成形。`;
    }

    return `你最近一次活跃是在 ${this.getLatestActiveDateText()}。哪怕还不算很密集，只要继续留下痕迹，节奏就会越来越清楚。`;
  }

  private getMemoryText(): string {
    if (this.records.length === 0) {
      return '等你有了更活跃的一天，这里会帮你把那个瞬间单独留住。';
    }
    return `${this.getMostActiveDate()} 是你最活跃的一天，那天你一共留下了 ${this.getMostActiveCount()} 条记录。高峰不是压力，而是你认真生活时自然留下的证明。`;
  }

  private getBehaviorBlocks(count: number): number {
    if (count <= 0) {
      return 0;
    }
    if (count >= 5) {
      return 5;
    }
    return count;
  }

  private getBehaviorBlockColor(item: BehaviorStat, blockIndex: number): string {
    if (blockIndex < this.getBehaviorBlocks(item.count)) {
      return item.color;
    }
    return '#EEF2F8';
  }

  private getHeatLegendColor(level: number): string {
    if (level === 0) {
      return '#F5F7FB';
    }
    const alphas: string[] = ['33', '66', '99', 'CC'];
    return ThemeUtils.withAlpha(this.themeColor, alphas[level - 1]);
  }

  private dismissKeyboard() {
    focusControl.requestFocus(this.dismissFocusId);
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          Text('成长')
            .width('100%')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.titleColor);

          Text('把零散努力慢慢看成一条长期曲线')
            .width('100%')
            .fontSize(11)
            .fontColor(this.secondaryTextColor)
            .margin({ top: 4, bottom: 16 });

          this.OverviewCard();
          this.HeatMapCard();
          this.HighlightCard();
          this.BehaviorCard();
          this.InfoCard('✎', this.themeColor, '阶段总结', this.getSummaryText());
          this.InfoCard('♡', '#FFB597', '那一天记忆点', this.getMemoryText());
          this.InfoCard('◌', '#C9B7FF', '第一次', this.getFirstRecordText());
          this.InfoCard('◔', this.themeColor, '你的节奏', this.getRhythmText());

          Text('这些小记录不会立刻改变生活，但它们会慢慢把你带向一个更稳定的自己。')
            .width('100%')
            .fontSize(11)
            .lineHeight(17)
            .textAlign(TextAlign.Center)
            .fontColor(this.secondaryTextColor)
            .margin({ top: 8, bottom: 24 });
        }
        .padding({ left: 12, right: 12, top: 28, bottom: this.tabBarSafeOffset });
      }
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
  OverviewCard() {
    Column() {
      this.CardTitle('◎', this.themeColor, '成长概览');

      Row() {
        this.OverviewItem(`${this.records.length}`, '累计记录');
        this.OverviewItem(`${this.stats.totalDays}`, '活跃天数');
      }
      .width('100%')
      .margin({ bottom: 14 });

      Row() {
        this.OverviewItem(`${this.stats.currentStreak}`, '当前连续');
        this.OverviewItem(`${this.stats.longestStreak}`, '最长连续');
      }
      .width('100%')
      .margin({ bottom: 14 });

      this.ProgressRow();
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(18)
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .shadow({ radius: 14, color: this.cardShadow, offsetX: 0, offsetY: 8 })
    .margin({ bottom: 14 });
  }

  @Builder
  OverviewItem(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColor);

      Text(label)
        .fontSize(11)
        .fontColor(this.secondaryTextColor)
        .margin({ top: 6 });
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 10, bottom: 10 })
    .backgroundColor(ThemeUtils.getTintColor(this.themeColor, '10'))
    .borderRadius(16)
    .margin({ left: 4, right: 4 });
  }

  @Builder
  ProgressRow() {
    Column() {
      Row() {
        Text('活跃率')
          .fontSize(12)
          .fontColor(this.secondaryTextColor)
          .layoutWeight(1);

        Text(`${this.stats.completionRate}%`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.titleColor);
      }
      .width('100%')
      .margin({ bottom: 8 });

      Row() {
        Row() {
        }
        .width(`${this.stats.completionRate}%`)
        .height(8)
        .backgroundColor(this.themeColor)
        .borderRadius(4);
      }
      .width('100%')
      .height(8)
      .backgroundColor('#EEF2F8')
      .borderRadius(4);
    }
    .width('100%');
  }

  @Builder
  HighlightCard() {
    Column() {
      this.CardTitle('✦', this.themeColor, '本阶段亮点');

      this.HighlightRow('最活跃的一天', `${this.getMostActiveDate()} · ${this.getMostActiveCount()} 条`);
      this.HighlightRow('主力标签', `${this.getChampionTag()?.label ?? '还没有'}${this.getChampionTag() ? ` · ${this.getChampionTag()!.count} 条` : ''}`);
      this.HighlightRow('日均记录', `${this.getAverageRecordsPerDay()} 条 / 活跃日`);
      this.HighlightRow('最近 7 天', `${this.getWeeklyRecordCount()} 条记录`, true);
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(18)
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .shadow({ radius: 14, color: this.cardShadow, offsetX: 0, offsetY: 8 })
    .margin({ bottom: 14 });
  }

  @Builder
  HighlightRow(label: string, value: string, isLast: boolean = false) {
    Row() {
      Text(label)
        .fontSize(12)
        .fontColor(this.secondaryTextColor)
        .layoutWeight(1);

      Text(value)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.titleColor)
        .textAlign(TextAlign.End);
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .border({ width: { bottom: isLast ? 0 : 1 }, color: '#F1F4F8' });
  }

  @Builder
  HeatMapCard() {
    Column() {
      this.CardTitle('▦', this.themeColor, '最近 8 周活跃热力');

      Column() {
        ForEach(getNumberArray(7), (row: number) => {
          Row() {
            ForEach(getNumberArray(8), (column: number) => {
              this.HeatBrickItem(row * 8 + column);
            });
          }
          .margin({ bottom: row === 6 ? 0 : 6 });
        });
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center);

      Row() {
        Text('少')
          .fontSize(10)
          .fontColor(this.lightTextColor)
          .margin({ right: 8 });

        ForEach(getNumberArray(5), (index: number) => {
          Column() {
          }
          .width(12)
          .height(12)
          .backgroundColor(this.getHeatLegendColor(index))
          .borderRadius(4)
          .border({ width: index === 0 ? 1 : 0, color: '#EEF2F7' })
          .margin({ right: index === 4 ? 0 : 6 });
        });

        Text('多')
          .fontSize(10)
          .fontColor(this.lightTextColor)
          .margin({ left: 8 });
      }
      .margin({ top: 14 });
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(18)
    .padding({ left: 12, right: 12, top: 14, bottom: 14 })
    .shadow({ radius: 14, color: this.cardShadow, offsetX: 0, offsetY: 8 })
    .margin({ bottom: 14 });
  }

  @Builder
  HeatBrickItem(index: number) {
    Column() {
    }
    .width(16)
    .height(16)
    .backgroundColor(this.heatBricks[index]?.color ?? '#F8FAFD')
    .borderRadius(5)
    .border({ width: this.heatBricks[index]?.filled ? 0 : 1, color: '#EEF2F7' })
    .margin({ right: index % 8 === 7 ? 0 : 6 });
  }

  @Builder
  CardTitle(icon: string, iconColor: string, title: string) {
    Row() {
      Text(icon)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(iconColor)
        .margin({ right: 6 });

      Text(title)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.titleColor);
    }
    .width('100%')
    .margin({ bottom: 12 });
  }

  @Builder
  InfoCard(icon: string, iconColor: string, title: string, body: string) {
    Column() {
      this.CardTitle(icon, iconColor, title);

      Text(body)
        .width('100%')
        .fontSize(11)
        .lineHeight(17)
        .fontColor(this.secondaryTextColor);
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(18)
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .shadow({ radius: 14, color: this.cardShadow, offsetX: 0, offsetY: 8 })
    .margin({ bottom: 14 });
  }

  @Builder
  BehaviorCard() {
    Column() {
      this.CardTitle('◔', this.themeColor, '行为分布');

      if (this.behaviorStats.length === 0) {
        Text('等你开始记录以后，这里会显示你最常出现的行为标签。')
          .width('100%')
          .fontSize(11)
          .lineHeight(17)
          .fontColor(this.secondaryTextColor);
      } else {
        ForEach(this.behaviorStats, (item: BehaviorStat) => {
          Row() {
            Row() {
              Column() {
              }
              .width(8)
              .height(8)
              .backgroundColor(item.color)
              .borderRadius(4)
              .margin({ right: 8 });

              Text(item.label)
                .fontSize(11)
                .fontColor(this.secondaryTextColor);
            }
            .width('32%')
            .justifyContent(FlexAlign.Start);

            Row() {
              ForEach(getNumberArray(5), (index: number) => {
                Column() {
                }
                .width(9)
                .height(9)
                .backgroundColor(this.getBehaviorBlockColor(item, index))
                .borderRadius(3)
                .margin({ left: 4 });
              });
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.End);

            Text(`${item.percent}%`)
              .width(42)
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.End)
              .fontColor(this.titleColor)
              .margin({ left: 10 });
          }
          .width('100%')
          .margin({ bottom: item.label === this.behaviorStats[this.behaviorStats.length - 1].label ? 0 : 10 });
        });
      }
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(18)
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .shadow({ radius: 14, color: this.cardShadow, offsetX: 0, offsetY: 8 })
    .margin({ bottom: 14 });
  }
}
