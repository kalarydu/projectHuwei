import { GreenhousePage } from '../views/GreenhousePage';
import { SensorDataPage } from '../views/SensorDataPage';
import { DevicePage } from '../views/DevicePage';
import { AlertLogPage } from '../views/AlertLogPage';
import { Constants } from '../common/Constants';
import { webview } from '@kit.ArkWeb';

const MOBILE_CSS: string =
  `(function(){
    var s=document.createElement('style');
    s.textContent='@media screen and (max-width:768px){'+
      'body{flex-direction:column;}'+
      '.sidebar{width:100%;padding:8px;display:flex;flex-wrap:wrap;gap:4px;}'+
      '.sidebar .logo{width:100%;padding:0 0 8px;font-size:15px;border:none;margin:0;}'+
      '.sidebar .logo span{font-size:20px;}'+
      '.sidebar .tab{display:inline-block;width:auto;padding:6px 10px;font-size:12px;border-radius:4px;}'+
      '.main{padding:10px;}'+
      '.page-title{font-size:17px;margin-bottom:12px;}'+
      '.card{padding:10px;margin-bottom:12px;}'+
      '.card h3{font-size:14px;margin-bottom:10px;}'+
      '.form-row{flex-direction:column;gap:6px;}'+
      '.form-row label{min-width:auto;font-size:12px;}'+
      '.form-row input,.form-row select{font-size:16px;padding:8px;}'+
      'table{font-size:11px;display:block;overflow-x:auto;}'+
      'th,td{padding:6px 4px;white-space:nowrap;}'+
      '.btn{padding:6px 10px;font-size:12px;}'+
      '.btn-sm{padding:2px 8px;font-size:11px;}'+
      '.modal{min-width:auto!important;max-width:95vw!important;padding:16px;}'+
      '.chat-bubble{max-width:90%;font-size:13px;}'+
      '.chart-container{height:200px;}'+
      'canvas{max-width:100%;}'+
    '}';
    document.head.appendChild(s);
  })()`;

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  private tabsController: TabsController = new TabsController();
  private webController: webview.WebviewController = new webview.WebviewController();

  build() {
    Tabs({ index: 0, barPosition: BarPosition.End, controller: this.tabsController }) {
      TabContent() {
        Web({ src: Constants.WEB_URL, controller: this.webController })
          .width('100%')
          .height('100%')
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .zoomAccess(true)
          .overviewModeAccess(true)
          .textZoomRatio(100)
          .onPageEnd(() => {
            this.webController.runJavaScript(MOBILE_CSS);
          })
      }
      .tabBar('数据看板')

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
    }
    .width('100%')
    .height('100%')
    .barHeight(56)
    .onChange((index: number) => { this.currentTab = index; })
  }
}
