import { GreenhousePage } from '../views/GreenhousePage';
import { DevicePage } from '../views/DevicePage';
import { AlertLogPage } from '../views/AlertLogPage';
import { CropMonitorPage } from '../views/CropMonitorPage';
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
      '.crop-grid{grid-template-columns:1fr;}'+
    '}';
    document.head.appendChild(s);
  })()`;

// 隐藏 Web 看板中与原生 Tab 重复的菜单项
// 只保留 传感器数据 + AI助手；大棚/设备/报警/作物 由原生页面提供
const DEDUP_NAV_JS: string =
  `(function(){
    var tabs = document.querySelectorAll('.sidebar .tab');
    tabs.forEach(function(btn) {
      var page = btn.getAttribute('data-page');
      if (page === 'greenhouse' || page === 'device' || page === 'alert' || page === 'crops') {
        btn.style.display = 'none';
      }
    });
    // 默认打开传感器数据页（有折线图）
    var sensorTab = document.querySelector('.sidebar .tab[data-page="sensor"]');
    if (sensorTab) sensorTab.click();
  })()`;

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @State alertRefreshKey: number = 0;
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
            this.webController.runJavaScript(DEDUP_NAV_JS);
          })
      }
      .tabBar('数据看板')

      TabContent() {
        CropMonitorPage()
      }
      .tabBar('作物监测')

      TabContent() {
        GreenhousePage()
      }
      .tabBar('大棚管理')

      TabContent() {
        DevicePage()
      }
      .tabBar('设备管理')

      TabContent() {
        AlertLogPage({ refreshKey: this.alertRefreshKey })
      }
      .tabBar('报警记录')
    }
    .width('100%')
    .height('100%')
    .barHeight(56)
    .onChange((index: number) => {
      this.currentTab = index;
      if (index === 4) { this.alertRefreshKey++; }  // 切到报警记录时触发刷新
    })
  }
}
