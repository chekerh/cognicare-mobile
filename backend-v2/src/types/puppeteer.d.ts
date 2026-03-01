declare module "puppeteer" {
  interface LaunchOptions {
    headless?: boolean | "new";
    args?: string[];
    defaultViewport?: { width: number; height: number } | null;
    executablePath?: string;
    timeout?: number;
  }

  interface Page {
    goto(
      url: string,
      options?: { waitUntil?: string | string[]; timeout?: number },
    ): Promise<any>;
    click(selector: string, options?: any): Promise<void>;
    type(
      selector: string,
      text: string,
      options?: { delay?: number },
    ): Promise<void>;
    waitForSelector(
      selector: string,
      options?: { timeout?: number; visible?: boolean },
    ): Promise<any>;
    waitForNavigation(options?: {
      waitUntil?: string | string[];
      timeout?: number;
    }): Promise<any>;
    $(selector: string): Promise<any>;
    $$(selector: string): Promise<any[]>;
    evaluate<T>(fn: (...args: any[]) => T, ...args: any[]): Promise<T>;
    url(): string;
    content(): Promise<string>;
    screenshot(options?: any): Promise<Buffer>;
    close(): Promise<void>;
    setDefaultNavigationTimeout(timeout: number): void;
    setDefaultTimeout(timeout: number): void;
    setViewport(viewport: { width: number; height: number }): Promise<void>;
    setUserAgent(userAgent: string): Promise<void>;
    select(selector: string, ...values: string[]): Promise<string[]>;
  }

  interface Browser {
    newPage(): Promise<Page>;
    close(): Promise<void>;
    pages(): Promise<Page[]>;
  }

  function launch(options?: LaunchOptions): Promise<Browser>;
}
