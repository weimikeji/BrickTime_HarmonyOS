import { storageService } from '../services/StorageService';

const DEFAULT_THEME_COLOR = '#63D5C2';

export class ThemeUtils {
  static getThemeColor(): string {
    const color = storageService.getSettings().themeColor;
    return this.normalizeHex(color);
  }

  static withAlpha(color: string, alphaHex: string): string {
    const normalized = this.normalizeHex(color);
    return `#${alphaHex}${normalized.slice(1)}`;
  }

  static getTintColor(color: string, alphaHex: string = '14'): string {
    return this.withAlpha(color, alphaHex);
  }

  private static normalizeHex(color: string): string {
    if (typeof color !== 'string') {
      return DEFAULT_THEME_COLOR;
    }
    const trimmed = color.trim().toUpperCase();
    if (/^#[0-9A-F]{6}$/.test(trimmed)) {
      return trimmed;
    }
    return DEFAULT_THEME_COLOR;
  }
}
