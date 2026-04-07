import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { AppNavigationBar } from '../components/AppNavigationBar';

interface WebViewRouteParams {
  title?: string;
  url?: string;
}

@Entry
@Component
export struct WebViewPage {
  private readonly pageBackground: string = '#F7F8FB';
  private readonly surfaceColor: string = '#FFFFFF';
  private readonly titleColor: string = '#3B3D45';
  private readonly dismissFocusId: string = 'webViewDismissFocus';
  private webController: webview.WebviewController = new webview.WebviewController();

  @State pageTitle: string = '网页内容';
  @State pageUrl: string = 'https://example.com';

  aboutToAppear() {
    try {
      const params = router.getParams() as WebViewRouteParams;
      if (params?.title && params.title.trim() !== '') {
        this.pageTitle = params.title;
      }
      if (params?.url && params.url.trim() !== '') {
        this.pageUrl = params.url;
      }
    } catch {
    }
  }

  private dismissKeyboard() {
    focusControl.requestFocus(this.dismissFocusId);
  }

  build() {
    Stack() {
      Column() {
        AppNavigationBar({
          title: this.pageTitle,
          titleColor: this.titleColor,
          surfaceColor: this.surfaceColor
        });

        Column() {
          Web({ src: this.pageUrl, controller: this.webController })
            .width('100%')
            .layoutWeight(1);
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 12, right: 12 });
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.pageBackground)
      .onClick(() => {
        this.dismissKeyboard();
      });

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

}
