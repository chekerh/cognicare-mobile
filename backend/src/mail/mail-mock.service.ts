import { Injectable } from '@nestjs/common';

/**
 * Mock mail service for development/testing
 * Logs verification codes to console instead of sending emails
 */
@Injectable()
export class MailMockService {
  async sendVerificationCode(email: string, code: string): Promise<void> {
    console.log('='.repeat(60));
    console.log('📧 MOCK EMAIL SERVICE - Development Mode');
    console.log('='.repeat(60));
    console.log(`To: ${email}`);
    console.log(`Subject: CogniCare - Verify your email address`);
    console.log(`\nYour verification code is: ${code}`);
    console.log(`\nThis code will expire in 10 minutes.`);
    console.log('='.repeat(60));
  }
}
