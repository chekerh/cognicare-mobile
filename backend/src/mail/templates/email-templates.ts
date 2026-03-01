export const getVerificationCodeTemplate = (code: string): string => {
  return `
    <div style="text-align: center;">
      <h2 style="color: #5A5A5A; font-size: 24px; margin-bottom: 20px;">
        Email Verification
      </h2>
      <p style="color: #5A5A5A; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        Thank you for signing up with CogniCare! To complete your registration, please use the verification code below:
      </p>
      
      <div style="background-color: #f9f9f9; border: 2px dashed #A4D7E1; border-radius: 12px; padding: 30px; margin: 30px 0;">
        <p style="color: #5A5A5A; font-size: 14px; margin-bottom: 10px; text-transform: uppercase; letter-spacing: 1px;">
          Your Verification Code
        </p>
        <h1 style="font-size: 48px; letter-spacing: 8px; color: #A4D7E1; margin: 10px 0; font-weight: bold;">
          ${code}
        </h1>
      </div>

      <div style="background-color: #FFF9E6; border-left: 4px solid #F9D51C; padding: 15px; margin: 30px 0; text-align: left;">
        <p style="color: #5A5A5A; font-size: 14px; margin: 0;">
          <strong>⏰ Important:</strong> This code will expire in <strong>10 minutes</strong> for your security.
        </p>
      </div>

      <p style="color: #5A5A5A; font-size: 14px; line-height: 1.6; margin-top: 30px;">
        If you didn't request this verification code, please ignore this email or contact our support team if you have concerns.
      </p>

      <div style="margin-top: 40px; padding-top: 30px; border-top: 1px solid #e0e0e0;">
        <p style="color: #888; font-size: 13px; line-height: 1.6;">
          Need help? Visit our <a href="#" style="color: #A4D7E1; text-decoration: none;">Help Center</a> or contact us at 
          <a href="mailto:support@cognicare.com" style="color: #A4D7E1; text-decoration: none;">support@cognicare.com</a>
        </p>
      </div>
    </div>
  `;
};

export const getPasswordResetTemplate = (code: string): string => {
  return `
    <div style="text-align: center;">
      <h2 style="color: #5A5A5A; font-size: 24px; margin-bottom: 20px;">
        Password Reset Request
      </h2>
      <p style="color: #5A5A5A; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        We received a request to reset your CogniCare account password. Use the code below to proceed:
      </p>
      
      <div style="background-color: #f9f9f9; border: 2px dashed #A4D7E1; border-radius: 12px; padding: 30px; margin: 30px 0;">
        <p style="color: #5A5A5A; font-size: 14px; margin-bottom: 10px; text-transform: uppercase; letter-spacing: 1px;">
          Password Reset Code
        </p>
        <h1 style="font-size: 48px; letter-spacing: 8px; color: #A4D7E1; margin: 10px 0; font-weight: bold;">
          ${code}
        </h1>
      </div>

      <div style="background-color: #FFF9E6; border-left: 4px solid #F9D51C; padding: 15px; margin: 30px 0; text-align: left;">
        <p style="color: #5A5A5A; font-size: 14px; margin: 0;">
          <strong>⏰ Important:</strong> This code will expire in <strong>10 minutes</strong> for your security.
        </p>
      </div>

      <div style="background-color: #FFE6E6; border-left: 4px solid #ff4444; padding: 15px; margin: 30px 0; text-align: left;">
        <p style="color: #5A5A5A; font-size: 14px; margin: 0;">
          <strong>🔒 Security Notice:</strong> If you didn't request a password reset, please ignore this email and ensure your account is secure. Consider changing your password if you suspect unauthorized access.
        </p>
      </div>

      <div style="margin-top: 40px; padding-top: 30px; border-top: 1px solid #e0e0e0;">
        <p style="color: #888; font-size: 13px; line-height: 1.6;">
          Need help? Visit our <a href="#" style="color: #A4D7E1; text-decoration: none;">Help Center</a> or contact us at 
          <a href="mailto:support@cognicare.com" style="color: #A4D7E1; text-decoration: none;">support@cognicare.com</a>
        </p>
      </div>
    </div>
  `;
};

export const getWelcomeTemplate = (userName: string): string => {
  return `
    <div style="text-align: center;">
      <h2 style="color: #5A5A5A; font-size: 28px; margin-bottom: 20px;">
        Welcome to CogniCare! 🎉
      </h2>
      <p style="color: #5A5A5A; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        Hi <strong>${userName}</strong>, we're thrilled to have you join our community!
      </p>

      <div style="background: linear-gradient(135deg, #A4D7E1 0%, #A7E9A4 100%); border-radius: 12px; padding: 30px; margin: 30px 0; color: white;">
        <h3 style="margin: 0 0 15px 0; font-size: 20px;">Your journey to better cognitive health starts now! 🧠✨</h3>
        <p style="margin: 0; font-size: 15px; opacity: 0.95;">
          CogniCare is here to support you every step of the way with personalized experiences designed for your well-being.
        </p>
      </div>

      <div style="text-align: left; margin: 40px 0;">
        <h3 style="color: #5A5A5A; font-size: 20px; margin-bottom: 20px;">Get Started:</h3>
        
        <div style="display: flex; align-items: start; margin-bottom: 20px;">
          <div style="background-color: #A4D7E1; color: white; border-radius: 50%; width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; margin-right: 15px; flex-shrink: 0; font-weight: bold;">1</div>
          <div>
            <h4 style="color: #5A5A5A; margin: 0 0 5px 0; font-size: 16px;">Download the App</h4>
            <p style="color: #888; margin: 0; font-size: 14px;">Available on iOS, Android, and Web</p>
          </div>
        </div>

        <div style="display: flex; align-items: start; margin-bottom: 20px;">
          <div style="background-color: #A7E9A4; color: white; border-radius: 50%; width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; margin-right: 15px; flex-shrink: 0; font-weight: bold;">2</div>
          <div>
            <h4 style="color: #5A5A5A; margin: 0 0 5px 0; font-size: 16px;">Complete Your Profile</h4>
            <p style="color: #888; margin: 0; font-size: 14px;">Help us personalize your experience</p>
          </div>
        </div>

        <div style="display: flex; align-items: start; margin-bottom: 20px;">
          <div style="background-color: #F9D51C; color: white; border-radius: 50%; width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; margin-right: 15px; flex-shrink: 0; font-weight: bold;">3</div>
          <div>
            <h4 style="color: #5A5A5A; margin: 0 0 5px 0; font-size: 16px;">Start Your Journey</h4>
            <p style="color: #888; margin: 0; font-size: 14px;">Explore guided exercises and track your progress</p>
          </div>
        </div>
      </div>

      <div style="background-color: #f9f9f9; border-radius: 12px; padding: 25px; margin: 30px 0;">
        <p style="color: #5A5A5A; font-size: 14px; line-height: 1.6; margin: 0;">
          💡 <strong>Tip:</strong> Enable notifications to stay on track with your cognitive health routine and never miss important updates!
        </p>
      </div>

      <div style="margin-top: 40px;">
        <a href="#" style="display: inline-block; background-color: #A4D7E1; color: white; padding: 15px 40px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px;">
          Get Started Now →
        </a>
      </div>

      <div style="margin-top: 40px; padding-top: 30px; border-top: 1px solid #e0e0e0;">
        <p style="color: #888; font-size: 13px; line-height: 1.6;">
          Questions? We're here to help! Contact us at 
          <a href="mailto:support@cognicare.com" style="color: #A4D7E1; text-decoration: none;">support@cognicare.com</a>
        </p>
      </div>
    </div>
  `;
};

export const getOrganizationInvitationTemplate = (
  organizationName: string,
  invitationType: 'staff' | 'family',
  acceptUrl: string,
  rejectUrl: string,
): string => {
  return `
    <div style="text-align: center;">
      <h2 style="color: #5A5A5A; font-size: 24px; margin-bottom: 20px;">
        You're Invited to Join ${organizationName}!
      </h2>
      <p style="color: #5A5A5A; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        ${organizationName} has invited you to join their organization as a ${invitationType} member on CogniCare.
      </p>
      
      <div style="background-color: #f9f9f9; border-radius: 12px; padding: 30px; margin: 30px 0; text-align: left;">
        <h3 style="color: #5A5A5A; font-size: 18px; margin-bottom: 15px;">What This Means:</h3>
        <ul style="color: #5A5A5A; font-size: 14px; line-height: 1.8; padding-left: 20px;">
          ${
            invitationType === 'staff'
              ? `
            <li>You'll be able to support families and children in the organization</li>
            <li>Access to organization resources and tools</li>
            <li>Collaborate with other staff members</li>
          `
              : `
            <li>Your family will receive support from the organization's staff</li>
            <li>Access to specialized resources and activities</li>
            <li>Personalized care for your children</li>
          `
          }
        </ul>
      </div>

      <div style="background-color: #FFF9E6; border-left: 4px solid #F9D51C; padding: 15px; margin: 30px 0; text-align: left;">
        <p style="color: #5A5A5A; font-size: 14px; margin: 0;">
          <strong>⏰ Important:</strong> This invitation will expire in <strong>7 days</strong>. Please respond before then.
        </p>
      </div>

      <p style="color: #5A5A5A; font-size: 16px; margin-bottom: 30px;">
        Would you like to accept this invitation?
      </p>

      <div style="margin: 30px 0;">
        <a href="${acceptUrl}" style="display: inline-block; background-color: #A7E9A4; color: white; padding: 15px 40px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px; margin: 10px;">
          ✓ Accept Invitation
        </a>
        <a href="${rejectUrl}" style="display: inline-block; background-color: #FF7675; color: white; padding: 15px 40px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px; margin: 10px;">
          ✗ Decline
        </a>
      </div>

      <p style="color: #888; font-size: 13px; line-height: 1.6; margin-top: 30px;">
        If you didn't expect this invitation or have concerns, you can safely ignore this email or contact us for assistance.
      </p>

      <div style="margin-top: 40px; padding-top: 30px; border-top: 1px solid #e0e0e0;">
        <p style="color: #888; font-size: 13px; line-height: 1.6;">
          Need help? Contact us at 
          <a href="mailto:support@cognicare.com" style="color: #A4D7E1; text-decoration: none;">support@cognicare.com</a>
        </p>
      </div>
    </div>
  `;
};

export const getOrganizationApprovedTemplate = (
  organizationName: string,
  leaderName: string,
): string => {
  return `
    <div style="text-align: center;">
      <div style="background: linear-gradient(135deg, #4ade80 0%, #22c55e 100%); padding: 30px; border-radius: 12px; margin-bottom: 30px;">
        <h1 style="color: white; font-size: 32px; margin: 0;">
          🎉 Congratulations!
        </h1>
      </div>

      <h2 style="color: #5A5A5A; font-size: 24px; margin-bottom: 20px;">
        Your Organization Has Been Approved
      </h2>

      <p style="color: #5A5A5A; font-size: 16px; line-height: 1.6; margin-bottom: 20px;">
        Dear ${leaderName},
      </p>

      <p style="color: #5A5A5A; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        We're excited to inform you that your organization <strong>${organizationName}</strong> has been approved by our admin team!
      </p>

      <div style="background-color: #dcfce7; border-left: 4px solid #22c55e; padding: 20px; margin: 30px 0; text-align: left; border-radius: 8px;">
        <p style="color: #166534; font-size: 15px; margin: 0; line-height: 1.6;">
          <strong>✅ What's Next?</strong><br><br>
          You can now log in to your organization leader dashboard and start:
        </p>
        <ul style="color: #166534; font-size: 14px; margin: 15px 0; padding-left: 20px; text-align: left;">
          <li>Adding staff members (doctors, volunteers, therapists)</li>
          <li>Inviting families to join your organization</li>
          <li>Managing children's profiles and progress</li>
          <li>Accessing organization analytics and reports</li>
        </ul>
      </div>

      <p style="color: #5A5A5A; font-size: 14px; line-height: 1.6; margin-top: 30px;">
        Thank you for joining CogniCare. Together, we're making a difference in cognitive health support!
      </p>

      <div style="margin-top: 40px; padding-top: 30px; border-top: 1px solid #e0e0e0;">
        <p style="color: #888; font-size: 13px; line-height: 1.6;">
          Need help getting started? Contact us at 
          <a href="mailto:support@cognicare.com" style="color: #22c55e; text-decoration: none;">support@cognicare.com</a>
        </p>
      </div>
    </div>
  `;
};

export const getOrganizationRejectedTemplate = (
  organizationName: string,
  leaderName: string,
  rejectionReason?: string,
): string => {
  return `
    <div style="text-align: center;">
      <div style="background: linear-gradient(135deg, #f87171 0%, #ef4444 100%); padding: 30px; border-radius: 12px; margin-bottom: 30px;">
        <h1 style="color: white; font-size: 32px; margin: 0;">
          ℹ️ Application Update
        </h1>
      </div>

      <h2 style="color: #5A5A5A; font-size: 24px; margin-bottom: 20px;">
        Organization Application Status
      </h2>

      <p style="color: #5A5A5A; font-size: 16px; line-height: 1.6; margin-bottom: 20px;">
        Dear ${leaderName},
      </p>

      <p style="color: #5A5A5A; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        Thank you for your interest in creating <strong>${organizationName}</strong> on CogniCare. After careful review, we regret to inform you that your organization application was not approved at this time.
      </p>

      ${
        rejectionReason
          ? `
      <div style="background-color: #fee2e2; border-left: 4px solid #ef4444; padding: 20px; margin: 30px 0; text-align: left; border-radius: 8px;">
        <p style="color: #991b1b; font-size: 15px; margin: 0; line-height: 1.6;">
          <strong>📋 Reason:</strong><br><br>
          ${rejectionReason}
        </p>
      </div>
      `
          : ''
      }

      <div style="background-color: #fef3c7; border-left: 4px solid #f59e0b; padding: 20px; margin: 30px 0; text-align: left; border-radius: 8px;">
        <p style="color: #78350f; font-size: 15px; margin: 0; line-height: 1.6;">
          <strong>💡 What You Can Do:</strong><br><br>
          • Review our organization eligibility criteria<br>
          • Address any concerns mentioned above<br>
          • Reapply at a later time<br>
          • Contact our support team for clarification
        </p>
      </div>

      <p style="color: #5A5A5A; font-size: 14px; line-height: 1.6; margin-top: 30px;">
        We appreciate your understanding and encourage you to reach out if you have any questions about the decision.
      </p>

      <div style="margin-top: 40px; padding-top: 30px; border-top: 1px solid #e0e0e0;">
        <p style="color: #888; font-size: 13px; line-height: 1.6;">
          Have questions? Contact us at 
          <a href="mailto:support@cognicare.com" style="color: #ef4444; text-decoration: none;">support@cognicare.com</a>
        </p>
      </div>
    </div>
  `;
};

export const getOrganizationPendingTemplate = (
  organizationName: string,
  leaderName: string,
): string => {
  return `
    <div style="text-align: center;">
      <div style="background: linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%); padding: 30px; border-radius: 12px; margin-bottom: 30px;">
        <h1 style="color: white; font-size: 32px; margin: 0;">
          ⏳ Application Received
        </h1>
      </div>

      <h2 style="color: #5A5A5A; font-size: 24px; margin-bottom: 20px;">
        Organization Application Submitted
      </h2>

      <p style="color: #5A5A5A; font-size: 16px; line-height: 1.6; margin-bottom: 20px;">
        Dear ${leaderName},
      </p>

      <p style="color: #5A5A5A; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        Thank you for submitting your request to create <strong>${organizationName}</strong> on CogniCare!
      </p>

      <div style="background-color: #fef3c7; border-left: 4px solid #f59e0b; padding: 20px; margin: 30px 0; text-align: left; border-radius: 8px;">
        <p style="color: #78350f; font-size: 15px; margin: 0; line-height: 1.6;">
          <strong>🔍 What Happens Next?</strong><br><br>
          Your organization application is now under review by our admin team. We carefully review each application to ensure quality and compliance with our platform standards.
        </p>
      </div>

      <div style="background-color: #e0e7ff; border-left: 4px solid #6366f1; padding: 20px; margin: 30px 0; text-align: left; border-radius: 8px;">
        <p style="color: #3730a3; font-size: 14px; margin: 0; line-height: 1.6;">
          <strong>⏱️ Review Timeline:</strong> Most applications are reviewed within 24-48 hours.<br><br>
          <strong>📧 Notification:</strong> You'll receive an email once your application is approved or if we need additional information.
        </p>
      </div>

      <p style="color: #5A5A5A; font-size: 14px; line-height: 1.6; margin-top: 30px;">
        Thank you for your patience. We're excited about the possibility of having you join the CogniCare community!
      </p>

      <div style="margin-top: 40px; padding-top: 30px; border-top: 1px solid #e0e0e0;">
        <p style="color: #888; font-size: 13px; line-height: 1.6;">
          Questions about your application? Contact us at 
          <a href="mailto:support@cognicare.com" style="color: #f59e0b; text-decoration: none;">support@cognicare.com</a>
        </p>
      </div>
    </div>
  `;
};

export const getVolunteerApprovedTemplate = (userName: string): string => {
  return `
    <div style="text-align: center;">
      <div style="background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%); padding: 30px; border-radius: 12px; margin-bottom: 30px;">
        <h1 style="color: white; font-size: 32px; margin: 0;">
          ✓ Volunteer Application Approved
        </h1>
      </div>
      <h2 style="color: #5A5A5A; font-size: 24px; margin-bottom: 20px;">
        Congratulations, ${userName}!
      </h2>
      <p style="color: #5A5A5A; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        Your volunteer application on CogniCare has been approved. You can now access volunteer features and help families in need.
      </p>
      <div style="background-color: #dcfce7; border-left: 4px solid #22c55e; padding: 20px; margin: 30px 0; text-align: left; border-radius: 8px;">
        <p style="color: #166534; font-size: 15px; margin: 0; line-height: 1.6;">
          <strong>Next steps:</strong> Open the app and go to your volunteer dashboard to view available missions and set your availability.
        </p>
      </div>
      <p style="color: #5A5A5A; font-size: 14px; line-height: 1.6; margin-top: 30px;">
        Thank you for joining the CogniCare volunteer community!
      </p>
      <div style="margin-top: 40px; padding-top: 30px; border-top: 1px solid #e0e0e0;">
        <p style="color: #888; font-size: 13px; line-height: 1.6;">
          Questions? Contact us at <a href="mailto:support@cognicare.com" style="color: #22c55e; text-decoration: none;">support@cognicare.com</a>
        </p>
      </div>
    </div>
  `;
};

export const getVolunteerDeniedTemplate = (
  userName: string,
  deniedReason?: string,
  courseUrl?: string,
): string => {
  return `
    <div style="text-align: center;">
      <div style="background: linear-gradient(135deg, #f87171 0%, #ef4444 100%); padding: 30px; border-radius: 12px; margin-bottom: 30px;">
        <h1 style="color: white; font-size: 32px; margin: 0;">
          Volunteer Application Update
        </h1>
      </div>
      <h2 style="color: #5A5A5A; font-size: 24px; margin-bottom: 20px;">
        Dear ${userName},
      </h2>
      <p style="color: #5A5A5A; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        Thank you for your interest in volunteering with CogniCare. After review, we are unable to approve your application at this time.
      </p>
      ${
        deniedReason
          ? `
      <div style="background-color: #fee2e2; border-left: 4px solid #ef4444; padding: 20px; margin: 30px 0; text-align: left; border-radius: 8px;">
        <p style="color: #991b1b; font-size: 15px; margin: 0; line-height: 1.6;">${deniedReason}</p>
      </div>
      `
          : ''
      }
      ${
        courseUrl
          ? `
      <div style="background-color: #e0e7ff; border-left: 4px solid #6366f1; padding: 20px; margin: 30px 0; text-align: left; border-radius: 8px;">
        <p style="color: #3730a3; font-size: 15px; margin: 0; line-height: 1.6;">
          <strong>Qualify for future opportunities:</strong> You can take our qualification course to become eligible for volunteer missions.
        </p>
        <p style="margin: 15px 0 0 0;">
          <a href="${courseUrl}" style="display: inline-block; background-color: #6366f1; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: bold;">View qualification courses →</a>
        </p>
      </div>
      `
          : ''
      }
      <p style="color: #5A5A5A; font-size: 14px; line-height: 1.6; margin-top: 30px;">
        If you have questions, contact us at <a href="mailto:support@cognicare.com" style="color: #ef4444; text-decoration: none;">support@cognicare.com</a>
      </p>
    </div>
  `;
};

/**
 * Email envoyé à l'utilisateur après une commande : confirmation que la commande sera bientôt traitée.
 */
export const getOrderConfirmationTemplate = (params: {
  orderId: string;
  productName: string;
  quantity: number;
}): string => {
  return `
    <div style="text-align: center;">
      <h2 style="color: #5A5A5A; font-size: 24px; margin-bottom: 20px;">
        Commande enregistrée
      </h2>
      <p style="color: #5A5A5A; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        Merci pour votre commande ! Nous avons bien reçu votre demande.
      </p>
      
      <div style="background-color: #f9f9f9; border: 2px dashed #A4D7E1; border-radius: 12px; padding: 24px; margin: 30px 0; text-align: left;">
        <p style="color: #5A5A5A; font-size: 14px; margin-bottom: 8px;">
          <strong>Référence :</strong> #${params.orderId}
        </p>
        <p style="color: #5A5A5A; font-size: 14px; margin-bottom: 8px;">
          <strong>Produit :</strong> ${params.productName}
        </p>
        <p style="color: #5A5A5A; font-size: 14px; margin: 0;">
          <strong>Quantité :</strong> ${params.quantity}
        </p>
      </div>

      <div style="background-color: #E8F7F9; border-left: 4px solid #A4D7E1; padding: 15px; margin: 30px 0; text-align: left;">
        <p style="color: #5A5A5A; font-size: 15px; margin: 0;">
          <strong>Votre commande sera bientôt traitée.</strong><br/>
          Notre équipe vous recontactera pour confirmer la livraison et le paiement.
        </p>
      </div>

      <p style="color: #5A5A5A; font-size: 14px; line-height: 1.6; margin-top: 30px;">
        Une question ? Contactez-nous à <a href="mailto:support@cognicare.com" style="color: #A4D7E1; text-decoration: none;">support@cognicare.com</a>
      </p>
    </div>
  `;
};

/**
 * Email envoyé au client après une commande BioHerbs : indique que la confirmation viendra de BioHerbs.
 * On n'envoie pas l'email CogniCare "Commande enregistrée" pour BioHerbs, afin que le client reçoive
 * l'email de confirmation réel de BioHerbs.
 */
export const getBioherbsOrderConfirmationTemplate = (params: {
  orderId: string;
  productName: string;
  quantity: number;
  sentToBioherbs: boolean;
}): string => {
  const mainMessage = params.sentToBioherbs
    ? 'Votre commande a été transmise à BioHerbs Tunisie. <strong>Vous recevrez sous peu un email de confirmation directement de BioHerbs</strong> à cette adresse (vérifiez vos courriers indésirables si besoin).'
    : 'Votre commande est enregistrée. Nous la transmettons à BioHerbs ; vous recevrez un email de confirmation de BioHerbs dès que possible.';
  return `
    <div style="text-align: center;">
      <h2 style="color: #5A5A5A; font-size: 24px; margin-bottom: 20px;">
        Commande transmise à BioHerbs
      </h2>
      <p style="color: #5A5A5A; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
        ${mainMessage}
      </p>
      <div style="background-color: #f9f9f9; border: 2px dashed #A4D7E1; border-radius: 12px; padding: 24px; margin: 30px 0; text-align: left;">
        <p style="color: #5A5A5A; font-size: 14px; margin-bottom: 8px;"><strong>Référence :</strong> #${params.orderId}</p>
        <p style="color: #5A5A5A; font-size: 14px; margin-bottom: 8px;"><strong>Produit :</strong> ${params.productName}</p>
        <p style="color: #5A5A5A; font-size: 14px; margin: 0;"><strong>Quantité :</strong> ${params.quantity}</p>
      </div>
      <p style="color: #5A5A5A; font-size: 14px; line-height: 1.6;">
        L’email de confirmation officiel viendra de <strong>BioHerbs Tunisie</strong>, pas de CogniCare.
      </p>
    </div>
  `;
};
