import { HttpUtil } from '../common/HttpUtil';
import { ToastUtil } from '../common/ToastUtil';
import { PageResult } from '../common/PageResult';
import { GreenhouseModel } from '../model/GreenhouseModel';
import { PaginationBar } from '../components/PaginationBar';

interface GreenhouseFormData {
  name: string;
  location: string;
  area: number;
  description: string;
  status: number;
}

interface GreenhouseUpdateData extends GreenhouseFormData {
  id: number;
}

@Component
export struct GreenhousePage {
  @State dataList: GreenhouseModel[] = [];
  @State currentPage: number = 1;
  @State totalPages: number = 1;
  @State searchName: string = '';
  // 表单
  @State formId: number = 0;
  @State formName: string = '';
  @State formLocation: string = '';
  @State formArea: string = '200';
  @State formDesc: string = '';
  @State formStatus: number = 1;

  aboutToAppear(): void {
    this.loadList(1);
  }

  async loadList(page: number) {
    const params = new Map<string, string | number>();
    params.set('page', page);
    params.set('size', 10);
    if (this.searchName) params.set('name', this.searchName);
    try {
      const res = await HttpUtil.get<PageResult<GreenhouseModel>>('/api/greenhouse/list', params);
      if (res.code === 200 && res.data) {
        this.dataList = res.data.records;
        this.currentPage = res.data.current;
        this.totalPages = res.data.pages;
      } else {
        ToastUtil.show(res.message || '加载失败');
      }
    } catch (e) {
      ToastUtil.show('网络错误：' + JSON.stringify(e));
    }
  }

  async saveGreenhouse() {
    if (!this.formName.trim()) { ToastUtil.show('请输入大棚名称'); return; }
    const data: GreenhouseFormData = {
      name: this.formName.trim(),
      location: this.formLocation.trim(),
      area: parseFloat(this.formArea) || 0,
      description: this.formDesc.trim(),
      status: this.formStatus
    };
    try {
      const res = this.formId > 0
        ? await HttpUtil.put<string>('/api/greenhouse', this.makeUpdateData(data))
        : await HttpUtil.post<string>('/api/greenhouse', data);
      if (res.code === 200) {
        ToastUtil.show(res.data as string || '操作成功');
        this.resetForm();
        this.loadList(1);
      } else {
        ToastUtil.show(res.message || '操作失败');
      }
    } catch (e) {
      ToastUtil.show('网络错误');
    }
  }

  makeUpdateData(data: GreenhouseFormData): GreenhouseUpdateData {
    return {
      id: this.formId,
      name: data.name,
      location: data.location,
      area: data.area,
      description: data.description,
      status: data.status
    };
  }

  editGreenhouse(item: GreenhouseModel) {
    this.formId = item.id;
    this.formName = item.name;
    this.formLocation = item.location;
    this.formArea = item.area.toString();
    this.formDesc = item.description || '';
    this.formStatus = item.status;
  }

  resetForm() {
    this.formId = 0;
    this.formName = '';
    this.formLocation = '';
    this.formArea = '200';
    this.formDesc = '';
    this.formStatus = 1;
  }

  deleteGreenhouse(id: number) {
    AlertDialog.show({
      message: '确定删除该大棚吗？',
      buttons: [
        { value: '取消', action: () => {} },
        {
          value: '确定',
          action: async () => {
            try {
              const res = await HttpUtil.del<string>(`/api/greenhouse/${id}`);
              if (res.code === 200) { ToastUtil.show('删除成功'); this.loadList(1); }
              else ToastUtil.show(res.message || '删除失败');
            } catch (e) { ToastUtil.show('网络错误'); }
          }
        }
      ]
    });
  }

  formatTime(t: string): string {
    if (!t) return '-';
    return t.replace('T', ' ').substring(0, 19);
  }

  build() {
    Scroll() {
      Column() {
        // 表单卡片
        Column() {
          Text(this.formId > 0 ? '编辑大棚' : '新增大棚')
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
            .border({ width: { bottom: 1 }, color: '#f0f0f0' })
            .padding({ bottom: 10 }).width('100%')

          TextInput({ placeholder: '名称，如：一号大棚', text: this.formName })
            .onChange(v => this.formName = v).margin({ top: 10 })
          TextInput({ placeholder: '位置，如：A区-东侧', text: this.formLocation })
            .onChange(v => this.formLocation = v).margin({ top: 8 })
          TextInput({ placeholder: '面积(㎡)', text: this.formArea })
            .type(InputType.Number).onChange(v => this.formArea = v).margin({ top: 8 })
          TextInput({ placeholder: '描述，如：番茄种植大棚', text: this.formDesc })
            .onChange(v => this.formDesc = v).margin({ top: 8 })

          Row() {
            Text('状态：').fontSize(14).fontColor('#666')
            Select([{ value: '运行中' }, { value: '停用' }])
              .selected(this.formStatus === 1 ? 0 : 1)
              .onSelect((index: number) => this.formStatus = index === 0 ? 1 : 0)
              .width(120).margin({ left: 8 })
          }.margin({ top: 8 }).alignItems(VerticalAlign.Center)

          Row() {
            Button('保存').backgroundColor('#1890ff').fontColor('#fff').onClick(() => this.saveGreenhouse())
            Button('重置').backgroundColor('#f5f5f5').fontColor('#333').onClick(() => this.resetForm()).margin({ left: 10 })
          }.margin({ top: 12 })
        }
        .backgroundColor('#fff').borderRadius(8).padding(16).width('100%')

        // 列表卡片
        Column() {
          Text('大棚列表').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
            .border({ width: { bottom: 1 }, color: '#f0f0f0' })
            .padding({ bottom: 10 }).width('100%')

          Row() {
            TextInput({ placeholder: '输入大棚名称', text: this.searchName })
              .onChange(v => this.searchName = v).layoutWeight(1)
            Button('查询').backgroundColor('#1890ff').fontColor('#fff')
              .onClick(() => this.loadList(1)).margin({ left: 10 })
          }.margin({ top: 10 }).width('100%')

          // 表头
          Scroll() {
            Column() {
              Row() {
                Text('名称').width(100).fontSize(12).fontColor('#666').fontWeight(FontWeight.Bold)
                Text('位置').width(100).fontSize(12).fontColor('#666').fontWeight(FontWeight.Bold)
                Text('面积').width(60).fontSize(12).fontColor('#666').fontWeight(FontWeight.Bold)
                Text('状态').width(60).fontSize(12).fontColor('#666').fontWeight(FontWeight.Bold)
                Text('操作').width(120).fontSize(12).fontColor('#666').fontWeight(FontWeight.Bold)
              }
              .backgroundColor('#fafafa').padding(8).borderRadius(4).width(440)

              if (this.dataList.length === 0) {
                Text('暂无数据').fontSize(14).fontColor('#999').padding(30).width(440).textAlign(TextAlign.Center)
              } else {
                List() {
                  ForEach(this.dataList, (item: GreenhouseModel, index: number) => {
                    ListItem() {
                      Row() {
                        Column() {
                          Text(item.name).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#333')
                          Text(item.description || '无描述').fontSize(11).fontColor('#999').maxLines(1)
                        }.width(100).alignItems(HorizontalAlign.Start)

                        Text(item.location || '-').fontSize(13).fontColor('#666').width(100)
                        Text(`${item.area}`).fontSize(13).fontColor('#666').width(60)
                        Text(item.status === 1 ? '运行中' : '停用')
                          .fontSize(11).fontColor(item.status === 1 ? '#52c41a' : '#ff4d4f')
                          .backgroundColor(item.status === 1 ? '#f6ffed' : '#fff2f0')
                          .borderRadius(3).padding({ left: 6, right: 6 }).width(60)

                        Row() {
                          Button('编辑').fontSize(12).backgroundColor('#1890ff').fontColor('#fff')
                            .onClick(() => this.editGreenhouse(item))
                          Button('删除').fontSize(12).backgroundColor('#ff4d4f').fontColor('#fff')
                            .onClick(() => this.deleteGreenhouse(item.id)).margin({ left: 6 })
                        }.width(120)
                      }
                      .width(440).padding(8).alignItems(VerticalAlign.Center)
                    }.border({ width: { bottom: 0.5 }, color: '#f0f0f0' })
                  })
                }
                .width(440).margin({ top: 4 })
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
