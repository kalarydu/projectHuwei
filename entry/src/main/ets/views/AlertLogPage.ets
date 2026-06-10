import { HttpUtil } from '../common/HttpUtil';
import { ToastUtil } from '../common/ToastUtil';
import { PageResult } from '../common/PageResult';
import { AlertLogModel } from '../model/AlertLogModel';
import { Constants } from '../common/Constants';
import { PaginationBar } from '../components/PaginationBar';
import { MqttUtil } from '../common/MqttUtil';
import { promptAction } from '@kit.ArkUI';

interface MqttAlertPayload {
  greenhouseId: number;
  alertType: string;
  message: string;
  createTime: string;
}

@Component
export struct AlertLogPage {
  @Prop @Watch('onRefreshKeyChange') refreshKey: number = 0;
  @State dataList: AlertLogModel[] = [];
  @State currentPage: number = 1;
  @State totalPages: number = 1;
  @State searchGid: string = '';
  @State searchStatus: string = '';
  // MQTT 状态
  @State mqttConnected: boolean = false;
  private alertCallback: (topic: string, payload: Object) => void = () => {};

  aboutToAppear(): void {
    this.loadList(1);
    this.initMqtt();
  }

  // 监听父组件传来的 refreshKey，每次切到此 tab 时刷新报警列表
  onRefreshKeyChange(): void {
    this.loadList(1);
  }

  aboutToDisappear(): void {
    MqttUtil.getInstance().unsubscribe(Constants.TOPIC_ALERT, this.alertCallback);
  }

  initMqtt(): void {
    this.mqttConnected = MqttUtil.getInstance().isConnected();
    this.alertCallback = (topic: string, payload: Object) => {
      const data = payload as MqttAlertPayload;
      const exists = this.dataList.some((item: AlertLogModel): boolean => {
        return item.greenhouseId === data.greenhouseId && item.createTime === data.createTime;
      });
      if (exists) {
        return;
      }
      const alert: AlertLogModel = {
        id: 0,
        greenhouseId: data.greenhouseId,
        alertType: data.alertType,
        message: data.message,
        status: 0,
        createTime: data.createTime,
        handleTime: ''
      };
      this.dataList = [alert, ...this.dataList];
      this.mqttConnected = true;
      promptAction.showToast({
        message: `[MQTT报警] ${Constants.ALERT_TYPE_MAP[alert.alertType] || alert.alertType}: ${alert.message}`,
        duration: 3000
      });
    };
    MqttUtil.getInstance().subscribe(Constants.TOPIC_ALERT, this.alertCallback);
  }

  async loadList(page: number) {
    const params = new Map<string, string | number>();
    params.set('page', page);
    params.set('size', 10);
    if (this.searchGid) params.set('greenhouseId', parseInt(this.searchGid));
    if (this.searchStatus !== '') params.set('status', parseInt(this.searchStatus));
    try {
      const res = await HttpUtil.get<PageResult<AlertLogModel>>('/api/alert-log/list', params);
      if (res.code === 200 && res.data) {
        this.dataList = res.data.records;
        this.currentPage = res.data.current;
        this.totalPages = res.data.pages;
      } else { ToastUtil.show(res.message || '加载失败'); }
    } catch (e) { ToastUtil.show('网络错误'); }
  }

  async handleAlert(id: number) {
    try {
      const res = await HttpUtil.put<string>(`/api/alert-log/${id}/handle`);
      if (res.code === 200) { ToastUtil.show('报警已处理'); this.loadList(1); }
      else ToastUtil.show(res.message || '处理失败');
    } catch (e) { ToastUtil.show('网络错误'); }
  }

  deleteAlert(id: number) {
    AlertDialog.show({
      message: '确定删除该报警记录吗？',
      buttons: [
        { value: '取消', action: () => {} },
        { value: '确定', action: async () => {
            try {
              const res = await HttpUtil.del<string>(`/api/alert-log/${id}`);
              if (res.code === 200) { ToastUtil.show('删除成功'); this.loadList(1); }
              else ToastUtil.show(res.message || '删除失败');
            } catch (e) { ToastUtil.show('网络错误'); }
          }
        }
      ]
    });
  }

  formatTime(t: string): string { return t ? t.replace('T', ' ').substring(0, 19) : '-'; }

  getSearchStatusIndex(status: string): number {
    if (status === '') return 0;
    return status === '0' ? 1 : 2;
  }

  build() {
    Scroll() {
      Column() {
        // MQTT 连接状态
        Row() {
          Text(this.mqttConnected ? '● MQTT 已连接 - 实时报警中' : '○ MQTT 未连接')
            .fontSize(12)
            .fontColor(this.mqttConnected ? '#52c41a' : '#999')
        }.width('100%').justifyContent(FlexAlign.End).margin({ bottom: 4 })

        // 列表
        Column() {
          Text('报警列表').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
            .border({ width: { bottom: 1 }, color: '#f0f0f0' }).padding({ bottom: 10 }).width('100%')

          Row() {
            TextInput({ placeholder: '大棚ID', text: this.searchGid }).type(InputType.Number)
              .onChange(v => this.searchGid = v).layoutWeight(1)
            Select([{ value: '全部' }, { value: '未处理' }, { value: '已处理' }])
              .selected(this.getSearchStatusIndex(this.searchStatus))
              .onSelect((index: number) => this.searchStatus = index === 0 ? '' : (index === 1 ? '0' : '1'))
              .width(100).margin({ left: 8 })
            Button('查询').backgroundColor('#1890ff').fontColor('#fff')
              .onClick(() => this.loadList(1)).margin({ left: 8 })
          }.margin({ top: 10 }).width('100%')

          if (this.dataList.length === 0) {
            Text('暂无报警记录').fontSize(14).fontColor('#999').padding(30).width('100%').textAlign(TextAlign.Center)
          } else {
            List() {
              ForEach(this.dataList, (item: AlertLogModel) => {
                ListItem() {
                  Column() {
                    Row() {
                      // 数据来源标签
                      Text(item.id === 0 ? 'MQTT' : '')
                        .fontSize(10).fontColor('#52c41a').backgroundColor('#f6ffed')
                        .borderRadius(3).padding({ left: 4, right: 4 })
                        .visibility(item.id === 0 ? Visibility.Visible : Visibility.None)
                      Text(Constants.ALERT_TYPE_MAP[item.alertType] || item.alertType)
                        .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#333')
                        .margin({ left: item.id === 0 ? 6 : 0 })
                      Text(item.status === 0 ? '未处理' : '已处理')
                        .fontSize(11).fontColor(item.status === 0 ? '#fa8c16' : '#52c41a')
                        .backgroundColor(item.status === 0 ? '#fff7e6' : '#f6ffed')
                        .borderRadius(3).padding({ left: 6, right: 6 }).margin({ left: 8 })
                      Blank()
                      Text(`大棚 #${item.greenhouseId}`).fontSize(11).fontColor('#999')
                    }.width('100%')

                    Text(item.message).fontSize(13).fontColor('#666').margin({ top: 4 }).maxLines(2)

                    Row() {
                      Text(this.formatTime(item.createTime)).fontSize(11).fontColor('#999')
                      if (item.handleTime) {
                        Text('→ ' + this.formatTime(item.handleTime)).fontSize(11).fontColor('#52c41a')
                      }
                      Blank()
                      if (item.status === 0) {
                        Button('处理').fontSize(11).backgroundColor('#52c41a').fontColor('#fff')
                          .onClick(() => this.handleAlert(item.id))
                      }
                      Button('删除').fontSize(11).backgroundColor('#ff4d4f').fontColor('#fff')
                        .onClick(() => this.deleteAlert(item.id)).margin({ left: 6 })
                    }.width('100%').margin({ top: 6 })
                  }
                  .width('100%').padding(8)
                }.border({ width: { bottom: 0.5 }, color: '#f0f0f0' })
              })
            }.width('100%').margin({ top: 4 })
          }

          PaginationBar({ current: this.currentPage, total: this.totalPages, onPageChange: (p: number) => { this.loadList(p); } })
        }
        .backgroundColor('#fff').borderRadius(8).padding(16).width('100%').margin({ top: 16 })
      }
      .padding(16).width('100%')
    }
    .backgroundColor('#f0f2f5').width('100%').height('100%')
  }
}
