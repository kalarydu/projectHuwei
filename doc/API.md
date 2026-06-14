# 🌱 智慧大棚管理系统 — 鸿蒙客户端 接口文档

> 客户端平台：HarmonyOS NEXT (API 23+) | 语言：ArkTS | 后端基础地址：`http://10.93.199.110:8080`

本文档描述鸿蒙客户端与后端 Spring Boot 服务之间的所有接口，包括 REST API、MQTT 主题及数据模型。

---

## 1. 后端连接配置

所有接口地址常量定义在 `entry/src/main/ets/common/Constants.ets`：

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `BASE_URL` | `http://10.93.199.110:8080` | REST API 基础地址 |
| `WEB_URL` | `http://10.93.199.110:8080` | Web 看板地址 |
| `MQTT_BROKER_URL` | `tcp://10.93.199.110:1883` | MQTT Broker TCP 地址 |

> ⚠️ 模拟器使用 `10.0.2.2` 访问宿主机，真机需使用电脑局域网 IP。

---

## 2. 统一响应格式

### ApiResponse\<T\> — 通用响应

```typescript
interface ApiResponse<T> {
  code: number;    // 200 成功，500 失败
  message: string; // 提示信息
  data: T;         // 返回数据
}
```

### PageResult\<T\> — 分页响应

```typescript
interface PageResult<T> {
  records: T[];   // 当前页数据列表
  total: number;  // 总记录数
  size: number;   // 每页条数
  current: number; // 当前页码
  pages: number;  // 总页数
}
```

---

## 3. REST API 接口列表

### 3.1 大棚管理

| 方法 | 路径 | 说明 | 调用位置 |
|------|------|------|----------|
| GET | `/api/greenhouse/list` | 分页查询大棚 | `GreenhousePage.ets` |
| POST | `/api/greenhouse` | 新增大棚 | `GreenhousePage.ets` |
| PUT | `/api/greenhouse` | 修改大棚 | `GreenhousePage.ets` |
| DELETE | `/api/greenhouse/{id}` | 删除大棚 | `GreenhousePage.ets` |

**GET /api/greenhouse/list 请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | number | 否 | 页码，默认 1 |
| size | number | 否 | 每页条数，默认 10 |
| name | string | 否 | 大棚名称模糊搜索 |

**调用示例：**

```typescript
const res = await HttpUtil.get<PageResult<GreenhouseModel>>('/api/greenhouse/list', params);
```

**POST /api/greenhouse 请求体字段：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | 是 | 大棚名称 |
| location | string | 否 | 位置描述 |
| area | number | 否 | 面积（㎡） |
| description | string | 否 | 描述 |
| status | number | 否 | 0-停用，1-运行中 |

---

### 3.2 设备管理

| 方法 | 路径 | 说明 | 调用位置 |
|------|------|------|----------|
| GET | `/api/device/list` | 分页查询设备 | `DevicePage.ets` |
| GET | `/api/device/{id}` | 查询单个设备 | `DevicePage.ets` |
| POST | `/api/device` | 新增设备 | `DevicePage.ets` |
| PUT | `/api/device` | 修改设备 | `DevicePage.ets` |
| PUT | `/api/device/{id}/toggle` | 🔌 开关设备 | `DevicePage.ets` |
| PUT | `/api/device/{id}/mode` | 🔄 切换控制模式 | `DevicePage.ets` |
| DELETE | `/api/device/{id}` | 删除设备 | `DevicePage.ets` |

**GET /api/device/list 请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | number | 否 | 页码，默认 1 |
| size | number | 否 | 每页条数，默认 10 |
| greenhouseId | number | 否 | 按大棚ID筛选 |
| deviceType | string | 否 | 按设备类型筛选 |

**设备类型枚举：**

| 类型码 | 中文名 |
|--------|--------|
| FAN | 风机 |
| LIGHT | 补光灯 |
| IRRIGATION | 灌溉机 |

---

### 3.3 传感器数据

| 方法 | 路径 | 说明 | 调用位置 |
|------|------|------|----------|
| GET | `/api/sensor-data/list` | 分页查询传感器数据 | `SensorDataPage.ets` |
| POST | `/api/sensor-data` | 新增传感器数据 | `SensorDataPage.ets` |
| DELETE | `/api/sensor-data/{id}` | 删除传感器数据 | `SensorDataPage.ets` |

**GET /api/sensor-data/list 请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | number | 否 | 页码，默认 1 |
| size | number | 否 | 每页条数，默认 10 |
| greenhouseId | number | 否 | 按大棚ID筛选 |

**POST /api/sensor-data 请求体字段：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| greenhouseId | number | 是 | 所属大棚ID |
| temperature | number | 否 | 温度（℃） |
| humidity | number | 否 | 空气湿度（%） |
| lightIntensity | number | 否 | 光照强度（Lux） |
| co2Concentration | number | 否 | CO2浓度（ppm） |
| soilMoisture | number | 否 | 土壤湿度（%） |
| soilPh | number | 否 | 土壤pH值 |
| recordTime | string | 否 | 记录时间 |

---

### 3.4 报警记录

| 方法 | 路径 | 说明 | 调用位置 |
|------|------|------|----------|
| GET | `/api/alert-log/list` | 分页查询报警 | `AlertLogPage.ets` |
| PUT | `/api/alert-log/{id}/handle` | ✅ 标记已处理 | `AlertLogPage.ets` |
| DELETE | `/api/alert-log/{id}` | 删除报警 | `AlertLogPage.ets` |

**GET /api/alert-log/list 请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | number | 否 | 页码，默认 1 |
| size | number | 否 | 每页条数，默认 10 |
| greenhouseId | number | 否 | 按大棚ID筛选 |
| alertType | string | 否 | 按报警类型筛选 |
| status | number | 否 | 0-未处理，1-已处理 |

**报警类型枚举：**

| 类型码 | 中文描述 |
|--------|----------|
| TEMP_HIGH | 温度过高 |
| TEMP_LOW | 温度过低 |
| HUMIDITY_HIGH | 湿度过高 |
| HUMIDITY_LOW | 湿度过低 |
| CO2_HIGH | CO2浓度过高 |
| CO2_LOW | CO2浓度过低 |
| LIGHT_LOW | 光照不足 |
| SOIL_MOISTURE_HIGH | 土壤湿度过高 |
| SOIL_MOISTURE_LOW | 土壤湿度过低 |
| SOIL_PH_HIGH | 土壤pH过高 |
| SOIL_PH_LOW | 土壤pH过低 |

---

### 3.5 AI 助手

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/ai/chat` | 🤖 AI 对话 |

**请求体：**

```json
{
  "message": "一号大棚最近有什么异常吗？"
}
```

> 该接口通过 WebView 内嵌的后端页面调用，非原生代码直接调用。

---

### 3.6 作物图像分类

> **数据看板集成**：WebView 内嵌的「数据看板」标签页中现已包含作物监测子页面，通过 SSE（`/api/classification/stream`）实时展示三大棚分类结果。该页面与原生「作物监测」Tab（`CropMonitorPage.ets`）功能互补——WebView 版本使用 SSE 实时推送，原生版本使用 5 秒轮询。

| 方法 | 路径 | 说明 | 调用位置 |
|------|------|------|----------|
| POST | `/api/classify` | 📤 上传图片预测 | 后端 Web 页面 |
| POST | `/api/classify/minio` | ☁️ MinIO 拉取预测 | 后端 Web 页面 |
| GET | `/api/classification/stream` | 🔗 SSE 实时推送 | 后端 Web 页面（数据看板-作物监测） |
| GET | `/api/classification/status` | 📊 SSE 连接状态 | 后端 Web 页面 |
| GET | `/api/classification/recent/{greenhouseKey}` | 🌾 按大棚查询 | `CropMonitorPage.ets` |

### GET /api/classification/recent/{greenhouseKey} — 作物监测轮询

这是鸿蒙原生代码直接调用的端点，`CropMonitorPage.ets` 每 5 秒轮询一次。

**路径参数：**

| 参数 | 说明 |
|------|------|
| greenhouseKey | 大棚标识：`strawberry` / `sunflower` / `cotton` |

**请求参数：**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| limit | number | 10 | 返回条数 |

**调用示例：**

```typescript
const res = await HttpUtil.get<CropMonitorModel[]>(
  '/api/classification/recent/' + card.key,
  new Map([['limit', 1]])
);
```

**响应数据字段：**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 主键 |
| greenhouseKey | string | 大棚标识 |
| greenhouseName | string | 大棚中文名 |
| objectName | string | MinIO 对象路径 |
| fileName | string | 文件名 |
| classId | number | 分类类别 ID（0-13） |
| classNameCn | string | 中文类别名 |
| classNameEn | string | 英文类别名 |
| confidence | number | 置信度 [0, 1] |
| elapsedMs | number | 推理耗时（毫秒） |
| createTime | string | 分类时间 |

**置信度颜色映射：**

| 置信度 | 颜色 |
|--------|------|
| ≥ 80% | 🟢 绿色 |
| 50%–80% | 🟡 黄色 |
| < 50% | 🔴 红色 |

---

## 4. MQTT 接口

### 4.1 连接配置

MQTT 客户端基于 TCP Socket 自实现 MQTT 3.1.1 协议，位于 `MqttUtil.ets`。

| 配置项 | 默认值 |
|--------|--------|
| Broker 地址 | `tcp://10.93.199.110:1883` |
| Client ID 前缀 | `harmony_greenhouse_` |
| 心跳间隔 | 15 秒（KEEP_ALIVE=30s） |
| 断线重连 | 5 秒后自动重连 |
| QoS | 0 |

### 4.2 订阅主题

| 主题 Pattern | 用途 | 消费页面 |
|-------------|------|----------|
| `greenhouse/+/sensor` | 传感器实时数据推送 | `SensorDataPage.ets` |
| `greenhouse/+/device/status` | 设备状态变更通知 | `DevicePage.ets` |
| `greenhouse/+/alert` | 报警实时推送 | `AlertLogPage.ets` |

### 4.3 发布主题

| 主题 Pattern | 用途 | 发布场景 |
|-------------|------|----------|
| `greenhouse/+/device/cmd` | 设备控制指令 | 用户在 DevicePage 点击开关 |

**发布示例（JSON）：**

```json
{
  "motor": "ON"
}
```

### 4.4 数据流

#### MQTT 实时推送流程

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

#### 设备远程控制流程

```
用户在 DevicePage 点击"开启/关闭"
  → HttpUtil.put('/api/device/{id}/toggle')
  → 后端更新数据库状态
  → 后端 MqttSendUtil 通过华为云 IoTDA API 下发 MQTT 指令
  → 真实设备收到指令执行动作
  → 设备状态变更 → MQTT 通知 → DevicePage 更新
```

---

## 5. 数据模型

### 5.1 GreenhouseModel（大棚）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 主键 |
| name | string | 大棚名称 |
| location | string | 位置 |
| area | number | 面积（㎡） |
| description | string | 描述 |
| status | number | 状态：0-停用，1-运行中 |
| createTime | string | 创建时间 |

### 5.2 DeviceModel（设备）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 主键 |
| greenhouseId | number | 所属大棚 ID |
| deviceName | string | 设备名称 |
| deviceType | string | FAN / LIGHT / IRRIGATION |
| status | number | 0-关闭，1-开启 |
| mode | string | AUTO-自动控制 / MANUAL-手动控制 |
| createTime | string | 创建时间 |

### 5.3 SensorDataModel（传感器数据）

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

### 5.4 AlertLogModel（报警记录）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 主键（MQTT 推送时为 0） |
| greenhouseId | number | 所属大棚 ID |
| alertType | string | 报警类型码 |
| message | string | 报警内容 |
| status | number | 0-未处理，1-已处理 |
| createTime | string | 报警时间 |
| handleTime | string | 处理时间 |

### 5.5 CropMonitorModel（作物分类结果）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | number | 主键 |
| greenhouseKey | string | 大棚标识：cotton / sunflower / strawberry |
| greenhouseName | string | 大棚中文名 |
| objectName | string | MinIO 对象路径 |
| fileName | string | 文件名 |
| classId | number | 分类类别 ID（0-13） |
| classNameCn | string | 中文类别名 |
| classNameEn | string | 英文类别名 |
| confidence | number | 置信度 [0, 1] |
| elapsedMs | number | 推理耗时（毫秒） |
| createTime | string | 分类时间 |

---

## 6. HTTP 工具类 API

客户端 HTTP 请求统一通过 `HttpUtil.ets` 单例工具类发起：

```typescript
class HttpUtil {
  static get<T>(path: string, params?: Map<string, Object>): Promise<ApiResponse<T>>;
  static post<T>(path: string, body?: Object): Promise<ApiResponse<T>>;
  static put<T>(path: string, body?: Object): Promise<ApiResponse<T>>;
  static del<T>(path: string): Promise<ApiResponse<T>>;
}
```

**特性：**
- 所有方法自动拼接 `BASE_URL` 前缀
- 10 秒请求超时
- 自动 JSON 序列化/反序列化
- 统一返回 `ApiResponse<T>` 格式

---

## 7. MQTT 工具类 API

MQTT 客户端通过 `MqttUtil.ets` 单例管理：

```typescript
class MqttUtil {
  static getInstance(): MqttUtil;
  connect(): Promise<void>;
  subscribe(topic: string, callback: (topic: string, payload: string) => void): void;
  unsubscribe(topic: string, callback?: Function): void;
  publish(topic: string, payload: string): void;
  isConnected(): boolean;
  disconnect(): void;
}
```
