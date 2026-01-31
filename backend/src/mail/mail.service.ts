import { Injectable, InternalServerErrorException } from '@nestjs/common';
// eslint-disable-next-line @typescript-eslint/no-require-imports
import sgMail = require('@sendgrid/mail');

@Injectable()
export class MailService {
  constructor() {
    const apiKey = process.env.SENDGRID_API_KEY;
    if (!apiKey) {
      throw new Error('SENDGRID_API_KEY is not defined');
    }
    sgMail.setApiKey(apiKey);
  }

  async sendVerificationCode(email: string, code: string): Promise<void> {
    const from = process.env.MAIL_FROM;
    if (!from) {
      throw new Error('MAIL_FROM is not defined');
    }

    const msg = {
      to: email,
      from: from,
      subject: 'CogniCare - Verify your email address',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #A4D7E1;">CogniCare - Email Verification</h2>
          <p>Your verification code is:</p>
          <h1 style="font-size: 32px; letter-spacing: 4px; color: #A4D7E1;">${code}</h1>
          <p>This code will expire in 10 minutes.</p>
          <p style="color: #888; font-size: 12px;">If you didn't request this code, please ignore this email.</p>
        </div>
      `,
    };

    try {
      await sgMail.send(msg);
      console.log(`Verification email sent to ${email}`);
    } catch (err: any) {
      console.error('Failed to send verification email:', err);
      
      // Provide more specific error messages
      if (err.code === 403) {
        console.error('SendGrid Error: Your sender email is not verified.');
        console.error('Please verify your sender identity at: https://app.sendgrid.com/settings/sender_auth/senders');
        throw new InternalServerErrorException(
          'Email sending is not properly configured. Please contact support.',
        );
      }
      
      throw new InternalServerErrorException(
        'Could not send verification email. Please try again later.',
      );
    }
  }
}
