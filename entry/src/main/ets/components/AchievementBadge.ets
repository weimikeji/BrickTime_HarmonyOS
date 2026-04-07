// 成就徽章组件
import { COLORS } from '../constants/AppConstants';

@Component
export struct AchievementBadge {
  @Prop icon: string;
  @Prop name: string;
  @Prop unlocked: boolean;

  build() {
    Column() {
      Text(this.icon)
        .fontSize(28)
        .fontColor(this.unlocked ? COLORS.warning : COLORS.textLight);
      Text(this.name)
        .fontSize(12)
        .fontColor(this.unlocked ? COLORS.text : COLORS.textLight)
        .margin({ top: 5 });
    }
    .width('30%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 10, bottom: 10 });
  }
}
