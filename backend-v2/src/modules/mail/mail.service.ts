import { Injectable, InternalServerErrorException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";

import sgMail = require("@sendgrid/mail");
import { getEmailBaseTemplate } from "./templates/email-base.template";
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
  getOrderConfirmationTemplate,
  getBioherbsOrderConfirmationTemplate,
} from "./templates/email-templates";

@Injectable()
export class MailService {
  private readonly apiKey: string | undefined;
  private readonly from: string | undefined;

  constructor(private readonly configService: ConfigService) {
    this.apiKey = this.configService.get<string>("SENDGRID_API_KEY");
    this.from = this.configService.get<string>("MAIL_FROM");
    if (!this.apiKey) {
      console.warn("WARNING: SENDGRID_API_KEY not defined.");
      return;
    }
    sgMail.setApiKey(this.apiKey);
  }

  private async send(
    to: string,
    subject: string,
    bodyContent: string,
    critical = true,
  ): Promise<boolean> {
    if (!this.apiKey || !this.from) {
      console.warn(`Skipping email to ${to}: not configured`);
      return false;
    }
    const html = getEmailBaseTemplate(bodyContent);
    try {
      await sgMail.send({ to, from: this.from, subject, html });
      console.log(`Email sent to ${to}`);
      return true;
    } catch (err: unknown) {
      console.error(`Failed to send email to ${to}:`, err);
      if (critical)
        throw new InternalServerErrorException(
          "Could not send email. Please try again later.",
        );
      return false;
    }
  }

  async sendVerificationCode(email: string, code: string): Promise<void> {
    await this.send(
      email,
      "CogniCare - Verify Your Email Address",
      getVerificationCodeTemplate(code),
    );
  }
  async sendPasswordResetCode(email: string, code: string): Promise<void> {
    await this.send(
      email,
      "CogniCare - Password Reset Request",
      getPasswordResetTemplate(code),
    );
  }
  async sendWelcomeEmail(email: string, userName: string): Promise<void> {
    await this.send(
      email,
      "Welcome to CogniCare! 🎉",
      getWelcomeTemplate(userName),
      false,
    );
  }

  async sendOrganizationInvitation(
    email: string,
    orgName: string,
    invitationType: "staff" | "family",
    acceptUrl: string,
    rejectUrl: string,
  ): Promise<void> {
    await this.send(
      email,
      `You're Invited to Join ${orgName} on CogniCare`,
      getOrganizationInvitationTemplate(
        orgName,
        invitationType,
        acceptUrl,
        rejectUrl,
      ),
    );
  }

  async sendOrganizationPending(
    email: string,
    orgName: string,
    leaderName: string,
  ): Promise<void> {
    await this.send(
      email,
      `Organization Application Received - ${orgName}`,
      getOrganizationPendingTemplate(orgName, leaderName),
    );
  }

  async sendOrganizationApproved(
    email: string,
    orgName: string,
    leaderName: string,
  ): Promise<void> {
    await this.send(
      email,
      `🎉 Your Organization "${orgName}" Has Been Approved!`,
      getOrganizationApprovedTemplate(orgName, leaderName),
    );
  }

  async sendOrganizationRejected(
    email: string,
    orgName: string,
    leaderName: string,
    reason?: string,
  ): Promise<void> {
    await this.send(
      email,
      `Organization Application Update - ${orgName}`,
      getOrganizationRejectedTemplate(orgName, leaderName, reason),
    );
  }

  async sendVolunteerApproved(email: string, userName: string): Promise<void> {
    await this.send(
      email,
      "CogniCare – Your volunteer application has been approved",
      getVolunteerApprovedTemplate(userName),
    );
  }

  async sendVolunteerDenied(
    email: string,
    userName: string,
    reason?: string,
    courseUrl?: string,
  ): Promise<void> {
    await this.send(
      email,
      "CogniCare – Volunteer application update",
      getVolunteerDeniedTemplate(userName, reason, courseUrl),
    );
  }

  async sendOrgLeaderInvitation(
    email: string,
    leaderName: string,
    orgName: string,
    acceptUrl: string,
    rejectUrl: string,
  ): Promise<boolean> {
    const content = `
      <h2 style="color: #2c3e50;">You've Been Invited to Lead an Organization!</h2>
      <p>Hello <strong>${leaderName}</strong>, you've been invited to lead <strong>${orgName}</strong> on CogniCare.</p>
      <div style="text-align: center; margin: 30px 0;">
        <a href="${acceptUrl}" style="background: linear-gradient(135deg, #6a5acd, #836fff); color: white; padding: 14px 28px; border-radius: 8px; font-weight: bold; display: inline-block; margin-right: 10px;">Accept</a>
        <a href="${rejectUrl}" style="background: #e74c3c; color: white; padding: 14px 28px; border-radius: 8px; font-weight: bold; display: inline-block;">Decline</a>
      </div>`;
    return this.send(
      email,
      `CogniCare – You're Invited to Lead ${orgName}`,
      content,
      false,
    );
  }

  async sendOrderToCogniCare(payload: {
    orderId: string;
    productName: string;
    quantity: number;
    price?: string;
    formData: Record<string, string>;
  }): Promise<boolean> {
    const to =
      this.configService.get<string>("COGNICARE_ORDER_EMAIL") || this.from;
    if (!to) return false;
    const d = payload.formData;
    const lines = [
      `<p><strong>Commande #${payload.orderId}</strong></p>`,
      `<p><strong>Produit:</strong> ${payload.productName}</p>`,
      `<p><strong>Quantité:</strong> ${payload.quantity}</p>`,
      d.email ? `<p>Email: ${d.email}</p>` : "",
      d.phone ? `<p>Téléphone: ${d.phone}</p>` : "",
    ].filter(Boolean);
    return this.send(
      to,
      `CogniCare - Commande #${payload.orderId}`,
      lines.join(""),
      false,
    );
  }

  async sendOrderConfirmationToCustomer(
    email: string,
    params: { orderId: string; productName: string; quantity: number },
  ): Promise<boolean> {
    if (!email?.trim()) return false;
    return this.send(
      email.trim(),
      `CogniCare - Commande #${params.orderId} enregistrée`,
      getOrderConfirmationTemplate(params),
      false,
    );
  }

  async sendBioherbsOrderConfirmationToCustomer(
    email: string,
    params: {
      orderId: string;
      productName: string;
      quantity: number;
      sentToBioherbs: boolean;
    },
  ): Promise<boolean> {
    if (!email?.trim()) return false;
    return this.send(
      email.trim(),
      `Commande transmise à BioHerbs - #${params.orderId}`,
      getBioherbsOrderConfirmationTemplate(params),
      false,
    );
  }
}
