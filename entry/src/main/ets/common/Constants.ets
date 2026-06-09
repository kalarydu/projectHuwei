// 后端 API 基础地址，模拟器中 10.0.2.2 映射到宿主机 localhost
export class Constants {
  static readonly BASE_URL: string = 'http://10.0.2.2:8080';

  // MQTT Broker 配置 (WebSocket)
  static readonly MQTT_BROKER_URL: string = 'tcp://10.190.156.163:1883';
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
    'PUMP': '水泵',
    'LIGHT': '补光灯',
    'CURTAIN': '卷帘'
  };

  static readonly ALERT_TYPE_MAP: Record<string, string> = {
    'TEMP_HIGH': '温度过高',
    'TEMP_LOW': '温度过低',
    'HUMIDITY_HIGH': '湿度过高',
    'HUMIDITY_LOW': '湿度过低',
    'CO2_HIGH': 'CO2过高',
    'LIGHT_LOW': '光照不足'
  };
}
