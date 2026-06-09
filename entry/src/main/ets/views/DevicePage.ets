import { HttpUtil } from '../common/HttpUtil';
import { ToastUtil } from '../common/ToastUtil';
import { PageResult } from '../common/PageResult';
import { DeviceModel } from '../model/DeviceModel';
import { Constants } from '../common/Constants';
import { PaginationBar } from '../components/PaginationBar';
import { MqttUtil } from '../common/MqttUtil';

interface DeviceFormData {
  greenhouseId: number;
  deviceName: string;
  deviceType: string;
  status: number;
}

interface DeviceUpdateData extends DeviceFormData {
  id: number;
}

interface DeviceCommandData {
  deviceId: number;
  deviceName: string;
  command: string;
  timestamp: string;
}

@Component
export struct DevicePage {
  @State dataList: DeviceModel[] = [];
  @State currentPage: number = 1;
  @State totalPages: number = 1;
  @State searchGid: string = '';
  @State searchType: string = '';
  // 表单
  @State formId: number = 0;
  @State formGid: string = '1';
  @State formName: string = '';
  @State formType: string = 'FAN';
  @State formStatus: number = 0;
  // MQTT 状态
  @State mqttConnected: boolean = false;
  private statusCallback: (topic: string, payload: Object) => void = () => {};

  aboutToAppear(): void {
    this.loadList(1);
    this.initMqtt();
  }

  aboutToDisappear(): void {
    MqttUtil.getInstance().unsubscribe(Constants.TOPIC_DEVICE_STATUS, this.statusCallback);
  }

  initMqtt(): void {
    this.mqttConnected = MqttUtil.getInstance().isConnected();
    this.statusCallback = (topic: string, payload: Object) => {
      const data = payload as Record<string, Object>;
      const deviceId = data.deviceId as number;
      const status = data.status as number;
      // 更新列表中对应设备的状态
      const item = this.dataList.find(d => d.id === deviceId);
      if (item) {
        item.status = status;
        ToastUtil.show(`设备 "${item.deviceName}" 已${status === 1 ? '开启' : '关闭'}`);
      }
      this.mqttConnected = true;
    };
    MqttUtil.getInstance().subscribe(Constants.TOPIC_DEVICE_STATUS, this.statusCallback);
  }

  async loadList(page: number) {
    const params = new Map<string, string | number>();
    params.set('page', page);
    params.set('size', 10);
    if (this.searchGid) params.set('greenhouseId', parseInt(this.searchGid));
    if (this.searchType) params.set('deviceType', this.searchType);
    try {
      const res = await HttpUtil.get<PageResult<DeviceModel>>('/api/device/list', params);
      if (res.code === 200 && res.data) {
        this.dataList = res.data.records;
        this.currentPage = res.data.current;
        this.totalPages = res.data.pages;
      } else { ToastUtil.show(res.message || '加载失败'); }
    } catch (e) { ToastUtil.show('网络错误'); }
  }

  async saveDevice() {
    if (!this.formName.trim()) { ToastUtil.show('请输入设备名称'); return; }
    const data: DeviceFormData = {
      greenhouseId: parseInt(this.formGid) || 1,
      deviceName: this.formName.trim(),
      deviceType: this.formType,
      status: this.formStatus
    };
    try {
      const res = this.formId > 0
        ? await HttpUtil.put<string>('/api/device', this.makeUpdateData(data))
        : await HttpUtil.post<string>('/api/device', data);
      if (res.code === 200) { ToastUtil.show(res.data as string || '操作成功'); this.resetForm(); this.loadList(1); }
      else ToastUtil.show(res.message || '操作失败');
    } catch (e) { ToastUtil.show('网络错误'); }
  }

  makeUpdateData(data: DeviceFormData): DeviceUpdateData {
    return {
      id: this.formId,
      greenhouseId: data.greenhouseId,
      deviceName: data.deviceName,
      deviceType: data.deviceType,
      status: data.status
    };
  }

  editDevice(item: DeviceModel) {
    this.formId = item.id;
    this.formGid = item.greenhouseId.toString();
    this.formName = item.deviceName;
    this.formType = item.deviceType;
    this.formStatus = item.status;
  }

  resetForm() { this.formId = 0; this.formGid = '1'; this.formName = ''; this.formType = 'FAN'; this.formStatus = 0; }

  async toggleDevice(id: number) {
    try {
      const res = await HttpUtil.put<string>(`/api/device/${id}/toggle`);
      if (res.code === 200) {
        // 同步发布 MQTT 控制指令
        const device = this.dataList.find(d => d.id === id);
        const newStatus = device ? (device.status === 1 ? 0 : 1) : 0;
        const cmdData: DeviceCommandData = {
          deviceId: id,
          deviceName: device?.deviceName ?? '',
          command: newStatus === 1 ? 'ON' : 'OFF',
          timestamp: new Date().toISOString()
        };
        MqttUtil.getInstance().publish(`greenhouse/${device?.greenhouseId ?? 1}/device/cmd`, cmdData);
        ToastUtil.show(res.data as string || '操作成功');
        this.loadList(1);
      }
      else ToastUtil.show(res.message || '操作失败');
    } catch (e) { ToastUtil.show('网络错误'); }
  }

  deleteDevice(id: number) {
    AlertDialog.show({
      message: '确定删除该设备吗？',
      buttons: [
        { value: '取消', action: () => {} },
        { value: '确定', action: async () => {
            try {
              const res = await HttpUtil.del<string>(`/api/device/${id}`);
              if (res.code === 200) { ToastUtil.show('删除成功'); this.loadList(1); }
              else ToastUtil.show(res.message || '删除失败');
            } catch (e) { ToastUtil.show('网络错误'); }
          }
        }
      ]
    });
  }

  build() {
    Scroll() {
      Column() {
        // MQTT 连接状态
        Row() {
          Text(this.mqttConnected ? '● MQTT 已连接 - 可远程控制' : '○ MQTT 未连接')
            .fontSize(12)
            .fontColor(this.mqttConnected ? '#52c41a' : '#999')
        }.width('100%').justifyContent(FlexAlign.End).margin({ bottom: 4 })

        // 表单卡片
        Column() {
          Text(this.formId > 0 ? '编辑设备' : '新增设备').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
            .border({ width: { bottom: 1 }, color: '#f0f0f0' }).padding({ bottom: 10 }).width('100%')

          TextInput({ placeholder: '大棚ID', text: this.formGid }).type(InputType.Number)
            .onChange(v => this.formGid = v).margin({ top: 10 })
          TextInput({ placeholder: '设备名称，如：风机-1号', text: this.formName })
            .onChange(v => this.formName = v).margin({ top: 8 })

          Row() {
            Text('类型：').fontSize(14).fontColor('#666')
            Select([{ value: '风机' }, { value: '水泵' }, { value: '补光灯' }, { value: '卷帘' }])
              .selected(this.getTypeIndex(this.formType))
              .onSelect((index: number) => this.formType = this.getTypeByIndex(index))
              .width(140).margin({ left: 8 })
          }.margin({ top: 8 }).alignItems(VerticalAlign.Center)

          Row() {
            Text('状态：').fontSize(14).fontColor('#666')
            Select([{ value: '关闭' }, { value: '开启' }])
              .selected(this.formStatus === 0 ? 0 : 1)
              .onSelect((index: number) => this.formStatus = index === 0 ? 0 : 1)
              .width(100).margin({ left: 8 })
          }.margin({ top: 8 }).alignItems(VerticalAlign.Center)

          Row() {
            Button('保存').backgroundColor('#1890ff').fontColor('#fff').onClick(() => this.saveDevice())
            Button('重置').backgroundColor('#f5f5f5').fontColor('#333').onClick(() => this.resetForm()).margin({ left: 10 })
          }.margin({ top: 12 })
        }
        .backgroundColor('#fff').borderRadius(8).padding(16).width('100%')

        // 列表卡片
        Column() {
          Text('设备列表').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
            .border({ width: { bottom: 1 }, color: '#f0f0f0' }).padding({ bottom: 10 }).width('100%')

          Row() {
            TextInput({ placeholder: '大棚ID', text: this.searchGid }).type(InputType.Number)
              .onChange(v => this.searchGid = v).layoutWeight(1)
            Select([{ value: '全部' }, { value: '风机' }, { value: '水泵' }, { value: '补光灯' }, { value: '卷帘' }])
              .selected(this.getSearchTypeIndex(this.searchType))
              .onSelect((index: number) => this.searchType = index === 0 ? '' : this.getTypeByIndex(index - 1))
              .width(100).margin({ left: 8 })
            Button('查询').backgroundColor('#1890ff').fontColor('#fff')
              .onClick(() => this.loadList(1)).margin({ left: 8 })
          }.margin({ top: 10 }).width('100%')

          if (this.dataList.length === 0) {
            Text('暂无数据').fontSize(14).fontColor('#999').padding(30).width('100%').textAlign(TextAlign.Center)
          } else {
            List() {
              ForEach(this.dataList, (item: DeviceModel) => {
                ListItem() {
                  Column() {
                    // 第一行：名称 + 类型标签 + 状态
                    Row() {
                      Text(item.deviceName)
                        .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#333')
                      Text(Constants.DEVICE_TYPE_MAP[item.deviceType] || item.deviceType)
                        .fontSize(11).fontColor('#1890ff').backgroundColor('#e6f7ff')
                        .borderRadius(3).padding({ left: 6, right: 6 }).margin({ left: 6 })
                      Blank()
                      Text(item.status === 1 ? '● 开启' : '○ 关闭')
                        .fontSize(12).fontColor(item.status === 1 ? '#52c41a' : '#ff4d4f')
                        .backgroundColor(item.status === 1 ? '#f6ffed' : '#fff2f0')
                        .borderRadius(3).padding({ left: 8, right: 8 })
                    }.width('100%')

                    // 第二行：大棚编号
                    Text(`大棚 #${item.greenhouseId}`)
                      .fontSize(12).fontColor('#999').margin({ top: 4 })

                    // 第三行：操作按钮
                    Row() {
                      Button(item.status === 1 ? '关闭' : '开启')
                        .fontSize(13).backgroundColor('#faad14').fontColor('#fff')
                        .onClick(() => this.toggleDevice(item.id))
                      Button('编辑')
                        .fontSize(13).backgroundColor('#1890ff').fontColor('#fff')
                        .onClick(() => this.editDevice(item)).margin({ left: 8 })
                      Button('删除')
                        .fontSize(13).backgroundColor('#ff4d4f').fontColor('#fff')
                        .onClick(() => this.deleteDevice(item.id)).margin({ left: 8 })
                    }.width('100%').margin({ top: 10 })
                  }
                  .width('100%').padding(12).backgroundColor('#fafafa').borderRadius(6)
                }.margin({ top: 6 }).border({ width: { bottom: 0.5 }, color: '#f0f0f0' })
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

  getTypeIndex(type: string): number {
    const keys = ['FAN', 'PUMP', 'LIGHT', 'CURTAIN'];
    const i = keys.indexOf(type);
    return i >= 0 ? i : 0;
  }
  getTypeByIndex(index: number): string {
    const keys = ['FAN', 'PUMP', 'LIGHT', 'CURTAIN'];
    return keys[index] || 'FAN';
  }
  getSearchTypeIndex(type: string): number {
    if (!type) return 0;
    const keys = ['FAN', 'PUMP', 'LIGHT', 'CURTAIN'];
    const i = keys.indexOf(type);
    return i >= 0 ? i + 1 : 0;
  }
}
