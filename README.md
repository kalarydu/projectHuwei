# 🌱 智慧大棚管理系统 — 鸿蒙客户端

基于 HarmonyOS NEXT（API 23+）的智慧大棚管理 App，通过 HTTP REST API 与后端交互，MQTT 实时接收传感器数据和报警推送，支持设备远程控制。

---

## 🛠 技术栈

| 层级 | 技术 |
|------|------|
| 开发语言 | ArkTS (TypeScript 超集) |
| 运行平台 | HarmonyOS NEXT 6.1.0 (API 23+) |
| UI 框架 | ArkUI 声明式 UI |
| 网络通信 | `@kit.NetworkKit` (HTTP + TCP Socket) |
| Web 内嵌 | `@kit.ArkWeb` (WebView) |
| MQTT 协议 | 自实现 MQTT 3.1.1 客户端（TCP Socket） |

---

## 📁 项目结构

```
projectHuwei/
├── AppScope/
│   └── app.json5                       # 应用全局配置（包名、版本号）
├── entry/
│   └── src/main/
│       ├── ets/
│       │   ├── common/                  # 公共模块
│       │   │   ├── ApiResponse.ets      # 统一 API 响应接口定义
│       │   │   ├── Constants.ets        # 全局常量（URL、MQTT 主题、映射表）
│       │   │   ├── HttpUtil.ets         # HTTP 请求工具（GET/POST/PUT/DELETE）
│       │   │   ├── MqttUtil.ets         # MQTT 客户端（自实现 MQTT 3.1.1 over TCP）
│       │   │   ├── PageResult.ets       # 分页响应接口定义
│       │   │   └── ToastUtil.ets        # Toast 提示工具
│       │   ├── components/
│       │   │   └── PaginationBar.ets    # 分页栏组件
│       │   ├── entryability/
│       │   │   └── EntryAbility.ets     # 应用入口（初始化 MQTT 连接）
│       │   ├── model/                   # 数据模型
│       │   │   ├── AlertLogModel.ets    # 报警记录
│       │   │   ├── CropMonitorModel.ets # 🆕 作物分类结果
│       │   │   ├── DeviceModel.ets      # 设备
│       │   │   ├── GreenhouseModel.ets  # 大棚
│       │   │   └── SensorDataModel.ets  # 传感器数据
│       │   ├── pages/
│       │   │   └── Index.ets            # 主页面（TabBar 入口）
│       │   └── views/                   # 业务页面
│       │       ├── AlertLogPage.ets     # 报警记录页（MQTT 实时 + 列表）
│       │       ├── CropMonitorPage.ets  # 🆕 作物监测页（MinIO + YOLO 实时分类）
│       │       ├── DevicePage.ets       # 设备管理页（MQTT 状态 + 远程控制）
│       │       ├── GreenhousePage.ets   # 大棚管理页（CRUD）
│       │       └── SensorDataPage.ets   # 传感器数据页（MQTT 实时 + 录入）
│       ├── module.json5                 # 模块配置
│       └── resources/                   # 资源文件（图片、国际化字符串）
├── build-profile.json5                  # 构建配置（SDK 版本、签名）
├── hvigorfile.ts                        # 构建脚本入口
├── oh-package.json5                     # 依赖声明
└── code-linter.json5                    # 代码规范配置
```

---

## 🏗 系统架构

```
┌─────────────────────────────────────────────────┐
│               HarmonyOS App                      │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │ Web 看板  │  │ 原生页面  │  │  MQTT 客户端   │  │
│  │ (WebView)│  │ (ArkUI)  │  │  (TCP Socket)  │  │
│  │          │  │          │  │                │  │
│  │ 传感器图表│  │ 大棚 CRUD│  │  订阅：        │  │
│  │ 作物监测  │  │ 设备管理  │  │  - sensor 数据  │  │
│  │ AI 助手  │  │ 报警处理  │  │  - device 状态  │  │
│  │          │  │ 报警处理  │  │  - device 状态  │  │
│  └────┬─────┘  └────┬─────┘  │  - alert 报警   │  │
│       │             │        └───────┬────────┘  │
│       │    HTTP     │    HTTP        │ MQTT(TCP) │
└───────┼─────────────┼────────────────┼───────────┘
        │             │                │
        ▼             ▼                ▼
┌─────────────────────────────────────────────────┐
│           Spring Boot 后端 (demo)                │
│  REST API(:8080)          MQTT Broker(:1883)    │
│  /api/greenhouse          greenhouse/+/sensor   │
│  /api/device              greenhouse/+/alert    │
│  /api/sensor-data         greenhouse/+/device/* │
│  /api/alert-log                                 │
│  /api/ai/chat                                   │
└───────────────────────┬─────────────────────────┘
                        │
                        ▼
              ┌─────────────────┐
              │  华为云 IoTDA    │
              │  (真实设备接入)   │
              └─────────────────┘
```

---

## 📱 页面导航

| Tab | 页面 | 类型 | 功能 |
|-----|------|------|------|
| 📊 数据看板 | WebView 内嵌后端页面 | Web | 传感器折线图（多棚对比）+ 作物监测（SSE 实时分类）+ AI 助手对话 |
| 🌾 作物监测 | CropMonitorPage 🆕 | 原生 | 三大棚（草莓/向日葵/棉花）实时分类结果，每5秒轮询后端 |
| 🏠 大棚管理 | GreenhousePage | 原生 | 大棚的新增、编辑、删除、列表查询 |
| ⚙️ 设备管理 | DevicePage | 原生 | 设备 CRUD + 远程开关（MQTT 指令下发） |
| 🔔 报警记录 | AlertLogPage | 原生 | 报警列表（HTTP）+ MQTT 实时推送 + 处理/删除 |

> **设计原则**：Web 看板侧边栏中与原生 Tab 重复的页面（大棚管理、设备管理、报警记录）已通过 JS 注入隐藏，避免功能重复。Web 看板保留**传感器折线图**、**作物监测**（SSE 实时分类）和 **AI 助手**三个独有功能。

---

## 🚀 快速开始

### 1. 环境要求

- DevEco Studio 5.0+
- HarmonyOS SDK API 23+
- HarmonyOS NEXT 真机或模拟器
- 后端服务已启动（Spring Boot 应用，端口 8080）
- MQTT Broker 已启动（端口 1883）

### 2. 配置后端地址

打开 `entry/src/main/ets/common/Constants.ets`，修改以下配置：

```typescript
export class Constants {
  // ⚠️ 改为你电脑的局域网 IP（模拟器使用 10.0.2.2）
  static readonly BASE_URL: string = 'http://你的IP:8080';

  // Web 看板地址（通常与 BASE_URL 相同）
  static readonly WEB_URL: string = 'http://你的IP:8080';

  // MQTT Broker 地址
  static readonly MQTT_BROKER_URL: string = 'tcp://你的IP:1883';
}
```

| 配置项 | 说明 |
|--------|------|
| `BASE_URL` | 后端 REST API 基础地址 |
| `WEB_URL` | 数据看板 Web 页面地址 |
| `MQTT_BROKER_URL` | MQTT Broker TCP 地址 |

### 3. 构建运行

1. 用 DevEco Studio 打开 `projectHuwei` 目录
2. 等待依赖同步完成
3. 选择目标设备（真机或模拟器）
4. 点击 Run 或 `Ctrl+F5`

---

## 🔌 核心模块说明

### MQTT 客户端 (`MqttUtil.ets`)

自实现的 MQTT 3.1.1 协议客户端，基于 TCP Socket：

| 功能 | 说明 |
|------|------|
| 连接管理 | 自动连接、心跳保活（15s）、断线重连（5s） |
| 主题订阅 | 支持通配符 `+` 和 `#` |
| 消息发布 | QoS 0 / QoS 1 支持 |
| 生命周期 | 应用启动时连接（EntryAbility），销毁时断开 |

**订阅主题：**

| 主题 Pattern | 用途 |
|-------------|------|
| `greenhouse/+/sensor` | 传感器实时数据推送 |
| `greenhouse/+/device/status` | 设备状态变更通知 |
| `greenhouse/+/alert` | 报警实时推送 |

### HTTP 工具 (`HttpUtil.ets`)

封装了 `@kit.NetworkKit` 的 HTTP 请求，统一处理：
- GET / POST / PUT / DELETE
- 自动 JSON 序列化/反序列化
- 统一超时设置（10s）
- 返回 `ApiResponse<T>` 统一响应格式

### 数据看板 WebView

第一个 Tab 内嵌后端 Web 页面，通过 JS 注入实现：
- **去重**：隐藏 Web 侧边栏中与原生 Tab 重复的 3 个菜单项（大棚管理、设备管理、报警记录）
- **默认页**：自动跳转到传感器数据页（折线图）
- **移动适配**：注入响应式 CSS 适配手机屏幕

### 🆕 作物监测 (`CropMonitorPage.ets`)

第三个 Tab（🌾 作物监测），通过定时轮询后端 `/api/classification/recent/{key}` 接口，实时展示 MinIO + YOLO 作物分类结果：

| 大棚 | 轮询端点 | 刷新间隔 |
|------|---------|---------|
| 🍓 草莓 | `GET /api/classification/recent/strawberry?limit=1` | 5s |
| 🌻 向日葵 | `GET /api/classification/recent/sunflower?limit=1` | 5s |
| 🌿 棉花 | `GET /api/classification/recent/cotton?limit=1` | 5s |

每张卡片展示：文件名、生长阶段（大字）、置信度百分比 + 彩色进度条、推理耗时。

| 置信度 | 颜色 |
|--------|------|
| ≥ 80% | 🟢 绿色 |
| 50%–80% | 🟡 黄色 |
| < 50% | 🔴 红色 |

---

## 📊 数据模型

### GreenhouseModel（大棚）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 主键 |
| name | string | 大棚名称 |
| location | string | 位置 |
| area | number | 面积（㎡） |
| description | string | 描述 |
| status | number | 状态：0-停用，1-运行中 |
| createTime | string | 创建时间 |

### DeviceModel（设备）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 主键 |
| greenhouseId | number | 所属大棚 ID |
| deviceName | string | 设备名称 |
| deviceType | string | FAN / LIGHT / IRRIGATION |
| status | number | 0-关闭，1-开启 |
| mode | string | AUTO-自动控制 / MANUAL-手动控制 |
| createTime | string | 创建时间 |

### SensorDataModel（传感器数据）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 主键 |
| greenhouseId | number | 所属大棚 ID |
| temperature | number | 温度（℃） |
| humidity | number | 空气湿度（%） |
| lightIntensity | number | 光照强度（Lux） |
| co2Concentration | number | CO2 浓度（ppm） |
| soilMoisture | number | 土壤湿度（%） |
| soilPh | number | 土壤 pH 值 |
| recordTime | string | 采集时间 |

### AlertLogModel（报警记录）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 主键（MQTT 推送时为 0） |
| greenhouseId | number | 所属大棚 ID |
| alertType | string | 报警类型（见下方枚举） |
| message | string | 报警内容 |
| status | number | 0-未处理，1-已处理 |
| createTime | string | 报警时间 |
| handleTime | string | 处理时间 |

**报警类型枚举：**

| 类型码 | 中文描述 |
|--------|----------|
| TEMP_HIGH | 温度过高 |
| TEMP_LOW | 温度过低 |
| HUMIDITY_HIGH | 湿度过高 |
| HUMIDITY_LOW | 湿度过低 |
| CO2_HIGH | CO2 浓度过高 |
| CO2_LOW | CO2 浓度过低 |
| LIGHT_LOW | 光照不足 |
| SOIL_MOISTURE_HIGH | 土壤湿度过高 |
| SOIL_MOISTURE_LOW | 土壤湿度过低 |
| SOIL_PH_HIGH | 土壤 pH 过高 |
| SOIL_PH_LOW | 土壤 pH 过低 |

### 🆕 CropMonitorModel（作物分类结果）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 主键 |
| greenhouseKey | string | 大棚标识：cotton / sunflower / strawberry |
| greenhouseName | string | 大棚中文名 |
| objectName | string | MinIO 对象路径 |
| fileName | string | 文件名 |
| classId | number | 分类类别 ID（0-13） |
| classNameCn | string | 中文类别名（如"棉花-开花期"） |
| classNameEn | string | 英文类别名 |
| confidence | number | 置信度 [0, 1] |
| elapsedMs | number | 推理耗时（毫秒） |
| createTime | string | 分类时间 |

---

## 🔄 数据流

### MQTT 实时推送流程

```
IoT 传感器上报
  → 后端 MqttMessageListener 解析入库
  → 后端 MQTT Broker 转发到对应主题
  → HarmonyOS MqttUtil 收到消息
  → 回调各页面处理：
     ├─ SensorDataPage: 去重 → 插入列表顶部
     ├─ DevicePage: 更新设备状态 → Toast 提示
     └─ AlertLogPage: 去重 → 插入顶部 + 弹窗提醒
```

### 设备远程控制流程

```
用户在 DevicePage 点击"开启/关闭"
  → HttpUtil.put('/api/device/{id}/toggle')
  → 后端更新数据库状态
  → 后端 MqttSendUtil 通过华为云 IoTDA API 下发 MQTT 指令
  → 真实设备收到指令执行动作
  → 设备状态变更 → MQTT 通知 → DevicePage 更新
```

---

## ⚠️ 注意事项

1. **网络配置**：模拟器使用 `10.0.2.2` 访问宿主机，真机需使用电脑局域网 IP
2. **MQTT 依赖后端**：MQTT Broker 由后端 Spring Boot 应用提供，确保后端已启动
3. **WebView JS 注入**：数据看板的去重逻辑依赖页面加载完成后的 JS 执行，首次加载可能有短暂闪烁
4. **数据安全**：`Constants.ets` 中的 IP 地址为开发环境配置，生产环境应使用域名
5. **MQTT 客户端**：自实现的 MQTT 3.1.1 协议，如后端升级到 MQTT 5.0 需同步适配

---

## 📝 License

MIT
