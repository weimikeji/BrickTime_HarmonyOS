import { Tag, Record } from '../models/DataModels';
import { storageService } from '../services/StorageService';
import { DateUtils } from '../utils/DateUtils';
import { EventBus, Events } from '../services/EventBus';
import { TagStyleUtils } from '../utils/TagStyleUtils';
import { RouterManager } from '../router/RouterManager';
import { TagIcon } from '../components/TagIcon';

interface ColorOption {
  value: string;
  bgColor: string;
}

interface IconOption {
  key: string;
}

@Entry
@Component
export struct TagManagePage {
  private readonly pageBackground: string = '#F7F8FB';
  private readonly surfaceColor: string = '#FFFFFF';
  private readonly titleColor: string = '#3B3D45';
  private readonly secondaryTextColor: string = '#A6AFC0';
  private readonly mutedTextColor: string = '#C7CFDC';
  private readonly shadowColor: string = '#14000000';
  private readonly mintColor: string = '#63D5C2';
  private readonly lineColor: string = '#EEF1F6';
  private readonly dismissFocusId: string = 'tagManageDismissFocus';
  private tagNameController: TextInputController = new TextInputController();

  @State tags: Tag[] = [];
  @State records: Record[] = [];
  @State showEditor: boolean = false;
  @State editingTagId: string = '';
  @State draftName: string = '';
  @State draftColor: string = '#7FB7FF';
  @State draftIcon: string = 'book';

  aboutToAppear() {
    EventBus.on(Events.TAG_UPDATED, this.handleTagUpdated);
    this.loadData();
  }

  aboutToDisappear() {
    EventBus.off(Events.TAG_UPDATED, this.handleTagUpdated);
  }

  private handleTagUpdated = () => {
    this.loadData();
  };

  private loadData() {
    this.tags = storageService.getTags();
    this.records = storageService.getRecords();
  }

  private getPresetTags(): Tag[] {
    const presets: Tag[] = [
      { id: 'preset-reading', name: '阅读', color: '#7FB7FF', icon: 'book' },
      { id: 'preset-sport', name: '运动', color: '#FFB182', icon: 'run' },
      { id: 'preset-think', name: '思考', color: '#C7B0FF', icon: 'bulb' },
      { id: 'preset-write', name: '写作', color: '#A7D8FF', icon: 'pen' },
      { id: 'preset-study', name: '学习', color: '#8BE4CC', icon: 'study' },
      { id: 'preset-meditate', name: '冥想', color: '#63D5C2', icon: 'meditate' }
    ];
    return presets;
  }

  private getColorOptions(): ColorOption[] {
    const options: ColorOption[] = [
      { value: '#7FB7FF', bgColor: '#EEF6FF' },
      { value: '#FFE8D7', bgColor: '#FFF3EA' },
      { value: '#EAE1FF', bgColor: '#F5F0FF' },
      { value: '#DDF7EF', bgColor: '#EEFDF7' },
      { value: '#E4F7EF', bgColor: '#F3FCF8' },
      { value: '#ECFAF2', bgColor: '#F6FEFA' },
      { value: '#EAF3FF', bgColor: '#F5F9FF' },
      { value: '#FFF4EA', bgColor: '#FFF8F1' }
    ];
    return options;
  }

  private getIconOptions(): IconOption[] {
    const options: IconOption[] = [
      { key: 'book' },
      { key: 'run' },
      { key: 'bulb' },
      { key: 'pen' },
      { key: 'study' },
      { key: 'meditate' },
      { key: 'music' },
      { key: 'focus' }
    ];
    return options;
  }

  private getSortedTags(): Tag[] {
    const ordered: Tag[] = [];
    const allTags = [...this.tags];
    this.getPresetTags().forEach((preset: Tag) => {
      const current = allTags.find((tag: Tag) => tag.name === preset.name);
      if (current) {
        ordered.push(current);
      }
    });
    allTags.forEach((tag: Tag) => {
      const exists = ordered.find((item: Tag) => item.id === tag.id);
      if (!exists) {
        ordered.push(tag);
      }
    });
    return ordered;
  }

  private getRecordCount(tagId: string): number {
    return this.records.filter((record: Record) => record.tagId === tagId).length;
  }

  private getCountText(tagId: string): string {
    return `${this.getRecordCount(tagId)}条记录`;
  }

  private getIconCircleBg(color: string): string {
    return TagStyleUtils.getChipBackground(color);
  }

  private openCreateEditor() {
    this.editingTagId = '';
    this.draftName = '';
    this.draftColor = '#7FB7FF';
    this.draftIcon = 'book';
    this.showEditor = true;
  }

  private openEditEditor(tag: Tag) {
    this.editingTagId = tag.id;
    this.draftName = tag.name;
    this.draftColor = tag.color;
    this.draftIcon = tag.icon;
    this.showEditor = true;
  }

  private closeEditor() {
    this.showEditor = false;
    this.editingTagId = '';
    this.draftName = '';
  }

  private canSubmit(): boolean {
    return this.draftName.trim() !== '';
  }

  private dismissKeyboard() {
    this.tagNameController.stopEditing();
    focusControl.requestFocus(this.dismissFocusId);
  }

  private saveTag() {
    if (!this.canSubmit()) {
      return;
    }

    const currentTags = [...this.tags];
    const nextTags: Tag[] = [];
    let nextRecords: Record[] = [...this.records];

    if (this.editingTagId === '') {
      currentTags.forEach((tag: Tag) => {
        nextTags.push(tag);
      });
      nextTags.push({
        id: DateUtils.generateId(),
        name: this.draftName.trim(),
        color: this.draftColor,
        icon: this.draftIcon
      });
    } else {
      currentTags.forEach((tag: Tag) => {
        if (tag.id === this.editingTagId) {
          nextTags.push({
            id: tag.id,
            name: this.draftName.trim(),
            color: this.draftColor,
            icon: this.draftIcon
          });
        } else {
          nextTags.push(tag);
        }
      });
      nextRecords = [];
      this.records.forEach((record: Record) => {
        if (record.tagId === this.editingTagId) {
          nextRecords.push({
            id: record.id,
            content: record.content,
            tagId: record.tagId,
            createdAt: record.createdAt,
            date: record.date,
            color: this.draftColor
          });
        } else {
          nextRecords.push(record);
        }
      });
    }

    storageService.saveTags(nextTags);
    storageService.saveRecords(nextRecords);
    this.loadData();
    this.closeEditor();
  }

  private confirmDelete(tag: Tag) {
    AlertDialog.show({
      title: '删除标签',
      message: `删除“${tag.name}”后，与它关联的记录也会一起删除。`,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        action: () => {
          this.deleteTag(tag.id);
        }
      }
    });
  }

  private deleteTag(tagId: string) {
    const nextTags = storageService.getTags().filter((tag: Tag) => tag.id !== tagId);
    const nextRecords = storageService.getRecords().filter((record: Record) => record.tagId !== tagId);
    storageService.saveTags(nextTags);
    storageService.saveRecords(nextRecords);
    this.loadData();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        Column() {
          this.Header();

          Column() {
            Text('现有标签')
              .width('100%')
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.secondaryTextColor)
              .margin({ left: 2, bottom: 12 });

            ForEach(this.getSortedTags(), (tag: Tag) => {
              this.TagCard(tag);
            }, (tag: Tag) => `${tag.id}-${tag.name}-${tag.color}-${tag.icon}`);
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 240 });
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

      if (this.showEditor) {
        this.EditorOverlay();
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
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }

  @Builder
  Header() {
    Row() {
      Button() {
        Text('←')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.titleColor);
      }
      .width(28)
      .height(28)
      .backgroundColor(this.surfaceColor)
      .borderRadius(14)
      .onClick(() => {
        RouterManager.goBack();
      });

      Text('标签管理')
        .layoutWeight(1)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor)
        .textAlign(TextAlign.Center)
        .margin({ left: 8 });

      Button() {
        Text('+')
          .fontSize(21)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF');
      }
      .width(28)
      .height(28)
      .backgroundColor(this.mintColor)
      .borderRadius(14)
      .onClick(() => {
        this.openCreateEditor();
      });
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 18 });
  }

  @Builder
  TagCard(tag: Tag) {
    Row() {
      Row() {
        TagIcon({ name: tag.icon, color: tag.color, iconSize: 24 })
      }
      .width(34)
      .height(34)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.getIconCircleBg(tag.color))
      .borderRadius(17)
      .margin({ right: 12 });

      Column() {
        Text(tag.name)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.titleColor);

        Text(this.getCountText(tag.id))
          .fontSize(11)
          .fontColor(this.secondaryTextColor)
          .margin({ top: 4 });
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);

      this.ActionIcon('✎', '#AEB8CB', () => {
        this.openEditEditor(tag);
      });

      this.ActionIcon('⌫', '#FF7D83', () => {
        this.confirmDelete(tag);
      });
    }
    .width('100%')
    .height(62)
    .padding({ left: 12, right: 12 })
    .backgroundColor(this.surfaceColor)
    .borderRadius(16)
    .shadow({ radius: 16, color: this.shadowColor, offsetX: 0, offsetY: 6 })
    .margin({ bottom: 10 });
  }

  @Builder
  ActionIcon(symbol: string, color: string, action: () => void) {
    Button() {
      if (symbol === '⌫') {
        this.TrashIcon(color);
      } else {
        Text(symbol)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(color);
      }
    }
    .width(30)
    .height(30)
    .backgroundColor(symbol === '⌫' ? '#FFF1F1' : '#F7F9FC')
    .borderRadius(15)
    .margin({ left: 10 })
    .onClick(() => {
      action();
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
  EditorOverlay() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#18000000')
        .onClick(() => {
          this.closeEditor();
        });

      this.EditorSheet();
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  EditorSheet() {
    Column() {
      Text(this.editingTagId === '' ? '新增标签' : '编辑标签')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor)
        .margin({ top: 22, bottom: 18 });

      this.SheetLabel('选择颜色');
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.getColorOptions(), (item: ColorOption) => {
          this.ColorOptionItem(item);
        });
      }
      .width('100%')
      .margin({ bottom: 18 });

      this.SheetLabel('选择图标');
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.getIconOptions(), (item: IconOption) => {
          this.IconOptionItem(item);
        });
      }
      .width('100%')
      .margin({ bottom: 18 });

      this.SheetLabel('标签名称');
      TextInput({ placeholder: '输入标签名称', text: $$this.draftName, controller: this.tagNameController })
        .width('100%')
        .height(44)
        .fontSize(14)
        .fontColor(this.titleColor)
        .placeholderColor(this.secondaryTextColor)
        .backgroundColor('#F7F9FC')
        .borderRadius(12)
        .padding({ left: 14, right: 14 })
        .margin({ bottom: 18 });

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
            this.dismissKeyboard();
            this.closeEditor();
          });

        Button(this.editingTagId === '' ? '创建' : '保存')
          .layoutWeight(1)
          .height(44)
          .margin({ left: 12 })
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor(this.canSubmit() ? this.mintColor : '#BEDFD8')
          .borderRadius(24)
          .enabled(this.canSubmit())
          .onClick(() => {
            this.dismissKeyboard();
            this.saveTag();
          });
      }
      .width('100%');
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius({ topLeft: 24, topRight: 24 })
    .padding({ left: 14, right: 14, bottom: 20 })
    .shadow({ radius: 22, color: this.shadowColor, offsetX: 0, offsetY: -4 })
    .onClick(() => {
      this.dismissKeyboard();
    });
  }

  @Builder
  SheetLabel(text: string) {
    Text(text)
      .width('100%')
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.secondaryTextColor)
      .margin({ bottom: 12 });
  }

  @Builder
  ColorOptionItem(item: ColorOption) {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(34)
        .height(34)
        .backgroundColor(item.value)
        .borderRadius(17)
        .border({
          width: this.draftColor === item.value ? 2 : 0,
          color: this.draftColor === item.value ? '#72AFFF' : item.value
        });

      if (this.draftColor === item.value) {
        Text('✓')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF');
      }
    }
    .width(42)
    .height(42)
    .margin({ right: 8, bottom: 10 })
    .onClick(() => {
      this.dismissKeyboard();
      this.draftColor = item.value;
    });
  }

  @Builder
  IconOptionItem(item: IconOption) {
    Button() {
      TagIcon({
        name: item.key,
        color: this.draftIcon === item.key ? this.mintColor : '#9EABC0',
        iconSize: 24
      })
    }
    .width(36)
    .height(36)
    .backgroundColor(this.draftIcon === item.key ? '#EDFBF6' : '#F7F9FC')
    .borderRadius(18)
    .border({
      width: this.draftIcon === item.key ? 1 : 0,
      color: this.draftIcon === item.key ? '#CBEFE5' : '#F7F9FC'
    })
    .margin({ right: 10, bottom: 10 })
    .onClick(() => {
      this.dismissKeyboard();
      this.draftIcon = item.key;
    });
  }
}
