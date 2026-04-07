// 每周积木墙组件 - 显示一周的积木
import { Record } from '../models/DataModels';
import { DateUtils, getNumberArray } from '../utils/DateUtils';
import { COLORS } from '../constants/AppConstants';

@Component
export struct WeekBrickWall {
  @Prop weekDays: string[];
  @Prop recordsMap: Map<string, Record[]>;

  build() {
    Column() {
      Text('本周积木')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.text)
        .margin({ bottom: 15 });

      Row() {
        ForEach(this.weekDays, (date: string) => {
          this.DayColumn(date);
        });
      }
      .width('100%')
      .justifyContent(FlexAlign.Start);
    }
    .width('100%')
    .backgroundColor(COLORS.surface)
    .borderRadius(12)
    .padding(15);
  }

  private getDayRecords(date: string): Record[] {
    return this.recordsMap.get(date) || [];
  }

  private getDayCount(date: string): number {
    return this.getDayRecords(date).length;
  }

  private getDayColor(date: string, index: number): string {
    return this.getDayRecords(date)[index]?.color || COLORS.primary;
  }

  @Builder
  DayColumn(date: string) {
    Column() {
      // 积木柱
      Column() {
        if (this.getDayCount(date) > 0) {
          ForEach(getNumberArray(Math.min(this.getDayCount(date), 5)), (i: number) => {
            Column()
              .width(20)
              .height(12)
              .backgroundColor(this.getDayColor(date, i))
              .borderRadius(2);
          });
          if (this.getDayCount(date) > 5) {
            Text('+' + (this.getDayCount(date) - 5))
              .fontSize(10)
              .fontColor(COLORS.primary);
          }
        } else {
          Text('-')
            .fontSize(14)
            .fontColor(COLORS.textLight);
        }
      }
      .width(24)
      .justifyContent(FlexAlign.End)
      .height(70);

      // 星期几
      Text(DateUtils.getDayOfWeekChinese(date))
        .fontSize(12)
        .fontColor(COLORS.textSecondary)
        .margin({ top: 5 });

      // 日期
      Text(date.substring(5))
        .fontSize(10)
        .fontColor(COLORS.textLight);
    }
    .margin({ right: 8 });
  }
}
