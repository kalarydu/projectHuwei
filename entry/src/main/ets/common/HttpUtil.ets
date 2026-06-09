import { http } from '@kit.NetworkKit';
import { Constants } from './Constants';
import { ApiResponse } from './ApiResponse';

export class HttpUtil {
  static async get<T>(path: string, params?: Map<string, string | number>): Promise<ApiResponse<T>> {
    let url = Constants.BASE_URL + path;
    if (params && params.size > 0) {
      const parts: string[] = [];
      params.forEach((value: string | number, key: string) => {
        if (value !== '' && value !== null && value !== undefined) {
          parts.push(`${encodeURIComponent(key)}=${encodeURIComponent(value)}`);
        }
      });
      if (parts.length > 0) url += '?' + parts.join('&');
    }
    const req = http.createHttp();
    try {
      const resp = await req.request(url, { method: http.RequestMethod.GET, connectTimeout: 10000, readTimeout: 10000 });
      return JSON.parse(resp.result as string) as ApiResponse<T>;
    } finally {
      req.destroy();
    }
  }

  static async post<T>(path: string, body: Object): Promise<ApiResponse<T>> {
    const url = Constants.BASE_URL + path;
    const req = http.createHttp();
    try {
      const resp = await req.request(url, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify(body),
        connectTimeout: 10000,
        readTimeout: 10000
      });
      return JSON.parse(resp.result as string) as ApiResponse<T>;
    } finally {
      req.destroy();
    }
  }

  static async put<T>(path: string, body?: Object): Promise<ApiResponse<T>> {
    const url = Constants.BASE_URL + path;
    const req = http.createHttp();
    try {
      const resp = await req.request(url, {
        method: http.RequestMethod.PUT,
        header: { 'Content-Type': 'application/json' },
        extraData: body ? JSON.stringify(body) : undefined,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      return JSON.parse(resp.result as string) as ApiResponse<T>;
    } finally {
      req.destroy();
    }
  }

  static async del<T>(path: string): Promise<ApiResponse<T>> {
    const url = Constants.BASE_URL + path;
    const req = http.createHttp();
    try {
      const resp = await req.request(url, { method: http.RequestMethod.DELETE, connectTimeout: 10000, readTimeout: 10000 });
      return JSON.parse(resp.result as string) as ApiResponse<T>;
    } finally {
      req.destroy();
    }
  }
}
