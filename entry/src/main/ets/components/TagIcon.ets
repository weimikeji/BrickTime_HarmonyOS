@Component
export struct TagIcon {
  @Prop name: string = 'book';
  @Prop color: string = '#7FB7FF';
  @Prop iconSize: number = 18;

  private stroke(): number {
    return this.px(2.2);
  }

  private line(): number {
    return this.px(2.6);
  }

  private px(value: number): number {
    return this.iconSize * value / 24;
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.name === 'book') {
        this.BookIcon();
      } else if (this.name === 'run') {
        this.RunIcon();
      } else if (this.name === 'bulb') {
        this.BulbIcon();
      } else if (this.name === 'pen') {
        this.PenIcon();
      } else if (this.name === 'study') {
        this.StudyIcon();
      } else if (this.name === 'meditate') {
        this.MeditateIcon();
      } else if (this.name === 'water') {
        this.WaterIcon();
      } else if (this.name === 'music') {
        this.MusicIcon();
      } else if (this.name === 'focus') {
        this.FocusIcon();
      } else {
        this.BookIcon();
      }
    }
    .width(this.iconSize)
    .height(this.iconSize);
  }

  @Builder
  BookIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Row() {
        Column()
          .width(this.px(6.8))
          .height(this.px(10))
          .border({ width: this.stroke(), color: this.color })
          .borderRadius(2)
          .margin({ right: this.px(1.1) });

        Column()
          .width(this.px(6.8))
          .height(this.px(10))
          .border({ width: this.stroke(), color: this.color })
          .borderRadius(2)
          .margin({ left: this.px(1.1) });
      }
      .justifyContent(FlexAlign.Center);

      Column()
        .width(this.line())
        .height(this.px(10))
        .backgroundColor(this.color)
        .borderRadius(1);
    }
  }

  @Builder
  RunIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.px(3.2))
        .height(this.px(3.2))
        .backgroundColor(this.color)
        .borderRadius(this.px(1.6))
        .translate({ x: this.px(2.5), y: this.px(-6.2) });

      Column()
        .width(this.px(1.8))
        .height(this.px(6.2))
        .backgroundColor(this.color)
        .borderRadius(1)
        .rotate({ angle: 24 })
        .translate({ x: this.px(1.1), y: this.px(-0.2) });

      Column()
        .width(this.px(5.8))
        .height(this.line())
        .backgroundColor(this.color)
        .borderRadius(1)
        .rotate({ angle: -22 })
        .translate({ x: this.px(-1.4), y: this.px(-2.2) });

      Column()
        .width(this.px(5.6))
        .height(this.line())
        .backgroundColor(this.color)
        .borderRadius(1)
        .rotate({ angle: -54 })
        .translate({ x: this.px(-2.6), y: this.px(4.6) });

      Column()
        .width(this.px(6.4))
        .height(this.line())
        .backgroundColor(this.color)
        .borderRadius(1)
        .rotate({ angle: 36 })
        .translate({ x: this.px(3.2), y: this.px(5.0) });
    }
  }

  @Builder
  BulbIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.px(8.8))
        .height(this.px(8.8))
        .border({ width: this.stroke(), color: this.color })
        .borderRadius(this.px(4.4))
        .translate({ y: this.px(-2.4) });

      Column()
        .width(this.px(3.2))
        .height(this.px(3.2))
        .border({
          width: { left: this.stroke(), right: this.stroke(), bottom: this.stroke(), top: 0 },
          color: this.color
        })
        .borderRadius(1.5)
        .translate({ y: this.px(3.4) });

      Column()
        .width(this.px(4.6))
        .height(this.line())
        .backgroundColor(this.color)
        .borderRadius(1)
        .translate({ y: this.px(5.6) });
    }
  }

  @Builder
  PenIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.px(10.8))
        .height(this.px(3.4))
        .backgroundColor(this.color)
        .borderRadius(2)
        .rotate({ angle: -45 });

      Column()
        .width(this.px(2.8))
        .height(this.px(2.8))
        .backgroundColor('#FFFFFF')
        .border({ width: this.stroke(), color: this.color })
        .rotate({ angle: -45 })
        .translate({ x: this.px(4.5), y: this.px(-4.5) });

      Column()
        .width(this.px(2.1))
        .height(this.px(2.1))
        .backgroundColor(this.color)
        .borderRadius(1.2)
        .rotate({ angle: -45 })
        .translate({ x: this.px(-4.5), y: this.px(4.5) });
    }
  }

  @Builder
  StudyIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.px(11))
        .height(this.px(9))
        .border({ width: this.stroke(), color: this.color })
        .borderRadius(2)
        .translate({ y: this.px(-1.2) });

      Column()
        .width(this.px(7))
        .height(this.line())
        .backgroundColor(this.color)
        .borderRadius(1)
        .translate({ y: this.px(-1.2) });

      Column()
        .width(this.px(9))
        .height(this.line())
        .backgroundColor(this.color)
        .borderRadius(1)
        .translate({ y: this.px(6.0) });
    }
  }

  @Builder
  MeditateIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.px(3.2))
        .height(this.px(3.2))
        .backgroundColor(this.color)
        .borderRadius(this.px(1.6))
        .translate({ y: this.px(-6) });

      Column()
        .width(this.px(1.8))
        .height(this.px(5.6))
        .backgroundColor(this.color)
        .borderRadius(1)
        .translate({ y: this.px(-0.6) });

      Column()
        .width(this.px(9.5))
        .height(this.line())
        .backgroundColor(this.color)
        .borderRadius(1)
        .rotate({ angle: 18 })
        .translate({ x: this.px(-2.2), y: this.px(3.8) });

      Column()
        .width(this.px(9.5))
        .height(this.line())
        .backgroundColor(this.color)
        .borderRadius(1)
        .rotate({ angle: -18 })
        .translate({ x: this.px(2.2), y: this.px(3.8) });

      Column()
        .width(this.px(11))
        .height(this.line())
        .backgroundColor(this.color)
        .borderRadius(1)
        .translate({ y: this.px(6.4) });
    }
  }

  @Builder
  WaterIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.px(6.8))
        .height(this.px(9.2))
        .border({ width: this.stroke(), color: this.color })
        .borderRadius(4)
        .translate({ y: this.px(0.8) });

      Column()
        .width(this.px(4.8))
        .height(this.px(2.8))
        .backgroundColor(this.color)
        .opacity(0.18)
        .borderRadius(2)
        .translate({ y: this.px(2.6) });

      Column()
        .width(this.px(5.8))
        .height(this.line())
        .backgroundColor(this.color)
        .borderRadius(1)
        .translate({ y: this.px(-5.4) });
    }
  }

  @Builder
  MusicIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.px(1.8))
        .height(this.px(9.6))
        .backgroundColor(this.color)
        .borderRadius(1)
        .translate({ x: this.px(2.8), y: this.px(-0.8) });

      Column()
        .width(this.px(5.8))
        .height(this.line())
        .backgroundColor(this.color)
        .borderRadius(1)
        .rotate({ angle: -14 })
        .translate({ x: this.px(0.6), y: this.px(-5.2) });

      Column()
        .width(this.px(3.2))
        .height(this.px(3.2))
        .border({ width: this.stroke(), color: this.color })
        .borderRadius(this.px(1.6))
        .translate({ x: this.px(-2.2), y: this.px(5.0) });

      Column()
        .width(this.px(3.2))
        .height(this.px(3.2))
        .border({ width: this.stroke(), color: this.color })
        .borderRadius(this.px(1.6))
        .translate({ x: this.px(3.0), y: this.px(3.8) });
    }
  }

  @Builder
  FocusIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.px(10.2))
        .height(this.px(10.2))
        .border({ width: this.stroke(), color: this.color })
        .borderRadius(this.px(5.1));

      Column()
        .width(this.px(4.4))
        .height(this.px(4.4))
        .border({ width: this.stroke(), color: this.color })
        .borderRadius(this.px(2.2));

      Column()
        .width(this.px(1.8))
        .height(this.px(4.2))
        .backgroundColor(this.color)
        .borderRadius(1)
        .translate({ y: this.px(-7.0) });

      Column()
        .width(this.px(1.8))
        .height(this.px(4.2))
        .backgroundColor(this.color)
        .borderRadius(1)
        .translate({ y: this.px(7.0) });

      Column()
        .width(this.px(4.2))
        .height(this.line())
        .backgroundColor(this.color)
        .borderRadius(1)
        .translate({ x: this.px(-7.0) });

      Column()
        .width(this.px(4.2))
        .height(this.line())
        .backgroundColor(this.color)
        .borderRadius(1)
        .translate({ x: this.px(7.0) });
    }
  }
}
