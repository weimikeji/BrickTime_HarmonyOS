// 今日页面 - 显示今天的积木记录
import { storageService } from '../services/StorageService';
import { Record, Tag } from '../models/DataModels';
import { DateUtils } from '../utils/DateUtils';
import { BRICK_COLORS } from '../constants/AppConstants';
import { EventBus, Events } from '../services/EventBus';
import { ThemeUtils } from '../utils/ThemeUtils';
import { TagStyleUtils } from '../utils/TagStyleUtils';
import { RouterManager } from '../router/RouterManager';

interface QuickTagPreset {
  name: string;
  color: string;
  bgColor: string;
  icon: string;
}

interface TodayTagBubbleData {
  tag: Tag;
  count: number;
  latestAt: number;
}

@Entry
@Component
export struct TodayPage {
  private readonly pageBackground: string = '#F7F8FB';
  private readonly softTint: string = '#F4F7FC';
  private readonly heroTint: string = '#F8FBFF';
  private readonly titleColor: string = '#3B3D45';
  private readonly secondaryTextColor: string = '#9AA3B7';
  private readonly lightTextColor: string = '#BAC3D4';
  private readonly cardShadowColor: string = '#14000000';
  private readonly emptyBrickBorder: string = '#E7EBF3';
  private readonly inputBackground: string = '#F7F9FC';
  private readonly dismissFocusId: string = 'todayDismissFocus';
  private readonly tabBarSafeOffset: number = 80;
  private addRecordController: TextAreaController = new TextAreaController();

  @State today: string = DateUtils.getToday();
  @State records: Record[] = [];
  @State tags: Tag[] = [];
  @State todayCount: number = 0;
  @State showAddDialog: boolean = false;
  @State newRecordContent: string = '';
  @State selectedTagId: string = '';
  @State themeColor: string = ThemeUtils.getThemeColor();
  @State heroTranslateY: number = 20;
  @State heroOpacity: number = 0;
  @State ctaScale: number = 1;
  @State cheerOpacity: number = 0;
  @State cheerText: string = '';
  @State cheerSubText: string = '';
  @State cheerTranslateY: number = 16;
  @State cheerScale: number = 0.9;
  @State cheerParticleOpacity: number = 0;
  @State cheerParticleOffset: number = 8;
  @State fireworkFrame: number = 0;
  @State fireworkVisible: boolean = false;
  @State showCelebrationModal: boolean = false;
  @State highlightedRecordId: string = '';
  @State highlightedBrickScale: number = 1;
  @State highlightedBrickOffset: number = 0;
  @State bubbleFloatPhase: boolean = false;
  private pendingHighlightRecordId: string = '';
  private fireworkTimer: number = -1;
  private cheerTimer: number = -1;
  private highlightTimer: number = -1;
  private bubbleTimer: number = -1;

  aboutToAppear() {
    AppStorage.setOrCreate('homeTabBarHidden', false);
    EventBus.on(Events.SETTINGS_CHANGED, this.handleSettingsChanged);
    EventBus.on(Events.RECORD_ADDED, this.handleRecordChanged);
    EventBus.on(Events.RECORD_UPDATED, this.handleRecordChanged);
    EventBus.on(Events.RECORD_DELETED, this.handleRecordChanged);
    this.loadData();
    this.themeColor = ThemeUtils.getThemeColor();
    this.playEntranceAnimation();
    this.startBubbleFloat();
  }

  aboutToDisappear() {
    AppStorage.setOrCreate('homeTabBarHidden', false);
    EventBus.off(Events.SETTINGS_CHANGED, this.handleSettingsChanged);
    EventBus.off(Events.RECORD_ADDED, this.handleRecordChanged);
    EventBus.off(Events.RECORD_UPDATED, this.handleRecordChanged);
    EventBus.off(Events.RECORD_DELETED, this.handleRecordChanged);
    this.clearEffectTimers();
  }

  private handleSettingsChanged = () => {
    this.themeColor = ThemeUtils.getThemeColor();
  };

  private handleRecordChanged = () => {
    this.loadData();
  };

  private clearEffectTimers() {
    if (this.fireworkTimer !== -1) {
      clearInterval(this.fireworkTimer);
      this.fireworkTimer = -1;
    }
    if (this.cheerTimer !== -1) {
      clearTimeout(this.cheerTimer);
      this.cheerTimer = -1;
    }
    if (this.highlightTimer !== -1) {
      clearTimeout(this.highlightTimer);
      this.highlightTimer = -1;
    }
    if (this.bubbleTimer !== -1) {
      clearInterval(this.bubbleTimer);
      this.bubbleTimer = -1;
    }
  }

  private startBubbleFloat() {
    if (this.bubbleTimer !== -1) {
      clearInterval(this.bubbleTimer);
    }
    this.bubbleFloatPhase = false;
    this.bubbleTimer = setInterval(() => {
      this.bubbleFloatPhase = !this.bubbleFloatPhase;
    }, 2200) as number;
  }

  private closeCelebrationModal() {
    this.clearEffectTimers();
    this.showCelebrationModal = false;
    AppStorage.setOrCreate('homeTabBarHidden', false);
    this.fireworkVisible = false;
    this.cheerOpacity = 0;
    this.cheerParticleOpacity = 0;
    this.ctaScale = 1;
    this.startBrickHighlight();
    this.startBubbleFloat();
  }

  private startBrickHighlight() {
    if (this.pendingHighlightRecordId === '') {
      this.highlightedRecordId = '';
      this.highlightedBrickScale = 1;
      this.highlightedBrickOffset = 0;
      return;
    }

    const recordId = this.pendingHighlightRecordId;
    this.pendingHighlightRecordId = '';
    this.highlightedRecordId = recordId;
    this.highlightedBrickScale = 0.92;
    this.highlightedBrickOffset = 10;

    animateTo({ duration: 320, curve: Curve.EaseOut }, () => {
      this.highlightedBrickScale = 1.08;
      this.highlightedBrickOffset = -8;
    });

    this.highlightTimer = setTimeout(() => {
      animateTo({ duration: 260, curve: Curve.EaseInOut }, () => {
        this.highlightedBrickScale = 1;
        this.highlightedBrickOffset = 0;
      });
    }, 180) as number;

    this.cheerTimer = setTimeout(() => {
      this.highlightedRecordId = '';
    }, 1500) as number;
  }

  private playEntranceAnimation() {
    this.heroTranslateY = 20;
    this.heroOpacity = 0;
    this.ctaScale = 0.96;
    animateTo({ duration: 450, curve: Curve.EaseOut }, () => {
      this.heroTranslateY = 0;
      this.heroOpacity = 1;
      this.ctaScale = 1;
    });
  }

  loadData() {
    this.records = storageService.getRecordsByDate(this.today);
    this.todayCount = this.records.length;
    this.tags = storageService.getTags();
  }

  addRecord() {
    if (!this.newRecordContent.trim() || !this.selectedTagId) {
      return;
    }

    const tag = this.tags.find(t => t.id === this.selectedTagId);
    const record: Record = {
      id: DateUtils.generateId(),
      content: this.newRecordContent,
      tagId: this.selectedTagId,
      createdAt: Date.now(),
      date: this.today,
      color: tag?.color || BRICK_COLORS[0],
    };

    storageService.addRecord(record);
    this.records = [record, ...this.records.filter((item: Record) => item.id !== record.id)];
    this.todayCount += 1;
    this.newRecordContent = '';
    this.selectedTagId = '';
    this.dismissKeyboard();
    this.showAddDialog = false;
    this.tags = storageService.getTags();
    EventBus.emit(Events.RECORD_ADDED);
    setTimeout(() => {
      this.triggerCheer(record.id);
    }, 260);
  }

  openSettings() {
    AppStorage.setOrCreate('homeDrawerVisible', true);
    EventBus.emit(Events.HOME_DRAWER_OPEN);
  }

  getDisplayDate(): string {
    const date = DateUtils.parseDate(this.today);
    return `${date.getMonth() + 1}月${date.getDate()}日`;
  }

  getDisplayWeekday(): string {
    return `周${DateUtils.getDayOfWeekChinese(this.today)}`;
  }

  getBrickLabel(record: Record): string {
    const content: string = record.content.trim();
    if (!content) {
      return this.tags.find(tag => tag.id === record.tagId)?.name || '未命名';
    }

    const normalized: string = content.replace(/\s+/g, '');
    if (normalized.length <= 10) {
      return normalized;
    }

    return `${normalized.slice(0, 10)}...`;
  }

  getRecordTagName(record: Record): string {
    return this.tags.find((tag: Tag) => tag.id === record.tagId)?.name ?? '记录';
  }

  getRecordTimeText(record: Record): string {
    const date = new Date(record.createdAt);
    const hour = String(date.getHours()).padStart(2, '0');
    const minute = String(date.getMinutes()).padStart(2, '0');
    return `${hour}:${minute}`;
  }

  getTodayTagBubbles(): TodayTagBubbleData[] {
    const grouped = new Map<string, TodayTagBubbleData>();
    this.records.forEach((record: Record) => {
      const current = grouped.get(record.tagId);
      const tag = this.tags.find((item: Tag) => item.id === record.tagId);
      if (!tag) {
        return;
      }
      if (current) {
        current.count += 1;
        current.latestAt = Math.max(current.latestAt, record.createdAt);
      } else {
        grouped.set(record.tagId, {
          tag: tag,
          count: 1,
          latestAt: record.createdAt
        });
      }
    });

    return Array.from(grouped.values()).sort((a: TodayTagBubbleData, b: TodayTagBubbleData) => {
      if (b.count !== a.count) {
        return b.count - a.count;
      }
      return b.latestAt - a.latestAt;
    });
  }

  getBubbleSize(bubble: TodayTagBubbleData): number {
    const baseSize = 74;
    const countExtra = Math.min((bubble.count - 1) * 8, 22);
    return baseSize + countExtra;
  }

  getBubbleTranslateX(index: number): number {
    const offsets = [-4, 6, -8, 7, -3, 5];
    const direction = this.bubbleFloatPhase ? 1 : -1;
    return offsets[index % offsets.length] * direction * 0.22;
  }

  getBubbleTranslateY(index: number): number {
    const offsets = [-4, 3, -6, 4, -2, 5];
    const direction = this.bubbleFloatPhase ? 1 : -1;
    return offsets[index % offsets.length] * direction;
  }

  getBubbleScale(index: number): number {
    const scales = [1, 0.92, 1.08, 0.96, 1.04, 0.9];
    return scales[index % scales.length];
  }

  getRecordPreviewText(record: Record): string {
    const content: string = record.content.trim();
    if (content === '') {
      return '记录了一件小事';
    }
    return content.replace(/\s+/g, ' ');
  }

  getTodayCount(): number {
    return this.todayCount;
  }

  getYesterdayCount(): number {
    const today = DateUtils.parseDate(this.today);
    const yesterday = new Date(today.getTime() - 24 * 60 * 60 * 1000);
    return storageService.getRecordsByDate(DateUtils.formatDate(yesterday)).length;
  }

  getNextStepHeadline(): string {
    const todayCount = this.getTodayCount();
    const yesterdayCount = this.getYesterdayCount();
    const diff = todayCount - yesterdayCount;

    if (todayCount === 0) {
      return '先放下一块最小的积木，今天就算开始了';
    }
    if (diff < 0) {
      return `再补 ${Math.abs(diff)} 条，就能追平昨天的节奏`;
    }
    if (diff === 0) {
      return '今天已经追平昨天，接下来只要再往前一点点';
    }
    return '今天已经超过昨天，接下来更适合保持节奏';
  }

  getNextStepPrimaryTip(): string {
    const todayCount = this.getTodayCount();
    if (todayCount === 0) {
      return '先记录一件 2 分钟内完成的小事';
    }
    if (todayCount < 3) {
      return '把刚做完但还没记下来的那件事补上';
    }
    return '优先记录刚刚完成的那一小步，不必写太满';
  }

  getNextStepSecondaryTip(): string {
    const focusTag = this.getFocusTagName();
    if (focusTag === '还没开始') {
      return '可以从阅读、运动、饮水里挑一个最容易开始的标签';
    }
    return `今天最常出现的是“${focusTag}”，可以继续围绕它再加一块`;
  }

  getCurrentStreak(): number {
    const allRecords = storageService.getRecords();
    if (allRecords.length === 0) {
      return 0;
    }

    const uniqueDays: string[] = [];
    allRecords.forEach((record: Record) => {
      if (!uniqueDays.includes(record.date)) {
        uniqueDays.push(record.date);
      }
    });
    uniqueDays.sort();

    const activeSet = new Set<string>(uniqueDays);
    let streak = 0;
    let cursor = DateUtils.parseDate(this.today);

    while (activeSet.has(DateUtils.formatDate(cursor))) {
      streak += 1;
      cursor = new Date(cursor.getTime() - 24 * 60 * 60 * 1000);
    }

    return streak;
  }

  getFocusTagName(): string {
    if (this.records.length === 0) {
      return '还没开始';
    }

    const counts = new Map<string, number>();
    this.records.forEach((record: Record) => {
      counts.set(record.tagId, (counts.get(record.tagId) ?? 0) + 1);
    });

    let bestTagId = this.records[0].tagId;
    let bestCount = 0;
    counts.forEach((count: number, tagId: string) => {
      if (count > bestCount) {
        bestCount = count;
        bestTagId = tagId;
      }
    });

    return this.tags.find((tag: Tag) => tag.id === bestTagId)?.name ?? '今日记录';
  }

  getEnergyText(): string {
    const count = this.getTodayCount();
    if (count === 0) {
      return '先放下一块积木，今天就会开始动起来。';
    }
    if (count < 3) {
      return '节奏已经启动，继续把零散的行动留下来。';
    }
    if (count < 6) {
      return '今天的状态不错，你已经在把碎片变成结构。';
    }
    return '今天很饱满，这些积木已经拼出明显轮廓了。';
  }

  getMilestoneText(): string {
    const streak = this.getCurrentStreak();
    if (streak <= 0) {
      return '还在起步';
    }
    if (streak === 1) {
      return '轻轻起步';
    }
    if (streak < 7) {
      return `连续 ${streak} 天`;
    }
    return '稳稳向前';
  }

  getMilestoneHeadline(): string {
    const streak = this.getCurrentStreak();
    if (streak <= 0) {
      return '今天就从第一块开始';
    }
    if (streak === 1) {
      return '第一块已经稳稳落下';
    }
    if (streak < 7) {
      return `你已经连续记录 ${streak} 天`;
    }
    return `你已经稳定坚持 ${streak} 天`;
  }

  getMilestoneSubText(): string {
    const streak = this.getCurrentStreak();
    if (streak <= 0) {
      return '不必很多，先把此刻留下来。';
    }
    if (streak === 1) {
      return '节奏已经启动，今天可以继续慢慢往上搭。';
    }
    if (streak < 7) {
      return '一点点往前，也会慢慢长成自己的轮廓。';
    }
    return '这份稳定很珍贵，继续按自己的节奏慢慢搭建。';
  }

  getRemainingHint(): string {
    const count = this.getTodayCount();
    if (count === 0) {
      return '今天从第一块开始';
    }
    if (count < 3) {
      return '现在记一条，最顺手';
    }
    return '再放一块，也很好';
  }

  getHeaderMotivationText(): string {
    const messages: string[] = [
      '慢慢搭，也是在认真往前走',
      '今天也给自己留下一块小积木',
      '先动一下，节奏就会慢慢回来',
      '不必很满，先开始就已经很好',
      '把这一刻记下来，今天就有了形状',
      '先落下一小块，接下来的路会更顺',
      '一点点推进，也会慢慢搭出轮廓'
    ];
    const date = DateUtils.parseDate(this.today);
    const index = (date.getFullYear() + date.getMonth() + 1 + date.getDate()) % messages.length;
    return messages[index];
  }

  private triggerCheer(recordId: string) {
    const count = this.getTodayCount();
    if (count <= 1) {
      this.cheerText = '第一块积木已经落下';
      this.cheerSubText = '今天已经正式开始了';
    } else if (count < 4) {
      this.cheerText = `很好，今天已经有 ${count} 块积木了`;
      this.cheerSubText = '再积一块，今天会更完整';
    } else {
      this.cheerText = `今天已经积累到 ${count} 块，继续保持`;
      this.cheerSubText = '你的节奏正在慢慢成形';
    }

    this.cheerOpacity = 0;
    this.cheerTranslateY = 16;
    this.cheerScale = 0.9;
    this.cheerParticleOpacity = 0;
    this.cheerParticleOffset = 8;
    this.fireworkFrame = 0;
    this.fireworkVisible = true;
    this.showCelebrationModal = true;
    AppStorage.setOrCreate('homeTabBarHidden', true);
    this.pendingHighlightRecordId = recordId;
    this.highlightedRecordId = '';
    this.highlightedBrickScale = 1;
    this.highlightedBrickOffset = 0;

    this.clearEffectTimers();

    animateTo({ duration: 320, curve: Curve.EaseOut }, () => {
      this.cheerOpacity = 1;
      this.cheerTranslateY = 0;
      this.cheerScale = 1;
      this.cheerParticleOpacity = 1;
      this.cheerParticleOffset = -22;
      this.ctaScale = 1.03;
    });

    this.fireworkTimer = setInterval(() => {
      if (this.fireworkFrame >= 40) {
        if (this.fireworkTimer !== -1) {
          clearInterval(this.fireworkTimer);
          this.fireworkTimer = -1;
        }
        this.fireworkVisible = false;
        return;
      }
      this.fireworkFrame += 1;
    }, 33) as number;

    setTimeout(() => {
      animateTo({ duration: 260, curve: Curve.EaseInOut }, () => {
        this.ctaScale = 1;
      });
    }, 180);
  }

  private getFireworkProgress(): number {
    return this.fireworkFrame / 40;
  }

  private getBurstProgress(delayFrames: number): number {
    const shifted = this.fireworkFrame - delayFrames;
    if (shifted <= 0) {
      return 0;
    }
    if (shifted >= 24) {
      return 1;
    }
    return shifted / 24;
  }

  private getSmoothBurstProgress(delayFrames: number): number {
    const progress = this.getBurstProgress(delayFrames);
    if (progress <= 0) {
      return 0;
    }
    if (progress >= 1) {
      return 1;
    }
    if (progress <= 0.24) {
      return progress * 2.3;
    }
    const shifted = (progress - 0.24) / 0.76;
    return 0.55 + (1 - Math.pow(1 - shifted, 2.4)) * 0.45;
  }

  private getBurstDistance(baseDistance: number, delayFrames: number): number {
    const progress = this.getSmoothBurstProgress(delayFrames);
    if (progress <= 0) {
      return baseDistance * 0.12;
    }
    if (progress <= 0.58) {
      return baseDistance * (0.12 + progress * 1.35);
    }
    if (progress <= 0.9) {
      return baseDistance * (0.9 + (progress - 0.58) * 0.18);
    }
    return baseDistance * 0.96;
  }

  private getBurstOpacity(delayFrames: number): number {
    const progress = this.getSmoothBurstProgress(delayFrames);
    if (!this.fireworkVisible || progress <= 0) {
      return 0;
    }
    if (progress <= 0.18) {
      return 0.45 + progress * 3.1;
    }
    if (progress <= 0.74) {
      return 1;
    }
    return Math.max(0, 1 - (progress - 0.74) * 2.9);
  }

  private getBurstScale(multiplier: number, delayFrames: number): number {
    const progress = this.getSmoothBurstProgress(delayFrames);
    if (progress <= 0) {
      return 0.28 * multiplier;
    }
    if (progress <= 0.18) {
      return (0.24 + progress * 2.6) * multiplier;
    }
    if (progress <= 0.62) {
      return (0.7 + (progress - 0.18) * 0.5) * multiplier;
    }
    return (0.92 - (progress - 0.62) * 0.42) * multiplier;
  }

  private getFireworkDistance(baseDistance: number): number {
    const progress = this.getFireworkProgress();
    if (progress <= 0.35) {
      return baseDistance * (0.35 + progress * 2.4);
    }
    if (progress <= 0.75) {
      return baseDistance * (1.19 + (progress - 0.35) * 0.7);
    }
    return baseDistance * (1.47 - (progress - 0.75) * 0.9);
  }

  private getFireworkOpacity(): number {
    const progress = this.getFireworkProgress();
    if (!this.fireworkVisible) {
      return 0;
    }
    if (progress <= 0.2) {
      return 0.85;
    }
    if (progress <= 0.7) {
      return 1;
    }
    return Math.max(0, 1 - (progress - 0.7) * 3.2);
  }

  private getFireworkScale(multiplier: number): number {
    const progress = this.getFireworkProgress();
    if (progress <= 0.4) {
      return (0.45 + progress * 1.25) * multiplier;
    }
    return (0.95 - (progress - 0.4) * 0.38) * multiplier;
  }

  getQuickTags(): Tag[] {
    const presets: QuickTagPreset[] = [
      { name: '阅读', color: '#7FB7FF', bgColor: '#EEF6FF', icon: '📘' },
      { name: '运动', color: '#FF9A5E', bgColor: '#FFF1E8', icon: '🏃' },
      { name: '思考', color: '#B08CFF', bgColor: '#F3EDFF', icon: '💡' },
      { name: '饮水', color: '#7EDDB7', bgColor: '#EAFBF5', icon: '💧' },
      { name: '写作', color: '#7FB7FF', bgColor: '#EEF6FF', icon: '✍️' },
      { name: '冥想', color: '#59D0B2', bgColor: '#ECFAF5', icon: '🧘' },
      { name: '学习', color: '#B08CFF', bgColor: '#F3EDFF', icon: '📚' }
    ];

    return presets.map((preset, index) => {
      const existing = this.tags.find(tag => tag.name === preset.name);
      return existing ?? {
        id: `quick-${index + 1}`,
        name: preset.name,
        color: preset.color,
        icon: preset.icon
      };
    });
  }

  getSelectedTag(): Tag | undefined {
    const fromTags = this.tags.find(tag => tag.id === this.selectedTagId);
    if (fromTags) {
      return fromTags;
    }
    return this.getQuickTags().find(tag => tag.id === this.selectedTagId);
  }

  private selectTag(tag: Tag) {
    const storedTag = this.ensureTag(tag);
    this.selectedTagId = storedTag.id;
  }

  private clearSelectedTag() {
    this.selectedTagId = '';
  }

  getRecordCountText(): string {
    return `${this.newRecordContent.length}/100`;
  }

  getSubmitButtonText(): string {
    if (this.selectedTagId === '') {
      return '先选一个标签';
    }
    if (this.newRecordContent.trim() === '') {
      return '写下刚刚完成的事';
    }
    return '完成记录';
  }

  canSubmitRecord(): boolean {
    return this.selectedTagId !== '' && this.newRecordContent.trim() !== '';
  }

  closeAddSheet() {
    this.dismissKeyboard();
    this.showAddDialog = false;
    AppStorage.setOrCreate('homeTabBarHidden', false);
  }

  dismissKeyboard() {
    this.addRecordController.stopEditing();
    focusControl.requestFocus(this.dismissFocusId);
  }

  ensureTag(tag: Tag): Tag {
    const existing = this.tags.find(item => item.id === tag.id || item.name === tag.name);
    if (existing) {
      return existing;
    }

    const nextTag: Tag = {
      id: DateUtils.generateId(),
      name: tag.name,
      color: tag.color,
      icon: tag.icon
    };
    const nextTags = [...this.tags, nextTag];
    storageService.saveTags(nextTags);
    this.tags = nextTags;
    return nextTag;
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          Row() {
            this.CircleAction('☰', () => {
              this.openSettings();
            });

            Text(this.getHeaderMotivationText())
              .layoutWeight(1)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.lightTextColor)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ left: 14, right: 4 });
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ top: 6, bottom: 10 });

          this.HeroCard();
          this.PrimaryActionCard();
          this.TodayBrickSection();
          this.InsightPanel();
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 10, bottom: this.tabBarSafeOffset });
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.pageBackground)
      .scrollBar(BarState.Off)
      .onClick(() => {
        this.dismissKeyboard();
      });

      if (this.showAddDialog) {
        this.AddRecordOverlay();
      }

      if (this.showCelebrationModal) {
        this.CelebrationModal();
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
  HeroCard() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width(138)
        .height(138)
        .backgroundColor(ThemeUtils.withAlpha(this.themeColor, '14'))
        .borderRadius(69)
        .translate({ x: 236, y: -72 });

      Column()
        .width(82)
        .height(82)
        .backgroundColor('#20FFFFFF')
        .borderRadius(41)
        .translate({ x: 284, y: 6 });

      Column()
        .width(34)
        .height(34)
        .backgroundColor(ThemeUtils.withAlpha(this.themeColor, '18'))
        .borderRadius(17)
        .translate({ x: 316, y: 96 });

      Column() {
        Row() {
          Text(`今日 · ${this.getDisplayWeekday()}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.titleColor);

          Blank();

          Text(this.getDisplayDate())
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.themeColor)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(ThemeUtils.getTintColor(this.themeColor, '24'))
            .borderRadius(14);
        }
        .width('100%');

        Text(this.getEnergyText())
          .fontSize(13)
          .lineHeight(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.secondaryTextColor)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 10 });

        Row() {
          this.HeroStatusPill(0, '已落下', `${this.todayCount}`);
          this.HeroStatusPill(1, '连续', `${this.getCurrentStreak()} 天`);
          this.HeroStatusPill(2, '聚焦', this.getFocusTagName());
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({ left: 4, right: 4, top: 10, bottom: 10 })
        .backgroundColor('#F5FCFB')
        .borderRadius(18)
        .margin({ top: 12 });
      }
      .width('100%');
    }
    .width('100%')
    .backgroundColor('#FCFDFE')
    .borderRadius(28)
    .padding({ left: 18, right: 18, top: 18, bottom: 16 })
    .border({ width: 1, color: ThemeUtils.getTintColor(this.themeColor, '24') })
    .shadow({
      radius: 22,
      color: ThemeUtils.withAlpha(this.themeColor, '10'),
      offsetX: 0,
      offsetY: 10
    })
    .translate({ y: this.heroTranslateY })
    .opacity(this.heroOpacity);
  }

  @Builder
  HeroStatusPill(iconType: number, label: string, value: string) {
    Column() {
      this.HeroStatusIcon(iconType);

      Text(label)
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor('#95A0B6')
        .textAlign(TextAlign.Center)
        .margin({ top: 6 });

      Text(value)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
        .margin({ top: 6 });
    }
    .layoutWeight(1)
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor(Color.Transparent)
    .borderRadius(0)
    .height(70)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({ left: 0, right: 0 });
  }

  @Builder
  HeroStatusIcon(iconType: number) {
    Stack({ alignContent: Alignment.Center }) {
      if (iconType === 0) {
        Column()
          .width(12)
          .height(12)
          .border({ width: 1.8, color: this.themeColor })
          .borderRadius(6);
      } else if (iconType === 1) {
        Text('🔥')
          .fontSize(14);
      } else {
        Column() {
          Row()
            .width(12)
            .height(2)
            .backgroundColor('#F1C24D')
            .borderRadius(1)
            .margin({ bottom: 2 });

          Row()
            .width(12)
            .height(2)
            .backgroundColor('#F1C24D')
            .borderRadius(1)
            .margin({ bottom: 2 });

          Row()
            .width(12)
            .height(2)
            .backgroundColor('#F1C24D')
            .borderRadius(1);
        }
        .height(12);
      }
    }
    .width(18)
    .height(18);
  }

  @Builder
  PrimaryActionCard() {
    Column() {
      Text('今天也往前一点点')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.lightTextColor)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 12 });

      Button() {
        Row() {
          Text('+')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ right: 12 });
          Text('记录一下刚刚做的事')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF');
        }
        .justifyContent(FlexAlign.Center);
      }
      .width('100%')
      .height(50)
      .backgroundColor(this.themeColor)
      .borderRadius(25)
      .shadow({
        radius: 18,
        color: ThemeUtils.withAlpha(this.themeColor, '14'),
        offsetX: 0,
        offsetY: 10
      })
      .scale({ x: this.ctaScale, y: this.ctaScale })
      .onClick(() => {
        this.showAddDialog = true;
        AppStorage.setOrCreate('homeTabBarHidden', true);
      });
    }
    .width('100%')
    .margin({ top: 14 })
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  TodayBrickSection() {
    Column() {
      Row() {
        Text('今天搭了什么')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.titleColor);
      }
      .width('100%')
      .margin({ bottom: 16 });

      if (this.records.length === 0) {
        this.EmptyBrickState();
      } else {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
          ForEach(this.getTodayTagBubbles(), (bubble: TodayTagBubbleData, index: number) => {
            this.TagBubble(bubble, index);
          });
        }
        .width('100%');
      }
    }
    .width('100%')
    .margin({ top: 20 });
  }

  @Builder
  TagBubble(bubble: TodayTagBubbleData, index: number) {
    Button() {
      Column() {
        Text(bubble.tag.name)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.titleColor)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .margin({ bottom: 6 });

        Text(`${bubble.count}块`)
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(TagStyleUtils.getChipText(bubble.tag.color))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#FFFFFF')
          .borderRadius(10);
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center);
    }
    .width(this.getBubbleSize(bubble))
    .height(this.getBubbleSize(bubble))
    .margin({ left: 2, right: 14, bottom: 16 })
    .padding({ left: 8, right: 8, top: 8, bottom: 8 })
    .backgroundColor(TagStyleUtils.getChipBackground(bubble.tag.color))
    .borderRadius(this.getBubbleSize(bubble) / 2)
    .shadow({
      radius: 14,
      color: ThemeUtils.withAlpha(bubble.tag.color, '20'),
      offsetX: 0,
      offsetY: 8
    })
    .translate({
      x: this.getBubbleTranslateX(index),
      y: this.getBubbleTranslateY(index)
    })
    .scale({
      x: this.getBubbleScale(index),
      y: this.getBubbleScale(index)
    })
    .animation({ duration: 2200, curve: Curve.EaseInOut })
    .onClick(() => {
      RouterManager.goToTodayTagDetail(bubble.tag.id);
    });
  }

  @Builder
  InsightPanel() {
    Column() {
      Text('下一步建议')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.lightTextColor);

      Text(this.getNextStepHeadline())
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor)
        .textAlign(TextAlign.Center)
        .margin({ top: 8 });

      Text('根据今天的记录，给你两个更容易继续下去的方向')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#8C97AC')
        .textAlign(TextAlign.Center)
        .lineHeight(18)
        .margin({ top: 8 });

      Row() {
        this.InsightChip('现在适合', this.getNextStepPrimaryTip());
        this.InsightChip('继续围绕', this.getNextStepSecondaryTip());
      }
      .width('100%')
      .margin({ top: 16 });
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(22)
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .margin({ top: 12 })
    .shadow({
      radius: 24,
      color: this.cardShadowColor,
      offsetX: 0,
      offsetY: 10
    });
  }

  @Builder
  InsightChip(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(11)
        .fontColor(this.lightTextColor);

      Text(value)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.titleColor)
        .textAlign(TextAlign.Center)
        .lineHeight(18)
        .margin({ top: 6 });
    }
    .layoutWeight(1)
    .constraintSize({ minHeight: 92 })
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor('#F6F8FC')
    .borderRadius(18)
    .margin({ left: 4, right: 4 });
  }

  @Builder
  CelebrationFirework() {
    Stack({ alignContent: Alignment.Center }) {
        this.FireworkBurst(0, 0, 0.96, 0);
        this.FireworkBurst(-56, -24, 0.72, 3);
        this.FireworkBurst(58, -20, 0.74, 4);
        this.FireworkBurst(-36, 42, 0.66, 7);
        this.FireworkBurst(42, 38, 0.68, 8);
        this.FireworkBurst(0, -54, 0.62, 10);
        this.FireworkBurst(-74, 12, 0.56, 12);
        this.FireworkBurst(74, 10, 0.56, 13);
        this.FireworkBurst(-16, 70, 0.54, 15);
        this.FireworkBurst(18, 72, 0.54, 16);

        Column()
          .width(18)
          .height(18)
          .backgroundColor('#FFFDF7')
          .borderRadius(9)
          .opacity(this.getBurstOpacity(0))
          .scale({ x: this.getBurstScale(1.2, 0), y: this.getBurstScale(1.2, 0) });
    }
    .width(232)
    .height(232)
    .clip(true);
  }

  @Builder
  CelebrationModal() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#7A0C121A')
        .onClick(() => {
          this.closeCelebrationModal();
        });

      Column()
        .width(280)
        .height(280)
        .backgroundColor(ThemeUtils.withAlpha(this.themeColor, '24'))
        .borderRadius(140)
        .translate({ x: -88, y: -146 })
        .shadow({
          radius: 40,
          color: ThemeUtils.withAlpha(this.themeColor, '28'),
          offsetX: 0,
          offsetY: 0
        });

      Column()
        .width(224)
        .height(224)
        .backgroundColor('#1FFFFFFF')
        .borderRadius(112)
        .translate({ x: 118, y: 168 })
        .shadow({ radius: 36, color: '#1AFFFFFF', offsetX: 0, offsetY: 0 });

      Column() {
        Stack({ alignContent: Alignment.Top }) {
          Column()
            .width(232)
            .height(232)
            .backgroundColor(ThemeUtils.withAlpha(this.themeColor, '18'))
            .borderRadius(116)
            .translate({ y: -34 })
            .shadow({
              radius: 30,
              color: ThemeUtils.withAlpha(this.themeColor, '20'),
              offsetX: 0,
              offsetY: 0
            });

          this.CelebrationFirework();

          Column() {
            Text('积木已落下')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF');

            Text(this.cheerText)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#F5F7FA')
              .textAlign(TextAlign.Center)
              .margin({ top: 14 });

            Text(this.cheerSubText)
              .fontSize(12)
              .lineHeight(20)
              .textAlign(TextAlign.Center)
              .fontColor('#D9E1EA')
              .margin({ top: 8 });

            Text('点一下关闭，庆祝完整停留')
              .fontSize(11)
              .fontColor('#95A2B5')
              .margin({ top: 14 });

            Button('关闭')
              .width('100%')
              .height(44)
              .margin({ top: 26 })
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .backgroundColor(this.themeColor)
              .borderRadius(24)
              .shadow({
                radius: 16,
                color: ThemeUtils.withAlpha(this.themeColor, '30'),
                offsetX: 0,
                offsetY: 10
              })
              .onClick(() => {
                this.closeCelebrationModal();
              });
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 196, bottom: 26 })
          .alignItems(HorizontalAlign.Center);
        }
        .width(332)
        .height(450)
        .backgroundColor('#E3131822')
        .borderRadius(30)
        .border({ width: 1, color: '#2EFFFFFF' })
        .shadow({ radius: 36, color: '#52000000', offsetX: 0, offsetY: 22 });
      }
      .onClick(() => {
      });
    }
    .width('100%')
    .height('100%')
    .zIndex(99);
  }

  @Builder
  FireworkBurst(offsetX: number, offsetY: number, burstScale: number, delayFrames: number) {
    Stack({ alignContent: Alignment.Center }) {
      this.FireworkParticle('#FFFFFF', -1.45, -0.2, 0.9 * burstScale, 22, offsetX, offsetY, delayFrames);
      this.FireworkParticle('#FFF1A8', -1.15, -1.0, 0.86 * burstScale, 20, offsetX, offsetY, delayFrames);
      this.FireworkParticle(ThemeUtils.getTintColor(this.themeColor, 'EE'), -0.55, -1.35, 0.82 * burstScale, 18, offsetX,
        offsetY, delayFrames);
      this.FireworkParticle('#FFD6E5', 0.1, -1.55, 0.9 * burstScale, 21, offsetX, offsetY, delayFrames);
      this.FireworkParticle('#FFFFFF', 0.8, -1.15, 0.78 * burstScale, 17, offsetX, offsetY, delayFrames);
      this.FireworkParticle(ThemeUtils.getTintColor(this.themeColor, 'CC'), 1.45, -0.3, 0.92 * burstScale, 22, offsetX,
        offsetY, delayFrames);
      this.FireworkParticle('#FFF1A8', 1.18, 0.58, 0.84 * burstScale, 18, offsetX, offsetY, delayFrames);
      this.FireworkParticle('#FFD6E5', 0.72, 1.22, 0.88 * burstScale, 20, offsetX, offsetY, delayFrames);
      this.FireworkParticle('#FFFFFF', 0, 1.5, 0.74 * burstScale, 17, offsetX, offsetY, delayFrames);
      this.FireworkParticle(ThemeUtils.getTintColor(this.themeColor, 'EE'), -0.75, 1.08, 0.8 * burstScale, 18, offsetX,
        offsetY, delayFrames);
      this.FireworkParticle('#FFF1A8', -1.28, 0.54, 0.76 * burstScale, 17, offsetX, offsetY, delayFrames);
      this.FireworkParticle(ThemeUtils.getTintColor(this.themeColor, '99'), 0, -0.9, 0.58 * burstScale, 13, offsetX, offsetY,
        delayFrames);
      this.FireworkParticle('#FFFFFF', 0.95, 0, 0.54 * burstScale, 13, offsetX, offsetY, delayFrames);
      this.FireworkParticle('#FFD6E5', -0.85, 0, 0.54 * burstScale, 13, offsetX, offsetY, delayFrames);
      this.FireworkParticle('#FFF1A8', 0, 0.96, 0.5 * burstScale, 11, offsetX, offsetY, delayFrames);
      this.FireworkParticle('#FFFFFF', -1.8, -0.72, 0.56 * burstScale, 15, offsetX, offsetY, delayFrames);
      this.FireworkParticle(ThemeUtils.getTintColor(this.themeColor, 'EE'), -1.72, 0.76, 0.52 * burstScale, 13, offsetX, offsetY,
        delayFrames);
      this.FireworkParticle('#FFD6E5', 1.82, -0.78, 0.54 * burstScale, 15, offsetX, offsetY, delayFrames);
      this.FireworkParticle('#FFF1A8', 1.76, 0.84, 0.52 * burstScale, 13, offsetX, offsetY, delayFrames);
      this.FireworkParticle('#FFFFFF', -0.18, -1.95, 0.5 * burstScale, 13, offsetX, offsetY, delayFrames);
      this.FireworkParticle(ThemeUtils.getTintColor(this.themeColor, 'CC'), 0.12, 1.96, 0.48 * burstScale, 13, offsetX, offsetY,
        delayFrames);
      this.FireworkParticle('#B9F7FF', -1.9, 0.08, 0.42 * burstScale, 11, offsetX, offsetY, delayFrames);
      this.FireworkParticle('#FFE3A1', 1.92, 0.06, 0.42 * burstScale, 11, offsetX, offsetY, delayFrames);
      this.FireworkParticle('#FFC7DA', 0.02, -2.08, 0.42 * burstScale, 11, offsetX, offsetY, delayFrames);
      this.FireworkParticle('#D7FFD7', -0.04, 2.12, 0.42 * burstScale, 11, offsetX, offsetY, delayFrames);
      this.FireworkParticle('#FFF1A8', -1.34, -1.56, 0.5 * burstScale, 13, offsetX, offsetY, delayFrames);
      this.FireworkParticle('#FFD6E5', 1.4, -1.48, 0.5 * burstScale, 13, offsetX, offsetY, delayFrames);
      this.FireworkParticle('#FFFFFF', -1.36, 1.52, 0.5 * burstScale, 13, offsetX, offsetY, delayFrames);
      this.FireworkParticle(ThemeUtils.getTintColor(this.themeColor, 'EE'), 1.32, 1.58, 0.5 * burstScale, 13, offsetX, offsetY,
        delayFrames);
    }
    .width(132)
    .height(132);
  }

  @Builder
  FireworkParticle(color: string, xFactor: number, yFactor: number, scaleFactor: number, size: number, burstOffsetX: number = 0,
    burstOffsetY: number = 0, delayFrames: number = 0) {
    Column()
      .width(size)
      .height(size)
      .backgroundColor(color)
      .borderRadius(size / 2)
      .opacity(this.getBurstOpacity(delayFrames))
      .scale({
        x: this.getBurstScale(scaleFactor, delayFrames),
        y: this.getBurstScale(scaleFactor, delayFrames)
      })
      .translate({
        x: burstOffsetX + this.getBurstDistance(34, delayFrames) * xFactor,
        y: burstOffsetY + this.getBurstDistance(34, delayFrames) * yFactor
      })
      .shadow({
        radius: 12,
        color: color,
        offsetX: 0,
        offsetY: 0
      });
  }

  @Builder
  CircleAction(symbol: string, action: () => void) {
    Button() {
      Text(symbol)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColor);
    }
    .width(28)
    .height(28)
    .backgroundColor(Color.Transparent)
    .borderRadius(0)
    .padding(0)
    .onClick(() => {
      action();
    });
  }

  @Builder
  BrickCell(record: Record) {
    Row() {
      Row() {
        Text(this.getRecordTagName(record))
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(record.color)
          .borderRadius(12);

        Text(this.getRecordPreviewText(record))
          .layoutWeight(1)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.titleColor)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 10, right: 10 });
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center);

      Text(this.getRecordTimeText(record))
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.lightTextColor);
    }
    .width('100%')
    .constraintSize({ minHeight: 56 })
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .padding({ left: 14, right: 16, top: 14, bottom: 14 })
    .margin({ bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .scale({
      x: this.highlightedRecordId === record.id ? this.highlightedBrickScale : 1,
      y: this.highlightedRecordId === record.id ? this.highlightedBrickScale : 1
    })
    .translate({ y: this.highlightedRecordId === record.id ? this.highlightedBrickOffset : 0 })
    .border({
      width: this.highlightedRecordId === record.id ? 1.5 : 0,
      color: this.highlightedRecordId === record.id ? ThemeUtils.withAlpha(record.color, '40') : '#FFFFFF'
    })
    .shadow({
      radius: this.highlightedRecordId === record.id ? 18 : 12,
      color: this.highlightedRecordId === record.id ? ThemeUtils.withAlpha(record.color, '28') : '#12000000',
      offsetX: 0,
      offsetY: this.highlightedRecordId === record.id ? 12 : 6
    });
  }

  @Builder
  EmptyBrickState() {
    Column() {
      Text('今天还没有记录')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor);

      Text('先记录第一条，今天就开始了')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.secondaryTextColor)
        .textAlign(TextAlign.Center)
        .margin({ top: 8 });

      Button('去记录第一条')
        .height(34)
        .margin({ top: 14 })
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColor)
        .backgroundColor(ThemeUtils.getTintColor(this.themeColor, '18'))
        .borderRadius(17)
        .padding({ left: 14, right: 14 })
        .onClick(() => {
          this.showAddDialog = true;
          AppStorage.setOrCreate('homeTabBarHidden', true);
        });
    }
    .width('100%')
    .constraintSize({ minHeight: 108 })
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .border({
      width: 1,
      color: this.emptyBrickBorder
    })
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  AddRecordSheet() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        Row() {
          Column() {
          }
          .width(54)
          .height(6)
          .backgroundColor('#E9EDF4')
          .borderRadius(3);
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 6, bottom: 18 });

        Row() {
          Column() {
            Text('记录刚刚完成的小事')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.titleColor);
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start);
        }
        .width('100%')
        .margin({ bottom: 18 });

        TextArea({ placeholder: '选一个标签，再写下今天新增的一块积木', text: $$this.newRecordContent, controller: this.addRecordController })
          .width('100%')
          .height(144)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.titleColor)
          .placeholderColor('#AAB3C3')
          .backgroundColor('#F8FAFD')
          .borderRadius(8)
          .border({ width: 1, color: '#EEF2F7' })
          .padding({ left: 18, right: 18, top: 18, bottom: 18 })
          .maxLength(100)
          .shadow({ radius: 10, color: '#12000000', offsetX: 0, offsetY: 4 })
          .margin({ bottom: 8 });

        Text(this.getRecordCountText())
          .width('100%')
          .fontSize(11)
          .textAlign(TextAlign.End)
          .fontColor(this.lightTextColor)
          .margin({ bottom: 16 });

        Row() {
          Text('当前标签')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.secondaryTextColor)
            .margin({ right: 10 });

          if (this.getSelectedTag()) {
            Text((this.getSelectedTag() as Tag).name)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(TagStyleUtils.getChipText((this.getSelectedTag() as Tag).color))
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor(TagStyleUtils.getChipBackground((this.getSelectedTag() as Tag).color))
              .border({
                width: 1,
                color: TagStyleUtils.getChipBorder((this.getSelectedTag() as Tag).color)
              })
              .borderRadius(18);
          } else {
            Text('还未选择')
              .fontSize(12)
              .fontColor(this.lightTextColor);
          }
        }
        .width('100%')
        .margin({ bottom: 18 });

        Text('快速标签')
          .width('100%')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.secondaryTextColor)
          .margin({ bottom: 16 });

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.getQuickTags(), (tag: Tag) => {
            this.QuickTagChip(tag);
          });
        }
        .width('100%')
        .margin({ bottom: 18 });

        Button() {
          Text(this.getSubmitButtonText())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF');
        }
        .width('100%')
        .height(44)
        .backgroundColor(this.canSubmitRecord() ? this.themeColor : '#C8CFDB')
        .borderRadius(24)
        .enabled(this.canSubmitRecord())
        .onClick(() => {
          this.dismissKeyboard();
          this.addRecord();
        });
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 10, bottom: 24 });

      Button() {
        Text('×')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#97A3B7');
      }
      .width(30)
      .height(30)
      .backgroundColor('#F3F6FA')
      .borderRadius(15)
      .margin({ top: 10, right: 10 })
      .onClick(() => {
        this.closeAddSheet();
      });
    }
    .width('100%')
    .borderRadius({ topLeft: 28, topRight: 28 })
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 20, color: '#18000000', offsetX: 0, offsetY: -4 })
    .onClick(() => {
      this.dismissKeyboard();
    });
  }

  @Builder
  AddRecordOverlay() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#22000000')
        .onClick(() => {
          this.closeAddSheet();
        });

      this.AddRecordSheet();
    }
    .width('100%')
    .height('100%')
    .zIndex(99);
  }

  @Builder
  SheetActionButton(type: string) {
    Button() {
      if (type === 'mic') {
        this.MicIcon();
      } else {
        this.TagOutlineIcon();
      }
    }
    .width(58)
    .height(58)
    .backgroundColor(this.softTint)
    .borderRadius(29)
    .margin({ right: 18 });
  }

  @Builder
  QuickTagChip(tag: Tag) {
    Button(tag.name)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.selectedTagId === tag.id ? TagStyleUtils.getSelectedText() : TagStyleUtils.getChipText(tag.color))
      .backgroundColor(this.selectedTagId === tag.id ? TagStyleUtils.getSelectedBackground(tag.color) : TagStyleUtils.getChipBackground(tag.color))
      .border({
        width: this.selectedTagId === tag.id ? 0 : 1,
        color: TagStyleUtils.getChipBorder(tag.color)
      })
      .borderRadius(20)
      .height(36)
      .padding({ left: 16, right: 16 })
      .margin({ right: 10, bottom: 10 })
      .onClick(() => {
        this.dismissKeyboard();
        this.selectTag(tag);
      });
  }

  getTagChipBg(tag: Tag): string {
    return TagStyleUtils.getChipBackground(tag.color);
  }

  @Builder
  MicIcon() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(12)
          .height(18)
          .borderRadius(8)
          .border({ width: 2, color: '#9BA6BA' });
      }
      .width(18)
      .height(22);

      Column()
        .width(16)
        .height(8)
        .margin({ top: 2 })
        .border({
          width: { left: 2, right: 2, bottom: 2, top: 0 },
          color: '#9BA6BA'
        })
        .borderRadius({ bottomLeft: 8, bottomRight: 8 });

      Column()
        .width(2)
        .height(8)
        .backgroundColor('#9BA6BA')
        .margin({ top: 1 });

      Column()
        .width(12)
        .height(2)
        .backgroundColor('#9BA6BA')
        .borderRadius(1)
        .margin({ top: 1 });
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  TagOutlineIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(18)
        .height(18)
        .border({
          width: 2,
          color: '#9BA6BA'
        })
        .borderRadius(4)
        .rotate({ angle: 45 });

      Column()
        .width(4)
        .height(4)
        .backgroundColor('#9BA6BA')
        .borderRadius(2)
        .margin({ left: 6, top: -1 });
    }
    .width(24)
    .height(24);
  }
}
