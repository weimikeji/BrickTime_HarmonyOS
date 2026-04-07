import { router } from '@kit.ArkUI';
import { storageService } from '../services/StorageService';
import { Record, Tag } from '../models/DataModels';
import { DateUtils } from '../utils/DateUtils';
import { RouterManager } from '../router/RouterManager';
import { EventBus, Events } from '../services/EventBus';
import { TagStyleUtils } from '../utils/TagStyleUtils';
import { AppNavigationBar } from '../components/AppNavigationBar';

interface DetailRouteParams {
  id?: string;
}

@Entry
@Component
export struct DetailPage {
  private readonly pageBackground: string = '#F7F8FB';
  private readonly surfaceColor: string = '#FFFFFF';
  private readonly titleColor: string = '#3B3D45';
  private readonly secondaryTextColor: string = '#99A3B6';
  private readonly mutedTextColor: string = '#C6CEDC';
  private readonly mintColor: string = '#63D5C2';
  private readonly dangerColor: string = '#FF7D83';
  private readonly shadowColor: string = '#14000000';
  private readonly dismissFocusId: string = 'detailDismissFocus';

  @State record: Record | null = null;
  @State tag: Tag | null = null;
  @State tags: Tag[] = [];
  @State recordId: string = '';
  @State showEditSheet: boolean = false;
  @State showDeleteConfirm: boolean = false;
  @State editContent: string = '';
  @State editTagId: string = '';
  @State deleteOverlayOpacity: number = 0;
  @State deleteCardOffsetY: number = 28;
  @State deleteCardScale: number = 0.96;

  aboutToAppear() {
    this.tags = storageService.getTags();
    try {
      const params = router.getParams() as DetailRouteParams;
      if (params && params.id) {
        this.recordId = params.id;
      }
    } catch {
    }
    this.loadRecord();
  }

  private loadRecord() {
    if (this.recordId === '') {
      this.record = null;
      this.tag = null;
      return;
    }
    this.record = storageService.getRecordById(this.recordId);
    this.tags = storageService.getTags();
    if (this.record) {
      this.tag = this.tags.find((item: Tag) => item.id === this.record?.tagId) ?? null;
      this.editContent = this.record.content;
      this.editTagId = this.record.tagId;
    } else {
      this.tag = null;
    }
  }

  private getTagBgColor(tag: Tag | null): string {
    if (!tag) {
      return '#EEF6FF';
    }
    return TagStyleUtils.getChipBackground(tag.color);
  }

  private getDisplayTime(): string {
    if (!this.record) {
      return '';
    }
    const date = new Date(this.record.createdAt);
    const hour = String(date.getHours()).padStart(2, '0');
    const minute = String(date.getMinutes()).padStart(2, '0');
    const today = DateUtils.getToday();
    const prefix = this.record.date === today ? '今天' : `${date.getMonth() + 1}月${date.getDate()}日`;
    return `${prefix} ${hour}:${minute}`;
  }

  private startEdit() {
    if (!this.record) {
      return;
    }
    this.showDeleteConfirm = false;
    this.editContent = this.record.content;
    this.editTagId = this.record.tagId;
    this.showEditSheet = true;
  }

  private openDeleteConfirm() {
    this.showDeleteConfirm = true;
    this.deleteOverlayOpacity = 0;
    this.deleteCardOffsetY = 20;
    this.deleteCardScale = 0.96;
    animateTo({ duration: 220, curve: Curve.EaseOut }, () => {
      this.deleteOverlayOpacity = 1;
      this.deleteCardOffsetY = 0;
      this.deleteCardScale = 1;
    });
  }

  private closeDeleteConfirm() {
    animateTo({ duration: 180, curve: Curve.EaseInOut }, () => {
      this.deleteOverlayOpacity = 0;
      this.deleteCardOffsetY = 12;
      this.deleteCardScale = 0.98;
    });
    setTimeout(() => {
      this.showDeleteConfirm = false;
    }, 180);
  }

  private saveEdit() {
    if (!this.record || this.editContent.trim() === '' || this.editTagId === '') {
      return;
    }
    const nextTag = this.tags.find((tag: Tag) => tag.id === this.editTagId);
    const nextRecord: Record = {
      id: this.record.id,
      content: this.editContent.trim(),
      tagId: this.editTagId,
      createdAt: this.record.createdAt,
      date: this.record.date,
      color: nextTag?.color ?? this.record.color
    };
    storageService.updateRecord(nextRecord);
    this.showEditSheet = false;
    this.loadRecord();
  }

  private deleteCurrentRecord() {
    if (!this.record) {
      return;
    }
    const deletedRecordId = this.record.id;
    storageService.deleteRecord(deletedRecordId);
    RouterManager.goBack();
    setTimeout(() => {
      EventBus.emit(Events.RECORD_DELETED);
    }, 0);
  }

  private getAvailableTags(): Tag[] {
    return this.tags.slice(0, 8);
  }

  private dismissKeyboard() {
    focusControl.requestFocus(this.dismissFocusId);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (!this.record) {
        this.EmptyState();
      } else {
        Column() {
          AppNavigationBar({
            title: '记录详情',
            titleColor: this.titleColor,
            surfaceColor: this.surfaceColor
          });

          Column() {
            this.RecordCard();
            this.ActionBar();
            Blank();
          }
          .width('100%')
          .padding({ left: 12, right: 12 });
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.pageBackground)
        .onClick(() => {
          this.dismissKeyboard();
        });
      }

      if (this.showEditSheet) {
        this.EditOverlay();
      }

      if (this.showDeleteConfirm) {
        this.DeleteOverlay();
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
  EmptyState() {
    Column() {
      Text('记录不存在')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.secondaryTextColor)
        .margin({ bottom: 16 });

      Button('返回')
        .width(120)
        .height(44)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor(this.mintColor)
        .borderRadius(24)
        .onClick(() => {
          RouterManager.goBack();
        });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.pageBackground);
  }

  @Builder
  TrashIcon(color: string) {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(12)
        .height(11)
        .border({ width: 1.7, color: color })
        .borderRadius(2)
        .translate({ y: 2 });

      Column()
        .width(14)
        .height(1.8)
        .backgroundColor(color)
        .borderRadius(1)
        .translate({ y: -5 });

      Column()
        .width(6)
        .height(1.8)
        .backgroundColor(color)
        .borderRadius(1)
        .translate({ y: -8 });
    }
  }

  @Builder
  RecordCard() {
    Column() {
      Row() {
        Text(this.tag?.name ?? '记录')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tag?.color ?? '#8FB1E8')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(this.getTagBgColor(this.tag))
          .borderRadius(18);

        Blank();

        Text(this.getDisplayTime())
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.mutedTextColor);
      }
      .width('100%')
      .margin({ bottom: 24 });

      Text('这块积木')
        .width('100%')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.mutedTextColor)
        .margin({ bottom: 10 });

      Text(this.record?.content ?? '')
        .width('100%')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .lineHeight(34)
        .fontColor(this.titleColor);

      Row() {
        Text('删掉它也没关系，新的积木还会继续落下。')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.secondaryTextColor);
      }
      .width('100%')
      .margin({ top: 26 });
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(28)
    .padding({ left: 24, right: 24, top: 24, bottom: 24 })
    .border({ width: 1, color: '#EEF2F7' });
  }

  @Builder
  DeleteCard() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(42)
          .height(42)
          .backgroundColor('#FFF2F3')
          .borderRadius(21)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);

        this.TrashIcon(this.dangerColor);
      }
      .width('100%')
      .height(42)
      .margin({ bottom: 16 });

      Text('删除这条记录？')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor);

      Text('删除后，这块积木会从今天和记录页里一起消失，并且无法恢复。')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#A5AEC0')
        .textAlign(TextAlign.Center)
        .lineHeight(22)
        .margin({ top: 8, bottom: 24 });

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#A5AEC0')
      .backgroundColor('#F5F7FA')
      .borderRadius(24)
      .onClick(() => {
            this.closeDeleteConfirm();
          });

        Button('删除')
          .layoutWeight(1)
          .height(44)
          .margin({ left: 14 })
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor(this.dangerColor)
          .borderRadius(24)
          .onClick(() => {
            this.deleteCurrentRecord();
          });
      }
      .width('100%');
    }
    .width('86%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(28)
    .padding({ left: 22, right: 22, top: 24, bottom: 22 })
    .shadow({ radius: 24, color: this.shadowColor, offsetX: 0, offsetY: 10 })
    .translate({ y: this.deleteCardOffsetY })
    .scale({ x: this.deleteCardScale, y: this.deleteCardScale });
  }

  @Builder
  DeleteOverlay() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#22000000')
        .opacity(this.deleteOverlayOpacity)
        .onClick(() => {
          this.closeDeleteConfirm();
        });

      this.DeleteCard();
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  ActionBar() {
    Row() {
      Button() {
        Text('编辑内容')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.titleColor);
      }
      .layoutWeight(1)
      .height(44)
      .backgroundColor('#FFFFFF')
      .borderRadius(22)
      .border({ width: 1, color: '#E9EEF5' })
      .onClick(() => {
        this.startEdit();
      });

      Button() {
        Text('删除记录')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.dangerColor);
      }
      .layoutWeight(1)
      .height(44)
      .margin({ left: 12 })
      .backgroundColor('#FFF3F4')
      .borderRadius(22)
      .border({ width: 1, color: '#FFD9DE' })
      .onClick(() => {
        this.openDeleteConfirm();
      });
    }
    .width('100%')
    .margin({ top: 16 });
  }

  @Builder
  EditOverlay() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#22000000')
        .onClick(() => {
          this.showEditSheet = false;
        });

      this.EditSheet();
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  EditSheet() {
    Column() {
      Column()
        .width(42)
        .height(5)
        .backgroundColor('#E6EBF3')
        .borderRadius(3)
        .margin({ top: 10, bottom: 18 });

      Text('编辑记录')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor)
        .margin({ bottom: 18 });

      TextArea({ placeholder: '记录一下刚刚做的事', text: $$this.editContent })
        .width('100%')
        .height(150)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.titleColor)
        .placeholderColor(this.secondaryTextColor)
        .backgroundColor('#F7F9FC')
        .borderRadius(20)
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        .maxLength(100)
        .margin({ bottom: 18 });

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.getAvailableTags(), (tag: Tag) => {
          this.TagChip(tag);
        });
      }
      .width('100%')
      .margin({ bottom: 18 });

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#A5AEC0')
          .backgroundColor('#F5F7FA')
          .borderRadius(24)
          .onClick(() => {
            this.showEditSheet = false;
          });

        Button('保存')
          .layoutWeight(1)
          .height(44)
          .margin({ left: 14 })
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor(this.editContent.trim() !== '' ? this.mintColor : '#BFE7DE')
          .borderRadius(24)
          .enabled(this.editContent.trim() !== '')
          .onClick(() => {
            this.saveEdit();
          });
      }
      .width('100%');
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius({ topLeft: 24, topRight: 24 })
    .padding({ left: 20, right: 20, bottom: 24 })
    .onClick(() => {
      this.dismissKeyboard();
    });
  }

  @Builder
  TagChip(tag: Tag) {
    Button(tag.name)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.editTagId === tag.id ? TagStyleUtils.getSelectedText() : TagStyleUtils.getChipText(tag.color))
      .backgroundColor(this.editTagId === tag.id ? TagStyleUtils.getSelectedBackground(tag.color) : TagStyleUtils.getChipBackground(tag.color))
      .border({
        width: this.editTagId === tag.id ? 0 : 1,
        color: TagStyleUtils.getChipBorder(tag.color)
      })
      .borderRadius(18)
      .height(36)
      .padding({ left: 18, right: 18 })
      .margin({ right: 10, bottom: 10 })
      .onClick(() => {
        this.editTagId = tag.id;
      });
  }
}
