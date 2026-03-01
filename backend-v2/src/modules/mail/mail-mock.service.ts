import { Injectable } from "@nestjs/common";

@Injectable()
export class MailMockService {
  private log(to: string, subject: string, extra = "") {
    console.log("=".repeat(60));
    console.log("📧 MOCK EMAIL SERVICE - Development Mode");
    console.log(`To: ${to} | Subject: ${subject}`);
    if (extra) console.log(extra);
    console.log("=".repeat(60));
  }

  sendVerificationCode(email: string, code: string): Promise<void> {
    this.log(email, "Verify Email", `Code: ${code}`);
    return Promise.resolve();
  }
  sendPasswordResetCode(email: string, code: string): Promise<void> {
    this.log(email, "Password Reset", `Code: ${code}`);
    return Promise.resolve();
  }
  sendWelcomeEmail(email: string, userName: string): Promise<void> {
    this.log(email, `Welcome ${userName}`);
    return Promise.resolve();
  }
  sendOrganizationInvitation(
    email: string,
    orgName: string,
    _type: string,
    acceptUrl: string,
    _rejectUrl: string,
  ): Promise<void> {
    this.log(email, `Invitation to ${orgName}`, `Accept: ${acceptUrl}`);
    return Promise.resolve();
  }
  sendOrganizationPending(
    email: string,
    orgName: string,
    _leaderName: string,
  ): Promise<void> {
    this.log(email, `Org Pending - ${orgName}`);
    return Promise.resolve();
  }
  sendOrganizationApproved(
    email: string,
    orgName: string,
    _leaderName: string,
  ): Promise<void> {
    this.log(email, `Org Approved - ${orgName}`);
    return Promise.resolve();
  }
  sendOrganizationRejected(
    email: string,
    orgName: string,
    _leaderName: string,
    _reason?: string,
  ): Promise<void> {
    this.log(email, `Org Rejected - ${orgName}`);
    return Promise.resolve();
  }
  sendVolunteerApproved(email: string, userName: string): Promise<void> {
    this.log(email, `Volunteer Approved - ${userName}`);
    return Promise.resolve();
  }
  sendVolunteerDenied(
    email: string,
    userName: string,
    _reason?: string,
  ): Promise<void> {
    this.log(email, `Volunteer Denied - ${userName}`);
    return Promise.resolve();
  }
  async sendOrgLeaderInvitation(
    email: string,
    leaderName: string,
    orgName: string,
    acceptUrl: string,
    _rejectUrl: string,
  ): Promise<boolean> {
    this.log(email, `Lead ${orgName}`, `${leaderName} Accept: ${acceptUrl}`);
    return true;
  }
  async sendOrderToCogniCare(_payload: any): Promise<boolean> {
    this.log("cognicare", "Order notification");
    return true;
  }
  async sendOrderConfirmationToCustomer(
    email: string,
    _params: any,
  ): Promise<boolean> {
    this.log(email, "Order Confirmation");
    return true;
  }
  async sendBioherbsOrderConfirmationToCustomer(
    email: string,
    _params: any,
  ): Promise<boolean> {
    this.log(email, "BioHerbs Confirmation");
    return true;
  }
}
