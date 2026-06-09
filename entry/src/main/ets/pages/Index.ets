import { GreenhousePage } from '../views/GreenhousePage';
import { SensorDataPage } from '../views/SensorDataPage';
import { DevicePage } from '../views/DevicePage';
import { AlertLogPage } from '../views/AlertLogPage';
import { Constants } from '../common/Constants';
import { webview } from '@kit.ArkWeb';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  private tabsController: TabsController = new TabsController();

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
      TabContent() {
        GreenhousePage()
      }
      .tabBar('大棚管理')

      TabContent() {
        SensorDataPage()
      }
      .tabBar('传感器数据')

      TabContent() {
        DevicePage()
      }
      .tabBar('设备管理')

      TabContent() {
        AlertLogPage()
      }
      .tabBar('报警记录')

      TabContent() {
        Web({ src: Constants.WEB_URL, controller: new webview.WebviewController() })
          .width('100%')
          .height('100%')
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .zoomAccess(true)
      }
      .tabBar('数据看板')
    }
    .width('100%')
    .height('100%')
    .barHeight(56)
    .onChange((index: number) => { this.currentTab = index; })
  }
}
