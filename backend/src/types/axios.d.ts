declare module 'axios' {
  interface AxiosRequestConfig {
    timeout?: number;
    headers?: Record<string, string>;
    validateStatus?: ((status: number) => boolean) | null;
    maxRedirects?: number;
  }

  interface AxiosResponse<T = unknown> {
    data: T;
    status: number;
  }

  interface AxiosError {
    response?: { data?: { description?: string }; status?: number };
    message: string;
    code?: string;
  }

  function get<T = unknown>(url: string, config?: AxiosRequestConfig): Promise<AxiosResponse<T>>;
  function post<T = unknown>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<AxiosResponse<T>>;
  function isAxiosError(err: unknown): err is AxiosError;

  const axios: {
    get: typeof get;
    post: typeof post;
    isAxiosError: typeof isAxiosError;
  };

  export default axios;
}
