// 积木卡片组件 - 显示单个积木
import { Record } from '../models/DataModels';
import { COLORS } from '../constants/AppConstants';

@Component
export struct BrickCard {
  @Prop record: Record;
  @Prop onClick?: () => void;

  build() {
    Column() {
      Text(this.record.content)
        .fontSize(14)
        .fontColor(COLORS.surface)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis });
    }
    .width('100%')
    .height(80)
    .backgroundColor(this.record.color)
    .borderRadius(8)
    .padding(10)
    .justifyContent(FlexAlign.Center)
    .onClick(this.onClick);
  }
}
