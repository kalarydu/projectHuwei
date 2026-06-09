import { promptAction } from '@kit.ArkUI';

export class ToastUtil {
  static show(msg: string) {
    promptAction.showToast({ message: msg, duration: 2000, bottom: '50%' });
  }
}
