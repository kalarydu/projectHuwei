/**
 * 作物图像分类结果数据模型
 * 对应后端 ClassificationResult 实体
 */
export interface CropMonitorModel {
  id: number;
  greenhouseKey: string;    // cotton / sunflower / strawberry
  greenhouseName: string;   // 棉花大棚 / 向日葵大棚 / 草莓大棚
  objectName: string;       // MinIO 对象路径
  fileName: string;         // 文件名
  classId: number;          // 分类类别 ID (0-13)
  classNameCn: string;      // 中文类别名
  classNameEn: string;      // 英文类别名
  confidence: number;       // 置信度 [0, 1]
  elapsedMs: number;        // 推理耗时（毫秒）
  createTime: string;       // 分类时间
}

/**
 * 大棚卡片配置
 */
export interface GreenhouseCardConfig {
  key: string;
  name: string;
  icon: string;
  color: string;       // 卡片头部背景色
  barColor: string;    // 置信度进度条颜色
}

/** 三大棚卡片配置 */
export const GREENHOUSE_CARDS: GreenhouseCardConfig[] = [
  { key: 'strawberry', name: '草莓大棚', icon: '🍓', color: '#ff6b6b', barColor: '#ee5a24' },
  { key: 'sunflower',  name: '向日葵大棚', icon: '🌻', color: '#f9ca24', barColor: '#f0932b' },
  { key: 'cotton',     name: '棉花大棚', icon: '🌿', color: '#a4b0be', barColor: '#747d8c' },
];

/** 轮询间隔（毫秒） */
export const POLL_INTERVAL_MS: number = 5000;
