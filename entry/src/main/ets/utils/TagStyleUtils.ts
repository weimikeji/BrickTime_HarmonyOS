import { ThemeUtils } from './ThemeUtils';

export class TagStyleUtils {
  static getChipBackground(color: string): string {
    return ThemeUtils.getTintColor(color, '36');
  }

  static getChipBorder(color: string): string {
    return ThemeUtils.getTintColor(color, '4A');
  }

  static getChipText(color: string): string {
    return color;
  }

  static getSelectedBackground(color: string): string {
    return color;
  }

  static getSelectedText(): string {
    return '#FFFFFF';
  }
}
