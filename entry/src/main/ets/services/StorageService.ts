import { relationalStore } from '@kit.ArkData';
import { STORAGE_KEYS } from '../constants/AppConstants';
import { AppSettings, Record, ReminderItem, StatsData, Tag } from '../models/DataModels';
import { EventBus, Events } from './EventBus';

const RECORD_KEY = STORAGE_KEYS.RECORDS;
const TAG_KEY = STORAGE_KEYS.TAGS;
const STATS_KEY = STORAGE_KEYS.STATS;
const SETTINGS_KEY = STORAGE_KEYS.SETTINGS;

const DB_NAME = 'brick_time.db';
const TABLE_RECORDS = 'records';
const TABLE_TAGS = 'tags';
const TABLE_META = 'meta';

class StorageService {
  private legacyStorage = AppStorage;
  private store: relationalStore.RdbStore | null = null;
  private initialized: boolean = false;
  private recordsCache: Record[] = [];
  private tagsCache: Tag[] = [];
  private statsCache: StatsData = this.getDefaultStatsData();
  private settingsCache: AppSettings = this.getDefaultSettingsData();

  async init(context: Context): Promise<void> {
    if (this.initialized) {
      return;
    }

    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    this.store = await relationalStore.getRdbStore(context, config);
    this.createTables();
    this.migrateLegacyDataIfNeeded();
    this.reloadCachesFromDb();
    this.initialized = true;
  }

  private createTables(): void {
    if (!this.store) {
      return;
    }
    this.store.executeSync(`CREATE TABLE IF NOT EXISTS ${TABLE_RECORDS} (
      id TEXT PRIMARY KEY,
      content TEXT NOT NULL,
      tagId TEXT NOT NULL,
      createdAt INTEGER NOT NULL,
      date TEXT NOT NULL,
      color TEXT NOT NULL
    )`);
    this.store.executeSync(`CREATE TABLE IF NOT EXISTS ${TABLE_TAGS} (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL UNIQUE,
      color TEXT NOT NULL,
      icon TEXT NOT NULL
    )`);
    this.store.executeSync(`CREATE TABLE IF NOT EXISTS ${TABLE_META} (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )`);
  }

  private migrateLegacyDataIfNeeded(): void {
    if (!this.store) {
      return;
    }

    const recordCount = this.queryCount(TABLE_RECORDS);
    const tagCount = this.queryCount(TABLE_TAGS);
    const metaCount = this.queryCount(TABLE_META);

    if (recordCount === 0 && tagCount === 0 && metaCount === 0) {
      const legacyTags = this.readLegacyTags();
      const legacyRecords = this.readLegacyRecords();
      const legacyStats = this.readLegacyStats();
      const legacySettings = this.readLegacySettings();

      const normalizedTags = this.normalizeTags(legacyTags);
      const canonicalTagIdMap = this.buildCanonicalTagIdMap(legacyTags, normalizedTags);
      const normalizedRecords = this.normalizeRecords(legacyRecords, canonicalTagIdMap, normalizedTags);

      normalizedTags.forEach((tag: Tag) => {
        this.insertTagRow(tag);
      });
      normalizedRecords.forEach((record: Record) => {
        this.insertRecordRow(record);
      });
      this.saveMetaValue(STATS_KEY, JSON.stringify(legacyStats));
      this.saveMetaValue(SETTINGS_KEY, JSON.stringify(legacySettings));
      this.clearLegacyStorage();
      return;
    }

    this.repairCurrentDatabase();
  }

  private repairCurrentDatabase(): void {
    const currentTags = this.loadTagsFromDb();
    const normalizedTags = this.normalizeTags(currentTags);
    const tagMap = this.buildCanonicalTagIdMap(currentTags, normalizedTags);
    const currentRecords = this.loadRecordsFromDb();
    const normalizedRecords = this.normalizeRecords(currentRecords, tagMap, normalizedTags);

    this.replaceAllTags(normalizedTags);
    this.replaceAllRecords(normalizedRecords);

    if (this.loadMetaValue(STATS_KEY) === '') {
      this.saveMetaValue(STATS_KEY, JSON.stringify(this.getDefaultStatsData()));
    }
    if (this.loadMetaValue(SETTINGS_KEY) === '') {
      this.saveMetaValue(SETTINGS_KEY, JSON.stringify(this.getDefaultSettingsData()));
    }
  }

  private readLegacyRecords(): Record[] {
    const data = this.legacyStorage.get<string>(RECORD_KEY);
    if (!data) {
      return [];
    }
    try {
      return JSON.parse(data) as Record[];
    } catch {
      return [];
    }
  }

  private readLegacyTags(): Tag[] {
    const data = this.legacyStorage.get<string>(TAG_KEY);
    if (!data) {
      return this.getBootstrapTags();
    }
    try {
      return JSON.parse(data) as Tag[];
    } catch {
      return this.getBootstrapTags();
    }
  }

  private readLegacyStats(): StatsData {
    const data = this.legacyStorage.get<string>(STATS_KEY);
    if (!data) {
      return this.getDefaultStatsData();
    }
    try {
      return JSON.parse(data) as StatsData;
    } catch {
      return this.getDefaultStatsData();
    }
  }

  private readLegacySettings(): AppSettings {
    const data = this.legacyStorage.get<string>(SETTINGS_KEY);
    if (!data) {
      return this.getDefaultSettingsData();
    }
    try {
      return this.normalizeSettings(JSON.parse(data) as AppSettings);
    } catch {
      return this.getDefaultSettingsData();
    }
  }

  private clearLegacyStorage(): void {
    this.legacyStorage.delete(RECORD_KEY);
    this.legacyStorage.delete(TAG_KEY);
    this.legacyStorage.delete(STATS_KEY);
    this.legacyStorage.delete(SETTINGS_KEY);
  }

  private queryCount(tableName: string): number {
    if (!this.store) {
      return 0;
    }

    const resultSet = this.store.querySqlSync(`SELECT COUNT(*) FROM ${tableName}`);
    let count = 0;
    if (resultSet.goToFirstRow()) {
      count = Number(resultSet.getLong(0));
    }
    resultSet.close();
    return count;
  }

  private persistLegacyValue(key: string, value: string): void {
    AppStorage.setOrCreate(key, value);
  }

  private reloadCachesFromDb(): void {
    this.recordsCache = this.loadRecordsFromDb();
    this.tagsCache = this.loadTagsFromDb();
    this.statsCache = this.loadStatsFromDb();
    this.settingsCache = this.loadSettingsFromDb();
  }

  private loadRecordsFromDb(): Record[] {
    if (!this.store) {
      return this.readLegacyRecords();
    }
    const resultSet = this.store.querySqlSync(`SELECT id, content, tagId, createdAt, date, color FROM ${TABLE_RECORDS} ORDER BY createdAt DESC`);
    const records: Record[] = [];
    if (resultSet.goToFirstRow()) {
      do {
        records.push({
          id: resultSet.getString(0),
          content: resultSet.getString(1),
          tagId: resultSet.getString(2),
          createdAt: resultSet.getLong(3),
          date: resultSet.getString(4),
          color: resultSet.getString(5)
        });
      } while (resultSet.goToNextRow());
    }
    resultSet.close();
    return records;
  }

  private loadTagsFromDb(): Tag[] {
    if (!this.store) {
      return this.readLegacyTags();
    }
    const resultSet = this.store.querySqlSync(`SELECT id, name, color, icon FROM ${TABLE_TAGS} ORDER BY name ASC`);
    const tags: Tag[] = [];
    if (resultSet.goToFirstRow()) {
      do {
        tags.push({
          id: resultSet.getString(0),
          name: resultSet.getString(1),
          color: resultSet.getString(2),
          icon: resultSet.getString(3)
        });
      } while (resultSet.goToNextRow());
    }
    resultSet.close();
    return tags;
  }

  private loadStatsFromDb(): StatsData {
    if (!this.store) {
      return this.readLegacyStats();
    }
    const value = this.loadMetaValue(STATS_KEY);
    if (value === '') {
      return this.getDefaultStatsData();
    }
    try {
      return JSON.parse(value) as StatsData;
    } catch {
      return this.getDefaultStatsData();
    }
  }

  private loadSettingsFromDb(): AppSettings {
    if (!this.store) {
      return this.readLegacySettings();
    }
    const value = this.loadMetaValue(SETTINGS_KEY);
    if (value === '') {
      return this.getDefaultSettingsData();
    }
    try {
      return this.normalizeSettings(JSON.parse(value) as AppSettings);
    } catch {
      return this.getDefaultSettingsData();
    }
  }

  private normalizeSettings(input: AppSettings): AppSettings {
    const fallback = this.getDefaultSettingsData();
    const source = input ?? fallback;
    const rawReminderTimes = Array.isArray(source.reminderTimes) ? source.reminderTimes : [];
    const normalizedReminderTimes: ReminderItem[] = rawReminderTimes
      .filter((item: ReminderItem) => typeof item?.time === 'string' && item.time.trim() !== '')
      .map((item: ReminderItem, index: number) => ({
        id: item.id && item.id.trim() !== '' ? item.id : `reminder-${index}-${item.time}`,
        title: item.title && item.title.trim() !== '' ? item.title : '每日提醒',
        time: item.time
      }));

    if (normalizedReminderTimes.length === 0) {
      normalizedReminderTimes.push({
        id: 'reminder-default-21-00',
        title: '每日提醒',
        time: source.reminderTime && source.reminderTime.trim() !== '' ? source.reminderTime : fallback.reminderTime
      });
    }

    const dedupedReminderTimes: ReminderItem[] = [];
    normalizedReminderTimes.forEach((item: ReminderItem) => {
      if (!dedupedReminderTimes.some((existing: ReminderItem) => existing.time === item.time)) {
        dedupedReminderTimes.push(item);
      }
    });

    return {
      dailyReminder: typeof source.dailyReminder === 'boolean' ? source.dailyReminder : fallback.dailyReminder,
      reminderTime: dedupedReminderTimes[0].time,
      reminderTimes: dedupedReminderTimes,
      hapticFeedback: typeof source.hapticFeedback === 'boolean' ? source.hapticFeedback : fallback.hapticFeedback,
      darkMode: typeof source.darkMode === 'boolean' ? source.darkMode : fallback.darkMode,
      themeColor: source.themeColor ?? fallback.themeColor,
      iCloudSync: typeof source.iCloudSync === 'boolean' ? source.iCloudSync : fallback.iCloudSync,
      faceIdLock: typeof source.faceIdLock === 'boolean' ? source.faceIdLock : fallback.faceIdLock,
      anonymousAnalytics: typeof source.anonymousAnalytics === 'boolean' ? source.anonymousAnalytics : fallback.anonymousAnalytics
    };
  }

  private loadMetaValue(key: string): string {
    if (!this.store) {
      return '';
    }
    const resultSet = this.store.querySqlSync(`SELECT value FROM ${TABLE_META} WHERE key = ?`, [key]);
    let value = '';
    if (resultSet.goToFirstRow()) {
      value = resultSet.getString(0);
    }
    resultSet.close();
    return value;
  }

  private saveMetaValue(key: string, value: string): void {
    if (!this.store) {
      this.persistLegacyValue(key, value);
      return;
    }
    this.store.insertSync(TABLE_META, { key: key, value: value }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  private insertRecordRow(record: Record): void {
    if (!this.store) {
      return;
    }
    this.store.insertSync(TABLE_RECORDS, {
      id: record.id,
      content: record.content,
      tagId: record.tagId,
      createdAt: record.createdAt,
      date: record.date,
      color: record.color
    }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  private insertTagRow(tag: Tag): void {
    if (!this.store) {
      return;
    }
    this.store.insertSync(TABLE_TAGS, {
      id: tag.id,
      name: tag.name,
      color: tag.color,
      icon: tag.icon
    }, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  private replaceAllRecords(records: Record[]): void {
    if (!this.store) {
      return;
    }
    this.store.executeSync(`DELETE FROM ${TABLE_RECORDS}`);
    records.forEach((record: Record) => {
      this.insertRecordRow(record);
    });
  }

  private replaceAllTags(tags: Tag[]): void {
    if (!this.store) {
      return;
    }
    this.store.executeSync(`DELETE FROM ${TABLE_TAGS}`);
    tags.forEach((tag: Tag) => {
      this.insertTagRow(tag);
    });
  }

  private normalizeTags(inputTags: Tag[]): Tag[] {
    const mergedById: Map<string, Tag> = new Map();
    const canonicalIdByName: Map<string, string> = new Map();
    this.getBootstrapTags().forEach((tag: Tag) => {
      mergedById.set(tag.id, tag);
      canonicalIdByName.set(tag.name, tag.id);
    });
    inputTags.forEach((tag: Tag) => {
      if (tag.name.trim() === '') {
        return;
      }
      if (mergedById.has(tag.id)) {
        const previous = mergedById.get(tag.id)!;
        canonicalIdByName.delete(previous.name);
        mergedById.set(tag.id, {
          id: tag.id,
          name: tag.name,
          color: tag.color,
          icon: tag.icon
        });
        canonicalIdByName.set(tag.name, tag.id);
        return;
      }

      const existingId = canonicalIdByName.get(tag.name);
      if (!existingId) {
        mergedById.set(tag.id, {
          id: tag.id,
          name: tag.name,
          color: tag.color,
          icon: tag.icon
        });
        canonicalIdByName.set(tag.name, tag.id);
        return;
      }

      const existing = mergedById.get(existingId)!;
      if (existing.id.startsWith('preset-') && !tag.id.startsWith('preset-')) {
        mergedById.set(existing.id, {
          id: existing.id,
          name: tag.name,
          color: tag.color,
          icon: tag.icon
        });
      }
    });
    return Array.from(mergedById.values());
  }

  private buildCanonicalTagIdMap(originalTags: Tag[], normalizedTags: Tag[]): Map<string, string> {
    const canonicalByName: Map<string, string> = new Map();
    normalizedTags.forEach((tag: Tag) => {
      canonicalByName.set(tag.name, tag.id);
    });
    const map: Map<string, string> = new Map();
    originalTags.forEach((tag: Tag) => {
      const canonicalId = canonicalByName.get(tag.name);
      if (canonicalId) {
        map.set(tag.id, canonicalId);
      }
    });
    normalizedTags.forEach((tag: Tag) => {
      map.set(tag.id, tag.id);
    });
    return map;
  }

  private normalizeRecords(inputRecords: Record[], tagIdMap: Map<string, string>, availableTags: Tag[]): Record[] {
    const colorByTagId: Map<string, string> = new Map();
    availableTags.forEach((tag: Tag) => {
      colorByTagId.set(tag.id, tag.color);
    });

    const deduped: Map<string, Record> = new Map();
    inputRecords.forEach((record: Record) => {
      if (record.id.trim() === '') {
        return;
      }
      const canonicalTagId = tagIdMap.get(record.tagId) ?? availableTags[0].id;
      deduped.set(record.id, {
        id: record.id,
        content: record.content,
        tagId: canonicalTagId,
        createdAt: record.createdAt,
        date: record.date,
        color: colorByTagId.get(canonicalTagId) ?? record.color
      });
    });
    return Array.from(deduped.values());
  }

  private getBootstrapTags(): Tag[] {
    const tags: Tag[] = [
      { id: 'preset-reading', name: '阅读', color: '#7FB7FF', icon: 'book' },
      { id: 'preset-sport', name: '运动', color: '#FFB182', icon: 'run' },
      { id: 'preset-think', name: '思考', color: '#C7B0FF', icon: 'bulb' },
      { id: 'preset-write', name: '写作', color: '#A7D8FF', icon: 'pen' },
      { id: 'preset-study', name: '学习', color: '#8BE4CC', icon: 'study' },
      { id: 'preset-meditate', name: '冥想', color: '#63D5C2', icon: 'meditate' },
      { id: 'preset-drink', name: '饮水', color: '#7EDDB7', icon: 'water' }
    ];
    return tags;
  }

  private getDefaultStatsData(): StatsData {
    return {
      totalDays: 0,
      completedDays: 0,
      currentStreak: 0,
      longestStreak: 0,
      completionRate: 0
    };
  }

  private getDefaultSettingsData(): AppSettings {
    return {
      dailyReminder: false,
      reminderTime: '21:00',
      reminderTimes: [
        { id: 'reminder-default-21-00', title: '每日提醒', time: '21:00' }
      ],
      hapticFeedback: false,
      darkMode: false,
      themeColor: '#63D5C2',
      iCloudSync: true,
      faceIdLock: false,
      anonymousAnalytics: true
    };
  }

  getRecords(): Record[] {
    return [...this.recordsCache];
  }

  saveRecords(records: Record[]): void {
    const normalized = this.normalizeRecords(records, this.buildCanonicalTagIdMap(this.tagsCache, this.tagsCache), this.tagsCache.length > 0 ? this.tagsCache : this.getBootstrapTags());
    if (!this.store) {
      this.recordsCache = normalized;
      this.persistLegacyValue(RECORD_KEY, JSON.stringify(normalized));
      return;
    }
    this.replaceAllRecords(normalized);
    this.recordsCache = this.loadRecordsFromDb();
  }

  addRecord(record: Record): void {
    if (!this.store) {
      const nextRecords = this.getRecords();
      nextRecords.unshift(record);
      this.saveRecords(nextRecords);
      EventBus.emit(Events.RECORD_ADDED);
      return;
    }

    const availableTags = this.tagsCache.length > 0 ? this.tagsCache : this.getBootstrapTags();
    const fallbackTagId = availableTags[0]?.id ?? record.tagId;
    const normalizedRecord: Record = {
      ...record,
      tagId: availableTags.find((tag: Tag) => tag.id === record.tagId)?.id ?? fallbackTagId,
      color: availableTags.find((tag: Tag) => tag.id === record.tagId)?.color ?? record.color
    };
    this.insertRecordRow(normalizedRecord);
    this.recordsCache = this.loadRecordsFromDb();
    EventBus.emit(Events.RECORD_ADDED);
  }

  getRecordById(id: string): Record | null {
    return this.recordsCache.find((record: Record) => record.id === id) ?? null;
  }

  updateRecord(nextRecord: Record): void {
    const nextRecords = this.getRecords().map((record: Record) => {
      if (record.id === nextRecord.id) {
        return nextRecord;
      }
      return record;
    });
    this.saveRecords(nextRecords);
    EventBus.emit(Events.RECORD_UPDATED);
  }

  deleteRecord(id: string): void {
    const nextRecords = this.getRecords().filter((record: Record) => record.id !== id);
    this.saveRecords(nextRecords);
    EventBus.emit(Events.RECORD_DELETED);
  }

  getRecordsByDate(date: string): Record[] {
    return this.recordsCache.filter((record: Record) => record.date === date);
  }

  getRecordsByTag(tagId: string): Record[] {
    return this.recordsCache.filter((record: Record) => record.tagId === tagId);
  }

  getTags(): Tag[] {
    return [...this.tagsCache];
  }

  saveTags(tags: Tag[]): void {
    const normalized = this.normalizeTags(tags);
    const tagIdMap = this.buildCanonicalTagIdMap(tags, normalized);
    const nextRecords = this.normalizeRecords(this.recordsCache, tagIdMap, normalized);
    if (!this.store) {
      this.tagsCache = normalized;
      this.recordsCache = nextRecords;
      this.persistLegacyValue(TAG_KEY, JSON.stringify(normalized));
      this.persistLegacyValue(RECORD_KEY, JSON.stringify(nextRecords));
      EventBus.emit(Events.TAG_UPDATED);
      return;
    }
    this.replaceAllTags(normalized);
    this.replaceAllRecords(nextRecords);
    this.tagsCache = this.loadTagsFromDb();
    this.recordsCache = this.loadRecordsFromDb();
    EventBus.emit(Events.TAG_UPDATED);
  }

  getStats(): StatsData {
    return this.statsCache;
  }

  saveStats(stats: StatsData): void {
    this.statsCache = stats;
    this.saveMetaValue(STATS_KEY, JSON.stringify(stats));
  }

  getSettings(): AppSettings {
    return this.settingsCache;
  }

  saveSettings(settings: AppSettings): void {
    const normalized = this.normalizeSettings(settings);
    this.settingsCache = normalized;
    this.saveMetaValue(SETTINGS_KEY, JSON.stringify(normalized));
    EventBus.emit(Events.SETTINGS_CHANGED);
  }

  clearAll(): void {
    const defaultTags = this.getBootstrapTags();
    const defaultStats = this.getDefaultStatsData();
    const defaultSettings = this.getDefaultSettingsData();

    if (!this.store) {
      this.recordsCache = [];
      this.tagsCache = defaultTags;
      this.statsCache = defaultStats;
      this.settingsCache = defaultSettings;
      this.persistLegacyValue(RECORD_KEY, JSON.stringify([]));
      this.persistLegacyValue(TAG_KEY, JSON.stringify(defaultTags));
      this.persistLegacyValue(STATS_KEY, JSON.stringify(defaultStats));
      this.persistLegacyValue(SETTINGS_KEY, JSON.stringify(defaultSettings));
    } else {
      this.replaceAllRecords([]);
      this.replaceAllTags(defaultTags);
      this.saveMetaValue(STATS_KEY, JSON.stringify(defaultStats));
      this.saveMetaValue(SETTINGS_KEY, JSON.stringify(defaultSettings));
      this.recordsCache = [];
      this.tagsCache = defaultTags;
      this.statsCache = defaultStats;
      this.settingsCache = defaultSettings;
    }

    AppStorage.setOrCreate('drawerTotalRecords', 0);
    AppStorage.setOrCreate('drawerStreakDays', 0);
    AppStorage.setOrCreate('drawerRecentStatus', '未开始');
    EventBus.emit(Events.SETTINGS_CHANGED);
    EventBus.emit(Events.RECORD_DELETED);
    EventBus.emit(Events.TAG_UPDATED);
  }
}

export const storageService = new StorageService();
