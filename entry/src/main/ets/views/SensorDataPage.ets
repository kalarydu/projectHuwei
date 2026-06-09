import { HttpUtil } from '../common/HttpUtil';
import { ToastUtil } from '../common/ToastUtil';
import { PageResult } from '../common/PageResult';
import { SensorDataModel } from '../model/SensorDataModel';
import { PaginationBar } from '../components/PaginationBar';
import { MqttUtil } from '../common/MqttUtil';
import { Constants } from '../common/Constants';

interface SensorDataFormData {
  greenhouseId: number;
  temperature: number;
  humidity: number;
  lightIntensity: number;
  co2Concentration: number;
  soilMoisture: number;
  recordTime: string;
}

interface MqttSensorPayload {
  greenhouseId: number;
  temperature: number;
  humidity: number;
  lightIntensity: number;
  co2Concentration: number;
  soilMoisture: number;
  recordTime: string;
}

@Component
export struct SensorDataPage {
  @State dataList: SensorDataModel[] = [];
  @State currentPage: number = 1;
  @State totalPages: number = 1;
  @State searchGid: string = '';
  // 表单
  @State formGid: string = '1';
  @State formTemp: string = '25.0';
  @State formHumidity: string = '65.0';
  @State formLight: string = '30000';
  @State formCo2: string = '420';
  @State formSoil: string = '55.0';
  // MQTT 状态
  @State mqttConnected: boolean = false;
  private mqttCallback: (topic: string, payload: Object) => void = () => {};

  aboutToAppear(): void {
    this.loadList(1);
    this.initMqtt();
  }

  aboutToDisappear(): void {
    MqttUtil.getInstance().unsubscribe(Constants.TOPIC_SENSOR, this.mqttCallback);
  }

  initMqtt(): void {
    this.mqttConnected = MqttUtil.getInstance().isConnected();
    this.mqttCallback = (topic: string, payload: Object) => {
      const data = payload as MqttSensorPayload;
      // 去重：检查是否已有相同时间和大棚ID的数据
      const exists = this.dataList.some((item: SensorDataModel): boolean => {
        return item.greenhouseId === data.greenhouseId &&
          item.temperature === data.temperature &&
          item.humidity === data.humidity &&
          item.lightIntensity === data.lightIntensity &&
          item.co2Concentration === data.co2Concentration &&
          item.soilMoisture === data.soilMoisture &&
          item.recordTime === data.recordTime;
      });
      if (exists) {
        return;
      }
      const sensor: SensorDataModel = {
        id: 0,
        greenhouseId: data.greenhouseId,
        temperature: data.temperature,
        humidity: data.humidity,
        lightIntensity: data.lightIntensity,
        co2Concentration: data.co2Concentration,
        soilMoisture: data.soilMoisture,
        recordTime: data.recordTime
      };
      this.dataList = [sensor, ...this.dataList];
      this.mqttConnected = true;
    };
    MqttUtil.getInstance().subscribe(Constants.TOPIC_SENSOR, this.mqttCallback);
  }

  async loadList(page: number) {
    const params = new Map<string, string | number>();
    params.set('page', page);
    params.set('size', 10);
    if (this.searchGid) params.set('greenhouseId', parseInt(this.searchGid));
    try {
      const res = await HttpUtil.get<PageResult<SensorDataModel>>('/api/sensor-data/list', params);
      if (res.code === 200 && res.data) {
        this.dataList = res.data.records;
        this.currentPage = res.data.current;
        this.totalPages = res.data.pages;
      } else { ToastUtil.show(res.message || '加载失败'); }
    } catch (e) { ToastUtil.show('网络错误'); }
  }

  async saveSensorData() {
    const data: SensorDataFormData = {
      greenhouseId: parseInt(this.formGid) || 1,
      temperature: parseFloat(this.formTemp) || 0,
      humidity: parseFloat(this.formHumidity) || 0,
      lightIntensity: parseFloat(this.formLight) || 0,
      co2Concentration: parseFloat(this.formCo2) || 0,
      soilMoisture: parseFloat(this.formSoil) || 0,
      recordTime: new Date().toISOString().replace('Z', '')
    };
    try {
      const res = await HttpUtil.post<string>('/api/sensor-data', data);
      if (res.code === 200) {
        ToastUtil.show('新增成功');
        this.loadList(1);
      } else ToastUtil.show(res.message || '新增失败');
    } catch (e) { ToastUtil.show('网络错误'); }
  }

  deleteSensor(id: number) {
    AlertDialog.show({
      message: '确定删除该条数据吗？',
      buttons: [
        { value: '取消', action: () => {} },
        { value: '确定', action: async () => {
            try {
              const res = await HttpUtil.del<string>(`/api/sensor-data/${id}`);
              if (res.code === 200) { ToastUtil.show('删除成功'); this.loadList(1); }
              else ToastUtil.show(res.message || '删除失败');
            } catch (e) { ToastUtil.show('网络错误'); }
          }
        }
      ]
    });
  }

  formatTime(t: string): string { return t ? t.replace('T', ' ').substring(0, 19) : '-'; }

  build() {
    Scroll() {
      Column() {
        // MQTT 连接状态
        Row() {
          Text(this.mqttConnected ? '● MQTT 已连接 - 实时接收中' : '○ MQTT 未连接')
            .fontSize(12)
            .fontColor(this.mqttConnected ? '#52c41a' : '#999')
        }.width('100%').justifyContent(FlexAlign.End).margin({ bottom: 4 })

        // 表单
        Column() {
          Text('新增传感器数据').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
            .border({ width: { bottom: 1 }, color: '#f0f0f0' }).padding({ bottom: 10 }).width('100%')
          Row() {
            TextInput({ placeholder: '大棚ID', text: this.formGid }).type(InputType.Number)
              .onChange(v => this.formGid = v).layoutWeight(1)
            TextInput({ placeholder: '温度(℃)', text: this.formTemp }).type(InputType.Number)
              .onChange(v => this.formTemp = v).layoutWeight(1).margin({ left: 8 })
            TextInput({ placeholder: '湿度(%)', text: this.formHumidity }).type(InputType.Number)
              .onChange(v => this.formHumidity = v).layoutWeight(1).margin({ left: 8 })
          }.margin({ top: 10 }).width('100%')
          Row() {
            TextInput({ placeholder: '光照(Lux)', text: this.formLight }).type(InputType.Number)
              .onChange(v => this.formLight = v).layoutWeight(1)
            TextInput({ placeholder: 'CO2(ppm)', text: this.formCo2 }).type(InputType.Number)
              .onChange(v => this.formCo2 = v).layoutWeight(1).margin({ left: 8 })
            TextInput({ placeholder: '土壤湿度(%)', text: this.formSoil }).type(InputType.Number)
              .onChange(v => this.formSoil = v).layoutWeight(1).margin({ left: 8 })
          }.margin({ top: 8 }).width('100%')
          Button('新增').backgroundColor('#1890ff').fontColor('#fff')
            .onClick(() => this.saveSensorData()).margin({ top: 12 })
        }
        .backgroundColor('#fff').borderRadius(8).padding(16).width('100%')

        // 列表
        Column() {
          Text('传感器数据列表').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
            .border({ width: { bottom: 1 }, color: '#f0f0f0' }).padding({ bottom: 10 }).width('100%')
          Row() {
            TextInput({ placeholder: '大棚ID筛选', text: this.searchGid }).type(InputType.Number)
              .onChange(v => this.searchGid = v).layoutWeight(1)
            Button('查询').backgroundColor('#1890ff').fontColor('#fff')
              .onClick(() => this.loadList(1)).margin({ left: 10 })
          }.margin({ top: 10 }).width('100%')

          Scroll() {
            Column() {
              Row() {
                Text('来源').width(50).fontSize(12).fontColor('#666').fontWeight(FontWeight.Bold)
                Text('温度').width(65).fontSize(12).fontColor('#666').fontWeight(FontWeight.Bold)
                Text('湿度').width(65).fontSize(12).fontColor('#666').fontWeight(FontWeight.Bold)
                Text('光照').width(65).fontSize(12).fontColor('#666').fontWeight(FontWeight.Bold)
                Text('CO2').width(65).fontSize(12).fontColor('#666').fontWeight(FontWeight.Bold)
                Text('土壤').width(65).fontSize(12).fontColor('#666').fontWeight(FontWeight.Bold)
                Text('时间').width(130).fontSize(12).fontColor('#666').fontWeight(FontWeight.Bold)
                Text('操作').width(60).fontSize(12).fontColor('#666').fontWeight(FontWeight.Bold)
              }
              .backgroundColor('#fafafa').padding(8).borderRadius(4).width(565)

              if (this.dataList.length === 0) {
                Text('暂无数据').fontSize(14).fontColor('#999').padding(30).width(565).textAlign(TextAlign.Center)
              } else {
                List() {
                  ForEach(this.dataList, (item: SensorDataModel) => {
                    ListItem() {
                      Row() {
                        Text(item.id === 0 ? 'MQTT' : 'HTTP').fontSize(10)
                          .fontColor(item.id === 0 ? '#52c41a' : '#1890ff')
                          .backgroundColor(item.id === 0 ? '#f6ffed' : '#e6f7ff')
                          .borderRadius(3).padding({ left: 4, right: 4 }).width(50)
                        Text(`${item.temperature}℃`).fontSize(13).fontColor('#333').width(65)
                        Text(`${item.humidity}%`).fontSize(13).fontColor('#333').width(65)
                        Text(`${item.lightIntensity}`).fontSize(13).fontColor('#333').width(65)
                        Text(`${item.co2Concentration}`).fontSize(13).fontColor('#333').width(65)
                        Text(`${item.soilMoisture}%`).fontSize(13).fontColor('#333').width(65)
                        Column() {
                          Text(this.formatTime(item.recordTime)).fontSize(11).fontColor('#999')
                          Text(`大棚 #${item.greenhouseId}`).fontSize(11).fontColor('#999')
                        }.width(130).alignItems(HorizontalAlign.Start)
                        Button('删除').fontSize(11).backgroundColor('#ff4d4f').fontColor('#fff')
                          .onClick(() => this.deleteSensor(item.id)).width(60)
                      }
                      .width(565).padding(8).alignItems(VerticalAlign.Center)
                    }.border({ width: { bottom: 0.5 }, color: '#f0f0f0' })
                  })
                }.width(565).margin({ top: 4 })
              }
            }
          }
          .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Auto).width('100%').margin({ top: 10 })

          PaginationBar({ current: this.currentPage, total: this.totalPages, onPageChange: (p: number) => { this.loadList(p); } })
        }
        .backgroundColor('#fff').borderRadius(8).padding(16).width('100%').margin({ top: 16 })
      }
      .padding(16).width('100%')
    }
    .backgroundColor('#f0f2f5').width('100%').height('100%')
  }
}
