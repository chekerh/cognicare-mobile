import { Injectable } from '@nestjs/common';

const SANDBOX = process.env.PAYPAL_SANDBOX !== 'false';
const BASE = SANDBOX
  ? 'https://api-m.sandbox.paypal.com'
  : 'https://api-m.paypal.com';

@Injectable()
export class PaypalService {
  private _accessToken: string | null = null;
  private _tokenExpiry = 0;

  private get clientId(): string {
    const id = process.env.PAYPAL_CLIENT_ID;
    if (!id) throw new Error('PAYPAL_CLIENT_ID is not set');
    return id;
  }

  private get clientSecret(): string {
    const secret = process.env.PAYPAL_CLIENT_SECRET;
    if (!secret) throw new Error('PAYPAL_CLIENT_SECRET is not set');
    return secret;
  }

  isConfigured(): boolean {
    return Boolean(
      process.env.PAYPAL_CLIENT_ID && process.env.PAYPAL_CLIENT_SECRET,
    );
  }

  private async getAccessToken(): Promise<string> {
    if (this._accessToken && Date.now() < this._tokenExpiry) {
      return this._accessToken;
    }
    const auth = Buffer.from(`${this.clientId}:${this.clientSecret}`).toString(
      'base64',
    );
    const res = await fetch(`${BASE}/v1/oauth2/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        Authorization: `Basic ${auth}`,
      },
      body: 'grant_type=client_credentials',
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`PayPal token failed: ${res.status} ${text}`);
    }
    const data = (await res.json()) as {
      access_token: string;
      expires_in: number;
    };
    this._accessToken = data.access_token;
    this._tokenExpiry = Date.now() + (data.expires_in - 60) * 1000;
    return this._accessToken;
  }

  /**
   * Create a PayPal order. Returns orderId and the URL to send the user to for approval.
   */
  async createOrder(params: {
    amount: string;
    currencyCode?: string;
    returnUrl: string;
    cancelUrl: string;
  }): Promise<{ orderId: string; approvalUrl: string }> {
    const token = await this.getAccessToken();
    const currency = params.currencyCode ?? 'USD';
    const body = {
      intent: 'CAPTURE',
      purchase_units: [
        {
          amount: {
            currency_code: currency,
            value: params.amount,
          },
        },
      ],
      application_context: {
        return_url: params.returnUrl,
        cancel_url: params.cancelUrl,
      },
    };
    const res = await fetch(`${BASE}/v2/checkout/orders`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(body),
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`PayPal create order failed: ${res.status} ${text}`);
    }
    const data = (await res.json()) as {
      id: string;
      links?: Array< { rel: string; href: string } >;
    };
    const approveLink = data.links?.find((l) => l.rel === 'approve');
    if (!approveLink?.href) {
      throw new Error('PayPal order created but no approval link');
    }
    return { orderId: data.id, approvalUrl: approveLink.href };
  }

  /**
   * Capture a previously created order after the user has approved it.
   */
  async captureOrder(orderId: string): Promise<{ status: string; id?: string }> {
    const token = await this.getAccessToken();
    const res = await fetch(
      `${BASE}/v2/checkout/orders/${orderId}/capture`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
      },
    );
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`PayPal capture failed: ${res.status} ${text}`);
    }
    const data = (await res.json()) as { status?: string; id?: string };
    return {
      status: data.status ?? 'COMPLETED',
      id: data.id ?? orderId,
    };
  }

  /**
   * Get order status (CREATED, APPROVED, COMPLETED, etc.).
   */
  async getOrderStatus(orderId: string): Promise<{ status: string }> {
    const token = await this.getAccessToken();
    const res = await fetch(`${BASE}/v2/checkout/orders/${orderId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) {
      if (res.status === 404) return { status: 'NOT_FOUND' };
      const text = await res.text();
      throw new Error(`PayPal get order failed: ${res.status} ${text}`);
    }
    const data = (await res.json()) as { status?: string };
    return { status: data.status ?? 'UNKNOWN' };
  }
}
