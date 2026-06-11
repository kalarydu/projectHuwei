import { HttpUtil } from '../common/HttpUtil';
import { CropMonitorModel, GreenhouseCardConfig, GREENHOUSE_CARDS, POLL_INTERVAL_MS } from '../model/CropMonitorModel';

/**
 * 作物生长监测页面
 * 三大棚实时分类结果展示，定时轮询后端 API
 */
@Component
export struct CropMonitorPage {
  /** 每个大棚的最新分类结果 */
  @State cropData: Record<string, CropMonitorModel | null> = {
    'strawberry': null,
    'sunflower': null,
    'cotton': null
  };
  /** 连接状态 */
  @State connected: boolean = false;
  /** 上次更新时间 */
  @State lastUpdate: string = '';
  private timer: number = -1;

  aboutToAppear(): void {
    this.pollAll();
    this.timer = setInterval(() => { this.pollAll(); }, POLL_INTERVAL_MS);
  }

  aboutToDisappear(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  /** 轮询三大棚最新结果 */
  async pollAll() {
    try {
      for (const card of GREENHOUSE_CARDS) {
        const res = await HttpUtil.get<CropMonitorModel[]>(
          '/api/classification/recent/' + card.key, new Map([['limit', 1]]));
        if (res.code === 200 && res.data && res.data.length > 0) {
          this.cropData[card.key] = res.data[0];
        }
      }
      this.connected = true;
      this.lastUpdate = new Date().toLocaleTimeString();
    } catch (e) {
      this.connected = false;
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('🌾 作物生长监测')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .layoutWeight(1)
        Row() {
          Circle({ width: 8, height: 8 })
            .fill(this.connected ? '#52c41a' : '#ff4d4f')
          Text(this.connected ? '已连接' : '连接断开')
            .fontSize(12)
            .fontColor('#888')
            .margin({ left: 4 })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 4 })

      // 更新时间
      if (this.lastUpdate) {
        Text('上次更新: ' + this.lastUpdate)
          .fontSize(11)
          .fontColor('#bbb')
          .padding({ left: 16, bottom: 8 })
      }

      // 三大棚卡片
      Scroll() {
        Column({ space: 12 }) {
          ForEach(GREENHOUSE_CARDS, (card: GreenhouseCardConfig) => {
            this.buildCropCard(card);
          }, (card: GreenhouseCardConfig) => card.key)
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 20 })
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }

  @Builder
  buildCropCard(card: GreenhouseCardConfig) {
    Column() {
      // 卡片头部
      Row() {
        Text(card.icon)
          .fontSize(28)
        Text(card.name)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#fff')
          .margin({ left: 8 })
      }
      .width('100%')
      .padding(14)
      .borderRadius({ topLeft: 12, topRight: 12 })
      .backgroundColor(card.color)

      // 卡片主体
      Column() {
        if (this.cropData[card.key]) {
          // 最新分类文件名
          Text('📷 ' + this.cropData[card.key]!.fileName)
            .fontSize(12)
            .fontColor('#999')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .margin({ bottom: 8 })

          // 生长阶段
          Text(this.cropData[card.key]!.classNameCn)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ bottom: 6 })

          // 置信度
          Row() {
            Text('置信度 ')
              .fontSize(13)
              .fontColor('#888')
            Text((this.cropData[card.key]!.confidence * 100).toFixed(1) + '%')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.confColor(this.cropData[card.key]!.confidence))
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 8 })

          // 进度条
          Row() {
            Row()
              .width((this.cropData[card.key]!.confidence * 100).toFixed(0) + '%')
              .height(8)
              .borderRadius(4)
              .backgroundColor(card.barColor)
            Row()
              .layoutWeight(1)
              .height(8)
              .borderRadius(4)
              .backgroundColor('#f0f0f0')
          }
          .width('100%')
          .height(8)
          .borderRadius(4)
          .backgroundColor('#f0f0f0')
          .margin({ bottom: 6 })

          // 耗时
          Text('推理耗时: ' + this.cropData[card.key]!.elapsedMs + 'ms')
            .fontSize(11)
            .fontColor('#bbb')

        } else {
          // 暂无数据
          Column() {
            Text('⏳')
              .fontSize(36)
              .margin({ bottom: 6 })
              .opacity(0.4)
            Text('等待数据...')
              .fontSize(14)
              .fontColor('#bbb')
          }
          .width('100%')
          .padding({ top: 24, bottom: 24 })
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .padding(14)
      .borderRadius({ bottomLeft: 12, bottomRight: 12 })
      .backgroundColor('#fff')
    }
    .width('100%')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#10000000', offsetY: 2 })
  }

  /** 置信度颜色 */
  confColor(conf: number): string {
    if (conf >= 0.8) return '#52c41a';
    if (conf >= 0.5) return '#faad14';
    return '#ff4d4f';
  }
}
