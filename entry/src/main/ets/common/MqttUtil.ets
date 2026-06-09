import { socket } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { Constants } from './Constants';

type MessageCallback = (topic: string, payload: Object) => void;

const DOMAIN = 0x0001;
const KEEP_ALIVE_SEC = 30;

const CONNECT_TYPE = 1;
const CONNACK_TYPE = 2;
const PUBLISH_TYPE = 3;
const SUBSCRIBE_TYPE = 8;
const SUBACK_TYPE = 9;
const PINGREQ_TYPE = 12;
const DISCONNECT_TYPE = 14;

class RemainingLengthResult {
  value: number = 0;
  bytesRead: number = 0;
}

class ParseResult {
  type: number = 0;
  flags: number = 0;
  body: Uint8Array = new Uint8Array(0);
}

class MqttAddr {
  host: string = '';
  port: number = 0;
}

interface TcpMessageData {
  message: ArrayBuffer;
  remoteInfo: socket.SocketRemoteInfo;
}

const textEncoder = new util.TextEncoder();
const textDecoder = new util.TextDecoder();

function encodeUtf8(str: string): Uint8Array {
  return textEncoder.encodeInto(str);
}

function decodeUtf8(bytes: Uint8Array): string {
  return textDecoder.decodeToString(bytes);
}

function encodeRemainingLength(length: number): Uint8Array {
  const bytes: number[] = [];
  let remaining = length;
  do {
    let byte = remaining % 128;
    remaining = Math.floor(remaining / 128);
    if (remaining > 0) {
      byte |= 0x80;
    }
    bytes.push(byte);
  } while (remaining > 0);
  return new Uint8Array(bytes);
}

function decodeRemainingLength(buf: Uint8Array, offset: number): RemainingLengthResult | null {
  let value = 0;
  let multiplier = 1;
  let bytesRead = 0;
  while (bytesRead < 4) {
    if (offset + bytesRead >= buf.length) {
      return null;
    }
    const byte = buf[offset + bytesRead];
    value += (byte & 0x7F) * multiplier;
    multiplier *= 128;
    bytesRead++;
    if ((byte & 0x80) === 0) {
      break;
    }
  }
  const result = new RemainingLengthResult();
  result.value = value;
  result.bytesRead = bytesRead;
  return result;
}

function buildPacket(type: number, flags: number, body: number[]): ArrayBuffer {
  const rl = encodeRemainingLength(body.length);
  const headerLen = 1 + rl.length;
  const totalLen = headerLen + body.length;
  const bytes = new Uint8Array(totalLen);
  bytes[0] = (type << 4) | flags;
  for (let i = 0; i < rl.length; i++) {
    bytes[1 + i] = rl[i];
  }
  for (let i = 0; i < body.length; i++) {
    bytes[headerLen + i] = body[i];
  }
  return bytes.buffer as ArrayBuffer;
}

function buildConnectPacket(clientId: string): ArrayBuffer {
  const idBytes = encodeUtf8(clientId);
  const varHeader: number[] = [
    0x00, 0x04, 0x4D, 0x51, 0x54, 0x54,
    0x04,
    0x02,
    (KEEP_ALIVE_SEC >> 8) & 0xFF, KEEP_ALIVE_SEC & 0xFF
  ];
  const payload: number[] = [(idBytes.length >> 8) & 0xFF, idBytes.length & 0xFF];
  for (let i = 0; i < idBytes.length; i++) {
    payload.push(idBytes[i]);
  }
  return buildPacket(CONNECT_TYPE, 0, varHeader.concat(payload));
}

function buildSubscribePacket(packetId: number, topic: string): ArrayBuffer {
  const topicBytes = encodeUtf8(topic);
  const varHeader: number[] = [(packetId >> 8) & 0xFF, packetId & 0xFF];
  const payload: number[] = [(topicBytes.length >> 8) & 0xFF, topicBytes.length & 0xFF];
  for (let i = 0; i < topicBytes.length; i++) {
    payload.push(topicBytes[i]);
  }
  payload.push(1);
  return buildPacket(SUBSCRIBE_TYPE, 2, varHeader.concat(payload));
}

function buildPublishPacket(topic: string, payloadStr: string): ArrayBuffer {
  const topicBytes = encodeUtf8(topic);
  const bodyBytes = encodeUtf8(payloadStr);
  const pid = Math.floor(Math.random() * 65535);
  const varHeader: number[] = [
    (topicBytes.length >> 8) & 0xFF, topicBytes.length & 0xFF
  ];
  for (let i = 0; i < topicBytes.length; i++) {
    varHeader.push(topicBytes[i]);
  }
  varHeader.push((pid >> 8) & 0xFF);
  varHeader.push(pid & 0xFF);
  const allBody: number[] = [];
  for (let i = 0; i < varHeader.length; i++) {
    allBody.push(varHeader[i]);
  }
  for (let i = 0; i < bodyBytes.length; i++) {
    allBody.push(bodyBytes[i]);
  }
  return buildPacket(PUBLISH_TYPE, 2, allBody);
}

function buildPingReqPacket(): ArrayBuffer {
  return buildPacket(PINGREQ_TYPE, 0, []);
}

function buildDisconnectPacket(): ArrayBuffer {
  return buildPacket(DISCONNECT_TYPE, 0, []);
}

export class MqttUtil {
  private static instance: MqttUtil;
  private tcp: socket.TCPSocket | null = null;
  private callbacks: Map<string, MessageCallback[]> = new Map();
  private connected: boolean = false;
  private buffer: number[] = [];
  private pingTimer: number | null = null;
  private closed: boolean = false;
  private connecting: boolean = false;
  private connackResolve: ((ok: boolean) => void) | null = null;

  static getInstance(): MqttUtil {
    if (MqttUtil.instance === null || MqttUtil.instance === undefined) {
      MqttUtil.instance = new MqttUtil();
    }
    return MqttUtil.instance;
  }

  async connect(): Promise<void> {
    if (this.connected) {
      return;
    }
    if (this.connecting) {
      return;
    }
    this.connecting = true;
    this.closed = false;
    this.buffer = [];

    try {
      // 关闭旧连接
      if (this.tcp !== null) {
        try {
          this.tcp.off('message');
          this.tcp.off('close');
          this.tcp.off('error');
          this.tcp.close();
        } catch (_) {
          // ignore
        }
        this.tcp = null;
      }

      this.tcp = socket.constructTCPSocketInstance();
      const addr = this.parseAddress(Constants.MQTT_BROKER_URL);

      const connackPromise = new Promise<boolean>((resolve: (ok: boolean) => void) => {
        this.connackResolve = resolve;
        setTimeout(() => {
          if (this.connackResolve !== null) {
            this.connackResolve = null;
            hilog.error(DOMAIN, 'mqtt', 'CONNACK timeout');
            resolve(false);
          }
        }, 10000);
      });

      this.tcp.on('message', (data: TcpMessageData) => {
        this.handleIncoming(new Uint8Array(data.message));
      });

      this.tcp.on('close', () => {
        if (this.connected) {
          hilog.warn(DOMAIN, 'mqtt', 'TCP close');
        }
        this.connected = false;
        this.connecting = false;
        this.stopPing();
        if (!this.closed) {
          setTimeout(() => {
            this.doReconnect();
          }, 5000);
        }
      });

      this.tcp.on('error', (err: Object) => {
        hilog.error(DOMAIN, 'mqtt', 'TCP error');
        this.connected = false;
        this.connecting = false;
      });

      const netAddr: socket.NetAddress = {
        address: addr.host,
        port: addr.port,
        family: 1
      };
      await this.tcp.connect({
        address: netAddr,
        timeout: 10000
      });

      hilog.info(DOMAIN, 'mqtt', 'TCP connected');

      const clientId = Constants.MQTT_CLIENT_ID_PREFIX + Date.now().toString();
      await this.tcp.send({ data: buildConnectPacket(clientId) });
      hilog.info(DOMAIN, 'mqtt', 'CONNECT sent');

      const ok = await connackPromise;
      if (!ok) {
        try { this.tcp.close(); } catch (_) {}
        this.tcp = null;
        this.connecting = false;
        throw new Error('CONNACK failed');
      }

      this.connected = true;
      this.connecting = false;
      this.startPing();
      hilog.info(DOMAIN, 'mqtt', 'MQTT ok');

      this.callbacks.forEach((_v: MessageCallback[], topic: string) => {
        this.sendSubscribe(topic);
      });
    } catch (e) {
      this.connected = false;
      this.connecting = false;
      this.connackResolve = null;
      throw new Error('MQTT connect failed');
    }
  }

  private doReconnect(): void {
    if (this.closed) {
      return;
    }
    this.connect().catch(() => {
      // 重连失败会触发close事件再重试
    });
  }

  subscribe(topic: string, callback: MessageCallback): void {
    const existing = this.callbacks.get(topic);
    if (existing === undefined) {
      this.callbacks.set(topic, [callback]);
    } else {
      existing.push(callback);
    }
    if (this.connected) {
      this.sendSubscribe(topic);
    }
  }

  private sendSubscribe(topic: string): void {
    if (this.tcp === null || !this.connected) {
      return;
    }
    const pktId = Math.floor(Math.random() * 65535);
    this.tcp.send({ data: buildSubscribePacket(pktId, topic) }).then(() => {
      hilog.info(DOMAIN, 'mqtt', 'subscribed: %{public}s', topic);
    }).catch((err: Error) => {
      hilog.error(DOMAIN, 'mqtt', 'sub fail');
    });
  }

  unsubscribe(topic: string, callback?: MessageCallback): void {
    if (callback !== undefined && callback !== null) {
      const cbs = this.callbacks.get(topic);
      if (cbs !== undefined) {
        const idx = cbs.indexOf(callback);
        if (idx >= 0) {
          cbs.splice(idx, 1);
        }
        if (cbs.length === 0) {
          this.callbacks.delete(topic);
        }
      }
    } else {
      this.callbacks.delete(topic);
    }
  }

  publish(topic: string, payload: Object): void {
    if (!this.connected || this.tcp === null) {
      this.connect().then(() => {
        this.doSend(topic, payload);
      }).catch(() => {});
      return;
    }
    this.doSend(topic, payload);
  }

  private doSend(topic: string, payload: Object): void {
    if (this.tcp === null) {
      return;
    }
    this.tcp.send({ data: buildPublishPacket(topic, JSON.stringify(payload)) })
      .catch((err: Error) => {
        hilog.error(DOMAIN, 'mqtt', 'send fail');
      });
  }

  isConnected(): boolean {
    return this.connected;
  }

  disconnect(): void {
    this.closed = true;
    this.stopPing();
    if (this.tcp !== null) {
      try {
        this.tcp.send({ data: buildDisconnectPacket() });
        this.tcp.close();
      } catch (_) {}
    }
    this.tcp = null;
    this.connected = false;
    this.connecting = false;
  }

  private parseAddress(url: string): MqttAddr {
    const match = url.match(/tcp:\/\/(.+):(\d+)/);
    const result = new MqttAddr();
    if (match !== null) {
      result.host = match[1];
      result.port = parseInt(match[2]);
    } else {
      result.host = '127.0.0.1';
      result.port = 1883;
    }
    return result;
  }

  private handleIncoming(data: Uint8Array): void {
    for (let i = 0; i < data.length; i++) {
      this.buffer.push(data[i]);
    }
    let pkt = this.tryParsePacket();
    while (pkt !== null) {
      this.dispatchPacket(pkt);
      pkt = this.tryParsePacket();
    }
  }

  private tryParsePacket(): ParseResult | null {
    if (this.buffer.length < 2) {
      return null;
    }
    const rl = decodeRemainingLength(new Uint8Array(this.buffer), 1);
    if (rl === null) {
      return null;
    }
    const headerLen = 1 + rl.bytesRead;
    const totalLen = headerLen + rl.value;
    if (this.buffer.length < totalLen) {
      return null;
    }
    const type = (this.buffer[0] >> 4) & 0x0F;
    const flags = this.buffer[0] & 0x0F;
    const body = new Uint8Array(this.buffer.slice(headerLen, totalLen));
    this.buffer.splice(0, totalLen);
    const result = new ParseResult();
    result.type = type;
    result.flags = flags;
    result.body = body;
    return result;
  }

  private dispatchPacket(pkt: ParseResult): void {
    if (pkt.type === CONNACK_TYPE) {
      const rc = pkt.body.length > 1 ? pkt.body[1] : 0xFF;
      hilog.info(DOMAIN, 'mqtt', 'CONNACK rc=%{public}d', rc);
      if (this.connackResolve !== null) {
        this.connackResolve(rc === 0);
        this.connackResolve = null;
      }
    } else if (pkt.type === PUBLISH_TYPE) {
      this.handlePublish(pkt);
    } else if (pkt.type === SUBACK_TYPE) {
      hilog.info(DOMAIN, 'mqtt', 'SUBACK');
    }
  }

  private handlePublish(pkt: ParseResult): void {
    let offset = 0;
    const topicLen = (pkt.body[offset] << 8) | pkt.body[offset + 1];
    offset += 2;
    const topic = decodeUtf8(pkt.body.slice(offset, offset + topicLen));
    offset += topicLen;
    const qos = (pkt.flags >> 1) & 0x03;
    if (qos > 0) {
      offset += 2;
    }
    const payloadStr = decodeUtf8(pkt.body.slice(offset));
    try {
      const payload = JSON.parse(payloadStr) as Object;
      hilog.info(DOMAIN, 'mqtt', 'msg %{public}s', topic);
      this.callbacks.forEach((cbs: MessageCallback[], pattern: string) => {
        if (this.topicMatches(pattern, topic)) {
          cbs.forEach((cb: MessageCallback) => cb(topic, payload));
        }
      });
    } catch (_) {
      hilog.error(DOMAIN, 'mqtt', 'bad JSON');
    }
  }

  private topicMatches(pattern: string, topic: string): boolean {
    const pp = pattern.split('/');
    const tp = topic.split('/');
    for (let i = 0; i < Math.max(pp.length, tp.length); i++) {
      if (pp[i] === '#') {
        return true;
      }
      if (pp[i] === '+') {
        continue;
      }
      if (pp[i] !== tp[i]) {
        return false;
      }
    }
    return pp.length === tp.length;
  }

  private startPing(): void {
    this.stopPing();
    this.pingTimer = setInterval(() => {
      if (this.connected && this.tcp !== null) {
        this.tcp.send({ data: buildPingReqPacket() }).catch(() => {});
      }
    }, (KEEP_ALIVE_SEC / 2) * 1000);
  }

  private stopPing(): void {
    if (this.pingTimer !== null) {
      clearInterval(this.pingTimer);
      this.pingTimer = null;
    }
  }
}
