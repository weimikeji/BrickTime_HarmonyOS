// 标签组件 - 显示单个标签
import { Tag } from '../models/DataModels';
import { COLORS } from '../constants/AppConstants';
import { TagStyleUtils } from '../utils/TagStyleUtils';
import { TagIcon } from './TagIcon';

@Component
export struct TagChip {
  @Prop tag: Tag;
  @Prop selected: boolean = false;
  @Prop showEdit: boolean = false;
  @Prop onClick?: () => void;

  build() {
    Button() {
      Row() {
        TagIcon({
          name: this.tag.icon,
          color: this.selected ? TagStyleUtils.getSelectedText() : TagStyleUtils.getChipText(this.tag.color),
          iconSize: 20
        })
        Text(this.tag.name)
          .fontSize(12)
          .fontColor(this.selected ? COLORS.surface : TagStyleUtils.getChipText(this.tag.color))
          .margin({ left: 4 });
      };
    }
    .backgroundColor(this.selected ? TagStyleUtils.getSelectedBackground(this.tag.color) : TagStyleUtils.getChipBackground(this.tag.color))
    .borderColor(this.selected ? this.tag.color : TagStyleUtils.getChipBorder(this.tag.color))
    .borderWidth(1)
    .borderRadius(18)
    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
    .onClick(this.onClick);
  }
}
