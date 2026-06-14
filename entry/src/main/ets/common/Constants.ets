// 后端 API 基础地址，模拟器中 10.0.2.2 映射到宿主机 localhost
export class Constants {
  static readonly BASE_URL: string = 'http://10.0.2.2:8080';

  // MQTT Broker 配置 (WebSocket)
  // Web 看板地址（demo 的 web 前端，含折线图等图表）
  static readonly WEB_URL: string = 'http://10.0.2.2:8080';

  static readonly MQTT_BROKER_URL: string = 'tcp://10.0.2.2:1883';
  static readonly MQTT_CLIENT_ID_PREFIX: string = 'harmony_greenhouse_';
  static readonly MQTT_USERNAME: string = '';
  static readonly MQTT_PASSWORD: string = '';

  // MQTT 主题
  static readonly TOPIC_SENSOR = 'greenhouse/+/sensor';
  static readonly TOPIC_DEVICE_CMD = 'greenhouse/+/device/cmd';
  static readonly TOPIC_DEVICE_STATUS = 'greenhouse/+/device/status';
  static readonly TOPIC_ALERT = 'greenhouse/+/alert';

  static readonly DEVICE_TYPE_MAP: Record<string, string> = {
    'FAN': '风机',
    'LIGHT': '补光灯',
    'IRRIGATION': '灌溉机'
  };

  static readonly ALERT_TYPE_MAP: Record<string, string> = {
    'TEMP_HIGH': '温度过高',
    'TEMP_LOW': '温度过低',
    'HUMIDITY_HIGH': '湿度过高',
    'HUMIDITY_LOW': '湿度过低',
    'CO2_HIGH': 'CO2浓度过高',
    'CO2_LOW': 'CO2浓度过低',
    'LIGHT_LOW': '光照不足',
    'SOIL_MOISTURE_HIGH': '土壤湿度过高',
    'SOIL_MOISTURE_LOW': '土壤湿度过低',
    'SOIL_PH_HIGH': '土壤pH过高',
    'SOIL_PH_LOW': '土壤pH过低'
  };

  // 作物分类 API
  static readonly API_CLASSIFY = '/api/classify';
  static readonly API_CLASSIFY_MINIO = '/api/classify/minio';
  static readonly API_CLASSIFICATION_RECENT = '/api/classification/recent';
  static readonly API_CLASSIFICATION_STREAM = '/api/classification/stream';
  static readonly API_CLASSIFICATION_STATUS = '/api/classification/status';

  static readonly METRIC_LABEL_MAP: Record<string, string> = {
    'temperature': '温度 (℃)',
    'humidity': '空气湿度 (%)',
    'lightIntensity': '光照强度 (Lux)',
    'co2Concentration': 'CO2浓度 (ppm)',
    'soilMoisture': '土壤湿度 (%)',
    'soilPh': '土壤pH值'
  };
}
