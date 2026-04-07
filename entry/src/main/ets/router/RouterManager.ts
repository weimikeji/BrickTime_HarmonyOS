// 路由管理 - 页面跳转
import { router } from '@kit.ArkUI';

export class RouterManager {
  // 跳转到今日页面
  static goToToday() {
    router.pushUrl({ url: 'pages/TodayPage' });
  }

  // 跳转到记录页面
  static goToRecord() {
    router.pushUrl({ url: 'pages/RecordPage' });
  }

  // 跳转到成长页面
  static goToGrowth() {
    router.pushUrl({ url: 'pages/GrowthPage' });
  }

  // 跳转到详情页面
  static goToDetail(recordId: string) {
    router.pushUrl({ url: 'pages/DetailPage', params: { id: recordId } });
  }

  // 跳转到今日标签详情页面
  static goToTodayTagDetail(tagId: string) {
    router.pushUrl({ url: 'pages/TagDetailPage', params: { tagId: tagId } });
  }

  // 跳转到设置页面
  static goToSettings() {
    router.pushUrl({ url: 'pages/SettingsPage' });
  }

  // 跳转到提醒设置页面
  static goToReminderSettings() {
    router.pushUrl({ url: 'pages/ReminderSettingsPage' });
  }

  // 跳转到标签管理页面
  static goToTagManage() {
    router.pushUrl({ url: 'pages/TagManagePage' });
  }

  // 跳转到主题风格页面
  static goToThemeSettings() {
    router.pushUrl({ url: 'pages/ThemeSettingsPage' });
  }

  // 跳转到站内网页页面
  static goToWebView(title: string, url: string) {
    router.pushUrl({ url: 'pages/WebViewPage', params: { title: title, url: url } });
  }

  // 返回上一页
  static goBack() {
    router.back();
  }
}
