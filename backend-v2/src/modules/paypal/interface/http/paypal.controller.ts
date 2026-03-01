import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  Res,
  BadRequestException,
} from "@nestjs/common";
import type { Response } from "express";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { Public } from "@/shared/decorators/public.decorator";
import { PaypalService } from "../../paypal.service";

@ApiTags("paypal")
@Controller("paypal")
export class PaypalController {
  constructor(private readonly paypal: PaypalService) {}

  @Post("create-order")
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({
    summary: "Create a PayPal order; returns orderId and approvalUrl",
  })
  async createOrder(@Body() body: { amount: string; currencyCode?: string }) {
    if (!this.paypal.isConfigured())
      throw new BadRequestException("PayPal is not configured");
    const amount = body.amount ?? (body as Record<string, any>)["value"];
    if (!amount || typeof amount !== "string")
      throw new BadRequestException('amount is required (e.g. "75.00")');
    const base =
      process.env.PAYPAL_RETURN_BASE ||
      process.env.BASE_URL ||
      "http://localhost:3000";
    const returnUrl = `${base.replace(/\/$/, "")}/api/v1/paypal/complete`;
    const cancelUrl = `${base.replace(/\/$/, "")}/api/v1/paypal/cancel`;
    return this.paypal.createOrder({
      amount,
      currencyCode: body.currencyCode ?? "USD",
      returnUrl,
      cancelUrl,
    });
  }

  @Get("complete")
  @Public()
  @ApiOperation({ summary: "PayPal redirects here after approval" })
  async complete(
    @Query("token") token: string | undefined,
    @Res() res: Response,
  ) {
    if (!token) {
      res.status(400).send("<html><body><p>Missing token.</p></body></html>");
      return;
    }
    try {
      const result = await this.paypal.captureOrder(token);
      const appScheme = process.env.PAYPAL_APP_SCHEME || "cognicare";
      const redirectUrl = `${appScheme}://paypal-success?orderId=${encodeURIComponent(result.id ?? token)}&status=success`;
      res.setHeader("Content-Type", "text/html; charset=utf-8");
      res.send(
        `<!DOCTYPE html><html><head><meta charset="utf-8"><meta http-equiv="refresh" content="2;url=${redirectUrl}"></head><body><p>Payment successful. Redirecting...</p></body></html>`,
      );
    } catch (e) {
      res
        .status(500)
        .send(
          `<html><body><p>Error: ${(e as Error).message}</p></body></html>`,
        );
    }
  }

  @Get("order-status")
  @ApiBearerAuth("JWT-auth")
  @ApiOperation({ summary: "Get PayPal order status" })
  async orderStatus(@Query("orderId") orderId: string | undefined) {
    if (!orderId) throw new BadRequestException("orderId is required");
    if (!this.paypal.isConfigured())
      throw new BadRequestException("PayPal is not configured");
    return this.paypal.getOrderStatus(orderId);
  }

  @Get("cancel")
  @Public()
  @ApiOperation({ summary: "PayPal redirects here if user cancels" })
  cancel(@Res() res: Response) {
    const appScheme = process.env.PAYPAL_APP_SCHEME || "cognicare";
    const redirectUrl = `${appScheme}://paypal-success?status=cancelled`;
    res.setHeader("Content-Type", "text/html; charset=utf-8");
    res.send(
      `<!DOCTYPE html><html><head><meta charset="utf-8"><meta http-equiv="refresh" content="2;url=${redirectUrl}"></head><body><p>Payment cancelled.</p></body></html>`,
    );
  }
}
