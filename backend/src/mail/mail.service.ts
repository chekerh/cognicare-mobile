import { Injectable, InternalServerErrorException } from '@nestjs/common';
// eslint-disable-next-line @typescript-eslint/no-require-imports
import sgMail = require('@sendgrid/mail');
import { getEmailBaseTemplate } from './templates/email-base.template';
import {
  getVerificationCodeTemplate,
  getPasswordResetTemplate,
  getWelcomeTemplate,
} from './templates/email-templates';

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

    const emailContent = getVerificationCodeTemplate(code);
    const htmlContent = getEmailBaseTemplate(emailContent);

    const msg = {
      to: email,
      from: from,
      subject: 'CogniCare - Verify Your Email Address',
      html: htmlContent,
    };

    try {
      await sgMail.send(msg);
      console.log(`Verification email sent to ${email}`);
    } catch (err: unknown) {
      console.error('Failed to send verification email:', err);

      // Provide more specific error messages
      if (err && typeof err === 'object' && 'code' in err && err.code === 403) {
        console.error('SendGrid Error: Your sender email is not verified.');
        console.error(
          'Please verify your sender identity at: https://app.sendgrid.com/settings/sender_auth/senders',
        );
        throw new InternalServerErrorException(
          'Email sending is not properly configured. Please contact support.',
        );
      }

      throw new InternalServerErrorException(
        'Could not send verification email. Please try again later.',
      );
    }
  }

  async sendPasswordResetCode(email: string, code: string): Promise<void> {
    const from = process.env.MAIL_FROM;
    if (!from) {
      throw new Error('MAIL_FROM is not defined');
    }

    const emailContent = getPasswordResetTemplate(code);
    const htmlContent = getEmailBaseTemplate(emailContent);

    const msg = {
      to: email,
      from: from,
      subject: 'CogniCare - Password Reset Request',
      html: htmlContent,
    };

    try {
      await sgMail.send(msg);
      console.log(`Password reset email sent to ${email}`);
    } catch (err: unknown) {
      console.error('Failed to send password reset email:', err);
      throw new InternalServerErrorException(
        'Could not send password reset email. Please try again later.',
      );
    }
  }

  async sendWelcomeEmail(email: string, userName: string): Promise<void> {
    const from = process.env.MAIL_FROM;
    if (!from) {
      throw new Error('MAIL_FROM is not defined');
    }

    const emailContent = getWelcomeTemplate(userName);
    const htmlContent = getEmailBaseTemplate(emailContent);

    const msg = {
      to: email,
      from: from,
      subject: 'Welcome to CogniCare! 🎉',
      html: htmlContent,
    };

    try {
      await sgMail.send(msg);
      console.log(`Welcome email sent to ${email}`);
    } catch (err: unknown) {
      console.error('Failed to send welcome email:', err);
      // Don't throw error for welcome emails - it's not critical
    }
  }
}
