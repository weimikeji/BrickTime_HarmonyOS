// 统计卡片组件 - 显示统计数据
import { StatsData } from '../models/DataModels';
import { COLORS } from '../constants/AppConstants';

@Component
export struct StatsCard {
  @Prop stats: StatsData;

  build() {
    Row() {
      this.StatItem(this.stats.totalDays.toString(), '总天数', COLORS.primary);
      this.StatItem(this.stats.completedDays.toString(), '完成天数', COLORS.success);
      this.StatItem(this.stats.currentStreak.toString(), '当前连续', COLORS.warning);
      this.StatItem(this.stats.longestStreak.toString(), '最长连续', COLORS.secondary);
    }
    .width('100%');
  }

  @Builder
  StatItem(value: string, label: string, color: string) {
    Column() {
      Text(value)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(color);
      Text(label)
        .fontSize(12)
        .fontColor(COLORS.textSecondary);
    }
    .width('25%')
    .alignItems(HorizontalAlign.Center);
  }
}
