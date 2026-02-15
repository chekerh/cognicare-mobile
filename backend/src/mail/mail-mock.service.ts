import { Injectable } from '@nestjs/common';

/**
 * Mock mail service for development/testing
 * Logs verification codes to console instead of sending emails
 */
@Injectable()
export class MailMockService {
  sendVerificationCode(email: string, code: string): Promise<void> {
    console.log('='.repeat(60));
    console.log('📧 MOCK EMAIL SERVICE - Development Mode');
    console.log('='.repeat(60));
    console.log(`To: ${email}`);
    console.log(`Subject: CogniCare - Verify your email address`);
    console.log(`\nYour verification code is: ${code}`);
    console.log(`\nThis code will expire in 10 minutes.`);
    console.log('='.repeat(60));
    return Promise.resolve();
  }

  sendPasswordReset(email: string, resetCode: string): Promise<void> {
    console.log('='.repeat(60));
    console.log('📧 MOCK EMAIL SERVICE - Development Mode');
    console.log('='.repeat(60));
    console.log(`To: ${email}`);
    console.log(`Subject: CogniCare - Reset Your Password`);
    console.log(`\nYour password reset code is: ${resetCode}`);
    console.log(`\nThis code will expire in 10 minutes.`);
    console.log('='.repeat(60));
    return Promise.resolve();
  }

  sendWelcome(email: string, fullName: string): Promise<void> {
    console.log('='.repeat(60));
    console.log('📧 MOCK EMAIL SERVICE - Development Mode');
    console.log('='.repeat(60));
    console.log(`To: ${email}`);
    console.log(`Subject: Welcome to CogniCare, ${fullName}!`);
    console.log(`\nWelcome email would be sent here.`);
    console.log('='.repeat(60));
    return Promise.resolve();
  }

  sendOrganizationInvitation(
    email: string,
    orgName: string,
    userName: string,
    acceptUrl: string,
    rejectUrl: string,
  ): Promise<void> {
    console.log('='.repeat(60));
    console.log('📧 MOCK EMAIL SERVICE - Development Mode');
    console.log('='.repeat(60));
    console.log(`To: ${email}`);
    console.log(`Subject: Invitation to join ${orgName}`);
    console.log(`\nHello ${userName},\n`);
    console.log(`You've been invited to join ${orgName}!`);
    console.log(`\nAccept URL: ${acceptUrl}`);
    console.log(`Reject URL: ${rejectUrl}`);
    console.log('='.repeat(60));
    return Promise.resolve();
  }

  sendOrganizationPending(
    email: string,
    orgName: string,
    userName: string,
  ): Promise<void> {
    console.log('='.repeat(60));
    console.log('📧 MOCK EMAIL SERVICE - Development Mode');
    console.log('='.repeat(60));
    console.log(`To: ${email}`);
    console.log(`Subject: Organization Request Pending - ${orgName}`);
    console.log(`\nHello ${userName},\n`);
    console.log(`Your organization ${orgName} is pending admin approval.`);
    console.log('='.repeat(60));
    return Promise.resolve();
  }

  sendOrganizationApproved(
    email: string,
    orgName: string,
    userName: string,
  ): Promise<void> {
    console.log('='.repeat(60));
    console.log('📧 MOCK EMAIL SERVICE - Development Mode');
    console.log('='.repeat(60));
    console.log(`To: ${email}`);
    console.log(`Subject: Organization Approved - ${orgName}`);
    console.log(`\nHello ${userName},\n`);
    console.log(
      `Congratulations! Your organization ${orgName} has been approved!`,
    );
    console.log('='.repeat(60));
    return Promise.resolve();
  }

  sendOrganizationRejected(
    email: string,
    orgName: string,
    userName: string,
    reason?: string,
  ): Promise<void> {
    console.log('='.repeat(60));
    console.log('📧 MOCK EMAIL SERVICE - Development Mode');
    console.log('='.repeat(60));
    console.log(`To: ${email}`);
    console.log(`Subject: Organization Request Rejected - ${orgName}`);
    console.log(`\nHello ${userName},\n`);
    console.log(`Your organization ${orgName} was not approved.`);
    if (reason) {
      console.log(`\nReason: ${reason}`);
    }
    console.log('='.repeat(60));
    return Promise.resolve();
  }

  sendVolunteerApproved(email: string, userName: string): Promise<void> {
    console.log('='.repeat(60));
    console.log('📧 MOCK EMAIL SERVICE - Development Mode');
    console.log('='.repeat(60));
    console.log(`To: ${email}`);
    console.log(`Subject: Volunteer Application Approved`);
    console.log(`\nHello ${userName},\n`);
    console.log(
      `Congratulations! Your volunteer application has been approved.`,
    );
    console.log('='.repeat(60));
    return Promise.resolve();
  }

  sendVolunteerDenied(
    email: string,
    userName: string,
    reason?: string,
  ): Promise<void> {
    console.log('='.repeat(60));
    console.log('📧 MOCK EMAIL SERVICE - Development Mode');
    console.log('='.repeat(60));
    console.log(`To: ${email}`);
    console.log(`Subject: Volunteer Application Update`);
    console.log(`\nHello ${userName},\n`);
    console.log(`Your volunteer application was not approved.`);
    if (reason) {
      console.log(`\nReason: ${reason}`);
    }
    console.log('='.repeat(60));
    return Promise.resolve();
  }

  async sendOrgLeaderInvitation(
    email: string,
    leaderName: string,
    organizationName: string,
    acceptUrl: string,
    rejectUrl: string,
  ): Promise<boolean> {
    console.log('='.repeat(60));
    console.log('📧 MOCK EMAIL SERVICE - Development Mode');
    console.log('='.repeat(60));
    console.log(`To: ${email}`);
    console.log(
      `Subject: CogniCare – You're Invited to Lead ${organizationName}`,
    );
    console.log(`\nHello ${leaderName},\n`);
    console.log(
      `You have been invited to become the Organization Leader for ${organizationName}!`,
    );
    console.log(`\nAs an Organization Leader, you will be able to:`);
    console.log(`  • Manage staff members (doctors, therapists, volunteers)`);
    console.log(`  • Oversee families and children in your care`);
    console.log(`  • Access organization analytics and reports`);
    console.log(`\nAccept Invitation: ${acceptUrl}`);
    console.log(`Decline Invitation: ${rejectUrl}`);
    console.log(`\nThis invitation will expire in 7 days.`);
    console.log('='.repeat(60));
    return Promise.resolve(true);
  }
}
