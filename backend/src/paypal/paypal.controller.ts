import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  Request,
  Res,
  BadRequestException,
} from '@nestjs/common';
import type { Response } from 'express';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PaypalService } from './paypal.service';

@ApiTags('paypal')
@Controller('paypal')
export class PaypalController {
  constructor(private readonly paypal: PaypalService) {}

  @Post('create-order')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Create a PayPal order; returns orderId and approvalUrl' })
  async createOrder(
    @Request() req: { user: { id: string } },
    @Body() body: { amount: string; currencyCode?: string },
  ) {
    if (!this.paypal.isConfigured()) {
      throw new BadRequestException('PayPal is not configured');
    }
    const amount = body.amount ?? body['value'];
    if (!amount || typeof amount !== 'string') {
      throw new BadRequestException('amount is required (e.g. "75.00")');
    }
    const base =
      process.env.PAYPAL_RETURN_BASE ||
      process.env.BASE_URL ||
      'http://localhost:3000';
    const returnUrl = `${base.replace(/\/$/, '')}/api/v1/paypal/complete`;
    const cancelUrl = `${base.replace(/\/$/, '')}/api/v1/paypal/cancel`;
    const { orderId, approvalUrl } = await this.paypal.createOrder({
      amount,
      currencyCode: body.currencyCode ?? 'USD',
      returnUrl,
      cancelUrl,
    });
    return { orderId, approvalUrl };
  }

  @Get('complete')
  @ApiOperation({ summary: 'PayPal redirects here after approval; we capture and redirect to app' })
  async complete(
    @Query('token') token: string | undefined,
    @Res() res: Response,
  ) {
    if (!token) {
      res.status(400).send(
        '<html><body><p>Missing token.</p><script>setTimeout(() => window.close(), 2000);</script></body></html>',
      );
      return;
    }
    try {
      const result = await this.paypal.captureOrder(token);
      const appScheme = process.env.PAYPAL_APP_SCHEME || 'cognicare';
      const redirectUrl = `${appScheme}://paypal-success?orderId=${encodeURIComponent(result.id ?? token)}&status=success`;
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      res.send(
        `<!DOCTYPE html><html><head><meta charset="utf-8"><meta http-equiv="refresh" content="2;url=${redirectUrl}"></head><body><p>Paiement réussi. Retour à l'app...</p><p><a href="${redirectUrl}">Cliquez ici si la redirection ne fonctionne pas</a></p></body></html>`,
      );
    } catch (e) {
      res.status(500).send(
        `<html><body><p>Erreur: ${(e as Error).message}</p></body></html>`,
      );
    }
  }

  @Get('order-status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get PayPal order status (COMPLETED = paid)' })
  async orderStatus(@Query('orderId') orderId: string | undefined) {
    if (!orderId) {
      throw new BadRequestException('orderId is required');
    }
    if (!this.paypal.isConfigured()) {
      throw new BadRequestException('PayPal is not configured');
    }
    const { status } = await this.paypal.getOrderStatus(orderId);
    return { orderId, status };
  }

  @Get('cancel')
  @ApiOperation({ summary: 'PayPal redirects here if user cancels' })
  async cancel(@Res() res: Response) {
    const appScheme = process.env.PAYPAL_APP_SCHEME || 'cognicare';
    const redirectUrl = `${appScheme}://paypal-success?status=cancelled`;
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(
      `<!DOCTYPE html><html><head><meta charset="utf-8"><meta http-equiv="refresh" content="2;url=${redirectUrl}"></head><body><p>Paiement annulé.</p><p><a href="${redirectUrl}">Retour à l'app</a></p></body></html>`,
    );
  }
}
