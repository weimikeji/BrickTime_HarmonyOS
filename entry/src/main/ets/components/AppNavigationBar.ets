import { RouterManager } from '../router/RouterManager';

@Component
export struct AppNavigationBar {
  @Prop title: string = '';
  @Prop titleColor: string = '#3B3D45';
  @Prop surfaceColor: string = '#FFFFFF';
  @Prop horizontalInset: number = 12;
  @Prop topInset: number = 10;
  @Prop bottomInset: number = 18;
  @Prop rightText: string = '';
  @Prop rightTextColor: string = '#FFFFFF';
  @Prop rightBackgroundColor: string = '#00FFFFFF';
  @Prop onBack?: () => void;
  @Prop onRightTap?: () => void;

  build() {
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
        if (this.onBack) {
          this.onBack();
          return;
        }
        RouterManager.goBack();
      });

      Text(this.title)
        .layoutWeight(1)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor)
        .textAlign(TextAlign.Center)
        .margin({ left: 8 });

      if (this.rightText !== '') {
        Button() {
          Text(this.rightText)
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.rightTextColor);
        }
        .width(28)
        .height(28)
        .backgroundColor(this.rightBackgroundColor)
        .borderRadius(14)
        .onClick(() => {
          if (this.onRightTap) {
            this.onRightTap();
          }
        });
      } else {
        Column()
          .width(28)
          .height(28);
      }
    }
    .width('100%')
    .padding({
      left: this.horizontalInset,
      right: this.horizontalInset,
      top: this.topInset,
      bottom: this.bottomInset
    });
  }
}
