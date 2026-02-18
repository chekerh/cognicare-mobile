import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
// eslint-disable-next-line @typescript-eslint/no-require-imports
import sgMail = require('@sendgrid/mail');
import { getEmailBaseTemplate } from './templates/email-base.template';
import {
  getVerificationCodeTemplate,
  getPasswordResetTemplate,
  getWelcomeTemplate,
  getOrganizationInvitationTemplate,
  getOrganizationPendingTemplate,
  getOrganizationApprovedTemplate,
  getOrganizationRejectedTemplate,
  getVolunteerApprovedTemplate,
  getVolunteerDeniedTemplate,
} from './templates/email-templates';

@Injectable()
export class MailService {
  private readonly apiKey: string | undefined;
  private readonly from: string | undefined;

  constructor(private readonly configService: ConfigService) {
    this.apiKey = this.configService.get<string>('SENDGRID_API_KEY');
    this.from = this.configService.get<string>('MAIL_FROM');

    if (!this.apiKey) {
      console.warn(
        'WARNING: SENDGRID_API_KEY is not defined. Email functionality will be disabled.',
      );
      return;
    }

    sgMail.setApiKey(this.apiKey);

    if (!this.from) {
      console.warn(
        'WARNING: MAIL_FROM is not defined. Email functionality may not work as expected.',
      );
    }
  }

  async sendVerificationCode(email: string, code: string): Promise<void> {
    if (!this.apiKey || !this.from) {
      console.warn(
        'Skipping verification email: SENDGRID_API_KEY or MAIL_FROM not configured',
      );
      return;
    }

    const emailContent = getVerificationCodeTemplate(code);
    const htmlContent = getEmailBaseTemplate(emailContent);

    const msg = {
      to: email,
      from: this.from,
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
    if (!this.apiKey || !this.from) {
      console.warn(
        'Skipping password reset email: SENDGRID_API_KEY or MAIL_FROM not configured',
      );
      return;
    }

    const emailContent = getPasswordResetTemplate(code);
    const htmlContent = getEmailBaseTemplate(emailContent);

    const msg = {
      to: email,
      from: this.from,
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
    if (!this.apiKey || !this.from) {
      console.warn(
        'Skipping welcome email: SENDGRID_API_KEY or MAIL_FROM not configured',
      );
      return;
    }

    const emailContent = getWelcomeTemplate(userName);
    const htmlContent = getEmailBaseTemplate(emailContent);

    const msg = {
      to: email,
      from: this.from,
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

  async sendOrganizationInvitation(
    email: string,
    organizationName: string,
    invitationType: 'staff' | 'family',
    acceptUrl: string,
    rejectUrl: string,
  ): Promise<void> {
    if (!this.apiKey || !this.from) {
      console.warn(
        'Skipping invitation email: SENDGRID_API_KEY or MAIL_FROM not configured',
      );
      return;
    }

    const emailContent = getOrganizationInvitationTemplate(
      organizationName,
      invitationType,
      acceptUrl,
      rejectUrl,
    );
    const htmlContent = getEmailBaseTemplate(emailContent);

    const msg = {
      to: email,
      from: this.from,
      subject: `You're Invited to Join ${organizationName} on CogniCare`,
      html: htmlContent,
    };

    try {
      await sgMail.send(msg);
      console.log(`Organization invitation email sent to ${email}`);
    } catch (err: unknown) {
      console.error('Failed to send invitation email:', err);
      throw new InternalServerErrorException(
        'Could not send invitation email. Please try again later.',
      );
    }
  }

  async sendOrganizationPending(
    email: string,
    organizationName: string,
    leaderName: string,
  ): Promise<void> {
    if (!this.apiKey || !this.from) {
      console.warn(
        'Skipping organization pending email: SENDGRID_API_KEY or MAIL_FROM not configured',
      );
      return;
    }

    const emailContent = getOrganizationPendingTemplate(
      organizationName,
      leaderName,
    );
    const htmlContent = getEmailBaseTemplate(emailContent);

    const msg = {
      to: email,
      from: this.from,
      subject: `Organization Application Received - ${organizationName}`,
      html: htmlContent,
    };

    try {
      await sgMail.send(msg);
      console.log(`Organization pending email sent to ${email}`);
    } catch (err: unknown) {
      console.error('Failed to send organization pending email:', err);
      throw new InternalServerErrorException(
        'Could not send organization pending email.',
      );
    }
  }

  async sendOrganizationApproved(
    email: string,
    organizationName: string,
    leaderName: string,
  ): Promise<void> {
    if (!this.apiKey || !this.from) {
      console.warn(
        'Skipping organization approved email: SENDGRID_API_KEY or MAIL_FROM not configured',
      );
      return;
    }

    const emailContent = getOrganizationApprovedTemplate(
      organizationName,
      leaderName,
    );
    const htmlContent = getEmailBaseTemplate(emailContent);

    const msg = {
      to: email,
      from: this.from,
      subject: `🎉 Your Organization "${organizationName}" Has Been Approved!`,
      html: htmlContent,
    };

    try {
      await sgMail.send(msg);
      console.log(`Organization approved email sent to ${email}`);
    } catch (err: unknown) {
      console.error('Failed to send organization approved email:', err);
      throw new InternalServerErrorException(
        'Could not send organization approved email.',
      );
    }
  }

  async sendOrganizationRejected(
    email: string,
    organizationName: string,
    leaderName: string,
    rejectionReason?: string,
  ): Promise<void> {
    if (!this.apiKey || !this.from) {
      console.warn(
        'Skipping organization rejected email: SENDGRID_API_KEY or MAIL_FROM not configured',
      );
      return;
    }

    const emailContent = getOrganizationRejectedTemplate(
      organizationName,
      leaderName,
      rejectionReason,
    );
    const htmlContent = getEmailBaseTemplate(emailContent);

    const msg = {
      to: email,
      from: this.from,
      subject: `Organization Application Update - ${organizationName}`,
      html: htmlContent,
    };

    try {
      await sgMail.send(msg);
      console.log(`Organization rejected email sent to ${email}`);
    } catch (err: unknown) {
      console.error('Failed to send organization rejected email:', err);
      throw new InternalServerErrorException(
        'Could not send organization rejected email.',
      );
    }
  }

  async sendVolunteerApproved(email: string, userName: string): Promise<void> {
    if (!this.apiKey || !this.from) {
      console.warn(
        'Skipping volunteer approved email: SENDGRID_API_KEY or MAIL_FROM not configured',
      );
      return;
    }
    const emailContent = getVolunteerApprovedTemplate(userName);
    const htmlContent = getEmailBaseTemplate(emailContent);
    const msg = {
      to: email,
      from: this.from,
      subject: 'CogniCare – Your volunteer application has been approved',
      html: htmlContent,
    };
    try {
      await sgMail.send(msg);
      console.log(`Volunteer approved email sent to ${email}`);
    } catch (err: unknown) {
      console.error('Failed to send volunteer approved email:', err);
      throw new InternalServerErrorException(
        'Could not send volunteer approved email.',
      );
    }
  }

  async sendVolunteerDenied(
    email: string,
    userName: string,
    deniedReason?: string,
    courseUrl?: string,
  ): Promise<void> {
    if (!this.apiKey || !this.from) {
      console.warn(
        'Skipping volunteer denied email: SENDGRID_API_KEY or MAIL_FROM not configured',
      );
      return;
    }
    const emailContent = getVolunteerDeniedTemplate(
      userName,
      deniedReason,
      courseUrl,
    );
    const htmlContent = getEmailBaseTemplate(emailContent);
    const msg = {
      to: email,
      from: this.from,
      subject: 'CogniCare – Volunteer application update',
      html: htmlContent,
    };
    try {
      await sgMail.send(msg);
      console.log(`Volunteer denied email sent to ${email}`);
    } catch (err: unknown) {
      console.error('Failed to send volunteer denied email:', err);
      throw new InternalServerErrorException(
        'Could not send volunteer denied email.',
      );
    }
  }

  async sendOrgLeaderInvitation(
    email: string,
    leaderName: string,
    organizationName: string,
    acceptUrl: string,
    rejectUrl: string,
  ): Promise<boolean> {
    if (!this.apiKey || !this.from) {
      console.warn(
        'Skipping org leader invitation email: SENDGRID_API_KEY or MAIL_FROM not configured',
      );
      return false;
    }

    const emailContent = `
      <h2 style="color: #2c3e50; margin-bottom: 20px;">You've Been Invited to Lead an Organization!</h2>
      <p style="color: #555; font-size: 16px; line-height: 1.6;">
        Hello <strong>${leaderName}</strong>,
      </p>
      <p style="color: #555; font-size: 16px; line-height: 1.6;">
        You have been invited to become the <strong>Organization Leader</strong> for 
        <strong style="color: #6a5acd;">${organizationName}</strong> on the CogniCare platform.
      </p>
      <p style="color: #555; font-size: 16px; line-height: 1.6;">
        As an Organization Leader, you will be able to:
      </p>
      <ul style="color: #555; font-size: 16px; line-height: 1.8;">
        <li>Manage staff members (doctors, therapists, volunteers)</li>
        <li>Oversee families and children in your care</li>
        <li>Access organization analytics and reports</li>
      </ul>
      <div style="text-align: center; margin: 30px 0;">
        <a href="${acceptUrl}" 
           style="background: linear-gradient(135deg, #6a5acd 0%, #836fff 100%); 
                  color: white; 
                  padding: 14px 28px; 
                  text-decoration: none; 
                  border-radius: 8px; 
                  font-weight: bold; 
                  display: inline-block;
                  margin-right: 10px;">
          Accept Invitation
        </a>
        <a href="${rejectUrl}" 
           style="background: #e74c3c; 
                  color: white; 
                  padding: 14px 28px; 
                  text-decoration: none; 
                  border-radius: 8px; 
                  font-weight: bold; 
                  display: inline-block;">
          Decline
        </a>
      </div>
      <p style="color: #888; font-size: 14px; margin-top: 20px;">
        This invitation will expire in 7 days. If you did not expect this invitation, 
        you can safely ignore this email.
      </p>
    `;

    const htmlContent = getEmailBaseTemplate(emailContent);

    const msg = {
      to: email,
      from: this.from,
      subject: `CogniCare – You're Invited to Lead ${organizationName}`,
      html: htmlContent,
    };

    try {
      console.log(`Attempting to send org leader invitation email to ${email}`);
      console.log(`Using from address: ${this.from}`);
      console.log(`Accept URL: ${acceptUrl}`);
      console.log(`Reject URL: ${rejectUrl}`);

      await sgMail.send(msg);
      console.log(
        `✅ Org leader invitation email sent successfully to ${email}`,
      );
      return true;
    } catch (err: unknown) {
      // Log detailed error for debugging
      console.error('❌ FAILED to send org leader invitation email');
      console.error(`Recipient: ${email}`);
      console.error(`Organization: ${organizationName}`);

      if (err && typeof err === 'object' && 'code' in err) {
        console.error('SendGrid error code:', err.code);
        if ('response' in err && err.response) {
          console.error(
            'SendGrid response:',
            JSON.stringify(err.response, null, 2),
          );
        }
      }
      console.error('Full error:', err);

      // Don't throw - allow invitation to be created even if email fails
      // This handles cases where SendGrid is misconfigured in production
      console.warn(
        'Invitation created but email not sent. Manual notification may be required.',
      );
      return false;
    }
  }
}
