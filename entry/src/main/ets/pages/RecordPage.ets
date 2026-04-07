// 记录页面 - 按设计稿重做历史记录页
import { storageService } from '../services/StorageService';
import { Record, Tag } from '../models/DataModels';
import { DateUtils } from '../utils/DateUtils';
import { RouterManager } from '../router/RouterManager';
import { EventBus, Events } from '../services/EventBus';
import { ThemeUtils } from '../utils/ThemeUtils';
import { TagStyleUtils } from '../utils/TagStyleUtils';

interface RecordGroupData {
  title: string;
  date: string;
  records: Record[];
}

@Entry
@Component
export struct RecordPage {
  private readonly pageBackground: string = '#F8F9FC';
  private readonly titleColor: string = '#3B3D45';
  private readonly secondaryTextColor: string = '#96A1B7';
  private readonly lightTextColor: string = '#BCC5D6';
  private readonly surfaceColor: string = '#FFFFFF';
  private readonly searchBackground: string = '#FFFFFF';
  private readonly cardShadow: string = '#120B1A2B';
  private readonly dismissFocusId: string = 'recordDismissFocus';
  private readonly tabBarSafeOffset: number = 80;
  private searchController: TextInputController = new TextInputController();
  private listScroller: Scroller = new Scroller();

  @State allRecords: Record[] = [];
  @State filteredRecords: Record[] = [];
  @State tags: Tag[] = [];
  @State selectedTagId: string = '';
  @State searchText: string = '';
  @State groupedRecords: RecordGroupData[] = [];
  @State themeColor: string = ThemeUtils.getThemeColor();
  @State showBackToTop: boolean = false;

  aboutToAppear() {
    EventBus.on(Events.SETTINGS_CHANGED, this.handleSettingsChanged);
    EventBus.on(Events.RECORD_ADDED, this.handleRecordChanged);
    EventBus.on(Events.RECORD_UPDATED, this.handleRecordChanged);
    EventBus.on(Events.RECORD_DELETED, this.handleRecordChanged);
    EventBus.on(Events.TAG_UPDATED, this.handleRecordChanged);
    this.loadData();
    this.themeColor = ThemeUtils.getThemeColor();
  }

  aboutToDisappear() {
    EventBus.off(Events.SETTINGS_CHANGED, this.handleSettingsChanged);
    EventBus.off(Events.RECORD_ADDED, this.handleRecordChanged);
    EventBus.off(Events.RECORD_UPDATED, this.handleRecordChanged);
    EventBus.off(Events.RECORD_DELETED, this.handleRecordChanged);
    EventBus.off(Events.TAG_UPDATED, this.handleRecordChanged);
  }

  private handleSettingsChanged = () => {
    this.themeColor = ThemeUtils.getThemeColor();
  };

  private handleRecordChanged = () => {
    this.loadData();
  };

  loadData() {
    this.allRecords = storageService.getRecords();
    this.tags = storageService.getTags();
    this.applyFilters();
    this.showBackToTop = this.shouldEnableBackToTop();
  }

  applyFilters() {
    let records = [...this.allRecords].sort((a, b) => b.createdAt - a.createdAt);

    if (this.selectedTagId !== '') {
      records = records.filter(record => record.tagId === this.selectedTagId);
    }

    const keyword = this.searchText.trim().toLowerCase();
    if (keyword !== '') {
      records = records.filter((record: Record) => this.matchesSearch(record, keyword));
    }

    this.filteredRecords = records;
    this.groupedRecords = this.buildGroups(records);
    this.showBackToTop = this.shouldEnableBackToTop();
  }

  matchesSearch(record: Record, keyword: string): boolean {
    const contentMatched = record.content.toLowerCase().includes(keyword);
    if (contentMatched) {
      return true;
    }

    const tagName = this.getTagName(record).toLowerCase();
    if (tagName.includes(keyword)) {
      return true;
    }

    const dateTitle = this.getDateTitle(record.date).toLowerCase();
    return dateTitle.includes(keyword);
  }

  buildGroups(records: Record[]): RecordGroupData[] {
    const grouped = new Map<string, Record[]>();
    records.forEach((record: Record) => {
      if (!grouped.has(record.date)) {
        grouped.set(record.date, []);
      }
      grouped.get(record.date)!.push(record);
    });

    const result: RecordGroupData[] = [];
    Array.from(grouped.entries()).forEach((entry: [string, Record[]]) => {
      const date = entry[0];
      const groupRecords = entry[1];
      const group: RecordGroupData = {
        title: this.getDateTitle(date),
        date: date,
        records: groupRecords
      };
      result.push(group);
    });
    return result;
  }

  getDateTitle(dateStr: string): string {
    const today = DateUtils.getToday();
    const todayDate = DateUtils.parseDate(today);
    const current = DateUtils.parseDate(dateStr);
    const yesterday = new Date(todayDate.getTime() - 24 * 60 * 60 * 1000);
    const yesterdayStr = DateUtils.formatDate(yesterday);

    if (dateStr === today) {
      return '今天';
    }

    if (dateStr === yesterdayStr) {
      return `昨天 · ${current.getMonth() + 1}月${current.getDate()}日`;
    }

    return `${current.getMonth() + 1}月${current.getDate()}日`;
  }

  getTagById(id: string): Tag | undefined {
    return this.tags.find(tag => tag.id === id);
  }

  getTimeText(timestamp: number): string {
    const date = new Date(timestamp);
    const hour = String(date.getHours()).padStart(2, '0');
    const minute = String(date.getMinutes()).padStart(2, '0');
    return `${hour}:${minute}`;
  }

  getTagBgColor(tag: Tag | undefined): string {
    if (!tag) {
      return '#EEF3FF';
    }
    return TagStyleUtils.getChipBackground(tag.color);
  }

  getFilterBg(tagId: string): string {
    if (this.selectedTagId === tagId) {
      const tag = this.getTagById(tagId);
      return tag ? TagStyleUtils.getSelectedBackground(tag.color) : this.themeColor;
    }
    if (tagId === '') {
      return '#F5F7FB';
    }
    const tag = this.getTagById(tagId);
    return tag ? TagStyleUtils.getChipBackground(tag.color) : '#F5F7FB';
  }

  getFilterTextColor(tagId: string): string {
    if (this.selectedTagId === tagId) {
      return TagStyleUtils.getSelectedText();
    }
    if (tagId === '') {
      return '#A6B0C2';
    }
    const tag = this.getTagById(tagId);
    return tag ? TagStyleUtils.getChipText(tag.color) : '#A6B0C2';
  }

  getVisibleTags(): Tag[] {
    return this.tags;
  }

  getTagName(record: Record): string {
    return this.getTagById(record.tagId)?.name ?? '记录';
  }

  getTagColor(record: Record): string {
    return this.getTagById(record.tagId)?.color ?? '#9DB0D7';
  }

  getRecordTagBgColor(record: Record): string {
    return this.getTagBgColor(this.getTagById(record.tagId));
  }

  dismissKeyboard() {
    this.searchController.stopEditing();
    focusControl.requestFocus(this.dismissFocusId);
  }

  clearSearch() {
    this.searchText = '';
    this.applyFilters();
    this.dismissKeyboard();
  }

  shouldEnableBackToTop(): boolean {
    return this.filteredRecords.length >= 4;
  }

  backToTop() {
    this.listScroller.scrollEdge(Edge.Top);
  }

  build() {
    Stack() {
      Scroll(this.listScroller) {
        Column() {
          Text('记录')
            .width('100%')
            .fontSize(25)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.titleColor)
            .margin({ top: 24, bottom: 18 });

          this.SearchBar();
          this.FilterBar();

          if (this.groupedRecords.length === 0) {
            this.EmptyState();
          } else {
            ForEach(this.groupedRecords, (group: RecordGroupData) => {
              this.RecordGroup(group);
            });

            this.ListFooter();
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 18, right: 18, bottom: this.tabBarSafeOffset });
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

      if (this.shouldEnableBackToTop()) {
        this.BackToTopButton();
      }
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }

  @Builder
  SearchBar() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.searchText.trim() === '') {
        Row() {
          Blank()
            .width(30)
            .height(1);

          Text('搜索今天做了什么...')
            .layoutWeight(1)
            .fontSize(13)
            .fontWeight(FontWeight.Regular)
            .fontColor('#C3CAD8')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
        .width('100%')
        .padding({ left: 14, right: 14 })
        .alignItems(VerticalAlign.Center);
      }

      Row() {
        Row() {
          this.SearchIcon();
        }
        .width(22)
        .height(22)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center);

        Blank()
          .width(8)
          .height(1);

        TextInput({ text: $$this.searchText, controller: this.searchController })
          .fontSize(13)
          .fontColor(this.titleColor)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(22)
          .margin({ top: -1 })
          .onChange((value: string) => {
            this.searchText = value;
            this.applyFilters();
          })
          .onSubmit(() => {
            this.dismissKeyboard();
          });

        if (this.searchText.trim() !== '') {
          Blank()
            .width(8)
            .height(1);

          Button() {
            Text('×')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#C3CAD8');
          }
          .width(18)
          .height(18)
          .backgroundColor('#F2F5FA')
          .borderRadius(9)
          .onClick(() => {
            this.clearSearch();
          });
        }
      }
      .width('100%')
      .padding({ left: 14, right: 14 })
      .alignItems(VerticalAlign.Center);
    }
    .width('100%')
    .height(44)
    .padding({ left: 14, right: 14 })
    .backgroundColor(this.searchBackground)
    .borderRadius(14)
    .shadow({
      radius: 10,
      color: '#0A0B1A2B',
      offsetX: 0,
      offsetY: 4
    })
    .margin({ bottom: 14 });
  }

  @Builder
  SearchIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(11)
        .height(11)
        .border({ width: 1.8, color: '#B8C1D3' })
        .borderRadius(6)
        .translate({ x: -2, y: -1 });

      Column()
        .width(6)
        .height(1.8)
        .backgroundColor('#B8C1D3')
        .borderRadius(1)
        .rotate({ angle: 45 })
        .translate({ x: 5, y: 5 });
    }
    .width(16)
    .height(16)
    .opacity(0.92);
  }

  @Builder
  BackToTopButton() {
    Button() {
      Text('↑')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#6F7D96');
    }
    .width(46)
    .height(46)
    .backgroundColor('#FDFEFF')
    .borderRadius(23)
    .border({ width: 1, color: '#EEF2F7' })
    .shadow({
      radius: 18,
      color: '#180B1A2B',
      offsetX: 0,
      offsetY: 10
    })
    .position({ right: 20, bottom: 110 })
    .opacity(0.96)
    .onClick(() => {
      this.backToTop();
    });
  }

  @Builder
  FilterBar() {
    Scroll() {
      Row() {
        this.FilterChip('全部', '');
        ForEach(this.getVisibleTags(), (tag: Tag) => {
          this.FilterChip(tag.name, tag.id);
        });
      }
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .padding({ right: 12 });
    }
    .width('100%')
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .margin({ bottom: 14 });
  }

  @Builder
  FilterChip(label: string, tagId: string) {
    Button(label)
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.getFilterTextColor(tagId))
      .backgroundColor(this.getFilterBg(tagId))
      .border({
        width: this.selectedTagId === tagId || tagId === '' ? 0 : 1,
        color: tagId === '' ? '#E6EBF3' : TagStyleUtils.getChipBorder(this.getTagById(tagId)?.color ?? '#DCE4F0')
      })
      .borderRadius(16)
      .height(30)
      .padding({ left: 14, right: 14 })
      .margin({ right: 8 })
      .onClick(() => {
        this.dismissKeyboard();
        this.selectedTagId = tagId;
        this.applyFilters();
      });
  }

  @Builder
  RecordGroup(group: RecordGroupData) {
    Column() {
      Text(group.title)
        .width('100%')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.secondaryTextColor)
        .margin({ bottom: 10 });

      ForEach(group.records, (record: Record) => {
        this.RecordCard(record);
      });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 });
  }

  @Builder
  RecordCard(record: Record) {
    Column() {
      Row() {
        Text(this.getTagName(record))
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTagColor(record))
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.getRecordTagBgColor(record))
          .borderRadius(12);

        Blank();

        Text(this.getTimeText(record.createdAt))
          .fontSize(11)
          .fontColor(this.lightTextColor);
      }
      .width('100%')
      .margin({ bottom: 12 });

      Row() {
        Text(record.content)
          .layoutWeight(1)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .lineHeight(21)
          .fontColor(this.titleColor)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        Text('›')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#CBD3E1')
          .margin({ left: 10 });
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);
    }
    .width('100%')
    .backgroundColor(this.surfaceColor)
    .borderRadius(18)
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .margin({ bottom: 12 })
    .shadow({
      radius: 16,
      color: this.cardShadow,
      offsetX: 0,
      offsetY: 6
    })
    .onClick(() => {
      this.dismissKeyboard();
      RouterManager.goToDetail(record.id);
    });
  }

  @Builder
  ListFooter() {
    Row() {
      Row()
        .width(28)
        .height(1)
        .backgroundColor('#E1E6F0')
        .borderRadius(1);

      Text('没有更多了')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.lightTextColor)
        .margin({ left: 10, right: 10 });

      Row()
        .width(28)
        .height(1)
        .backgroundColor('#E1E6F0')
        .borderRadius(1);
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ top: 6, bottom: 18 });
  }

  @Builder
  EmptyState() {
    Column() {
      Text('还没有找到匹配的记录')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.secondaryTextColor);
      Text(this.searchText.trim() !== '' ? `没有找到和“${this.searchText.trim()}”相关的内容` : '换个关键词试试，或者先去记录今天的积木')
        .fontSize(13)
        .fontColor(this.lightTextColor)
        .margin({ top: 8 });
    }
    .width('100%')
    .constraintSize({ minHeight: 360 })
    .justifyContent(FlexAlign.Center);
  }
}
