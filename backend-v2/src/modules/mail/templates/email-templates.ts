export const getVerificationCodeTemplate = (code: string): string => `
  <div style="text-align: center;">
    <h2 style="color: #5A5A5A; font-size: 24px; margin-bottom: 20px;">Email Verification</h2>
    <p style="color: #5A5A5A; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">Thank you for signing up with CogniCare! Use the verification code below:</p>
    <div style="background-color: #f9f9f9; border: 2px dashed #A4D7E1; border-radius: 12px; padding: 30px; margin: 30px 0;">
      <p style="color: #5A5A5A; font-size: 14px; margin-bottom: 10px; text-transform: uppercase; letter-spacing: 1px;">Your Verification Code</p>
      <h1 style="font-size: 48px; letter-spacing: 8px; color: #A4D7E1; margin: 10px 0; font-weight: bold;">${code}</h1>
    </div>
    <div style="background-color: #FFF9E6; border-left: 4px solid #F9D51C; padding: 15px; margin: 30px 0; text-align: left;">
      <p style="color: #5A5A5A; font-size: 14px; margin: 0;"><strong>⏰ Important:</strong> This code will expire in <strong>10 minutes</strong>.</p>
    </div>
  </div>
`;

export const getPasswordResetTemplate = (code: string): string => `
  <div style="text-align: center;">
    <h2 style="color: #5A5A5A; font-size: 24px;">Password Reset Request</h2>
    <div style="background-color: #f9f9f9; border: 2px dashed #A4D7E1; border-radius: 12px; padding: 30px; margin: 30px 0;">
      <p style="color: #5A5A5A; font-size: 14px; text-transform: uppercase; letter-spacing: 1px;">Password Reset Code</p>
      <h1 style="font-size: 48px; letter-spacing: 8px; color: #A4D7E1; margin: 10px 0;">${code}</h1>
    </div>
  </div>
`;

export const getWelcomeTemplate = (userName: string): string => `
  <div style="text-align: center;">
    <h2 style="color: #5A5A5A; font-size: 28px;">Welcome to CogniCare! 🎉</h2>
    <p style="color: #5A5A5A; font-size: 16px;">Hi <strong>${userName}</strong>, we're thrilled to have you!</p>
    <div style="background: linear-gradient(135deg, #A4D7E1 0%, #A7E9A4 100%); border-radius: 12px; padding: 30px; margin: 30px 0; color: white;">
      <h3 style="margin: 0 0 15px 0;">Your journey to better cognitive health starts now! 🧠✨</h3>
    </div>
  </div>
`;

export const getOrganizationInvitationTemplate = (orgName: string, invitationType: 'staff' | 'family', acceptUrl: string, rejectUrl: string): string => `
  <div style="text-align: center;">
    <h2 style="color: #5A5A5A;">You're Invited to Join ${orgName}!</h2>
    <p style="color: #5A5A5A;">${orgName} has invited you as a ${invitationType} member on CogniCare.</p>
    <div style="margin: 30px 0;">
      <a href="${acceptUrl}" style="display: inline-block; background-color: #A7E9A4; color: white; padding: 15px 40px; border-radius: 8px; font-weight: bold; margin: 10px;">✓ Accept</a>
      <a href="${rejectUrl}" style="display: inline-block; background-color: #FF7675; color: white; padding: 15px 40px; border-radius: 8px; font-weight: bold; margin: 10px;">✗ Decline</a>
    </div>
  </div>
`;

export const getOrganizationPendingTemplate = (orgName: string, leaderName: string): string => `
  <div style="text-align: center;">
    <h2 style="color: #5A5A5A;">Organization Application Submitted</h2>
    <p>Dear ${leaderName}, your organization <strong>${orgName}</strong> is under review.</p>
  </div>
`;

export const getOrganizationApprovedTemplate = (orgName: string, leaderName: string): string => `
  <div style="text-align: center;">
    <div style="background: linear-gradient(135deg, #4ade80, #22c55e); padding: 30px; border-radius: 12px; margin-bottom: 30px;">
      <h1 style="color: white;">🎉 Congratulations!</h1>
    </div>
    <p>Dear ${leaderName}, your organization <strong>${orgName}</strong> has been approved!</p>
  </div>
`;

export const getOrganizationRejectedTemplate = (orgName: string, leaderName: string, reason?: string): string => `
  <div style="text-align: center;">
    <h2 style="color: #5A5A5A;">Organization Application Status</h2>
    <p>Dear ${leaderName}, your organization <strong>${orgName}</strong> was not approved.</p>
    ${reason ? `<div style="background-color: #fee2e2; border-left: 4px solid #ef4444; padding: 20px; margin: 30px 0; text-align: left;"><p style="color: #991b1b;">${reason}</p></div>` : ''}
  </div>
`;

export const getVolunteerApprovedTemplate = (userName: string): string => `
  <div style="text-align: center;">
    <h2 style="color: #5A5A5A;">Congratulations, ${userName}!</h2>
    <p style="color: #5A5A5A;">Your volunteer application has been approved.</p>
  </div>
`;

export const getVolunteerDeniedTemplate = (userName: string, reason?: string, courseUrl?: string): string => `
  <div style="text-align: center;">
    <h2 style="color: #5A5A5A;">Dear ${userName},</h2>
    <p>We are unable to approve your application at this time.</p>
    ${reason ? `<div style="background-color: #fee2e2; border-left: 4px solid #ef4444; padding: 20px; margin: 30px 0;"><p style="color: #991b1b;">${reason}</p></div>` : ''}
    ${courseUrl ? `<p><a href="${courseUrl}" style="background-color: #6366f1; color: white; padding: 12px 24px; border-radius: 8px;">View qualification courses →</a></p>` : ''}
  </div>
`;

export const getOrderConfirmationTemplate = (params: { orderId: string; productName: string; quantity: number }): string => `
  <div style="text-align: center;">
    <h2 style="color: #5A5A5A;">Commande enregistrée</h2>
    <div style="background-color: #f9f9f9; border: 2px dashed #A4D7E1; border-radius: 12px; padding: 24px; margin: 30px 0; text-align: left;">
      <p><strong>Référence :</strong> #${params.orderId}</p>
      <p><strong>Produit :</strong> ${params.productName}</p>
      <p><strong>Quantité :</strong> ${params.quantity}</p>
    </div>
  </div>
`;

export const getBioherbsOrderConfirmationTemplate = (params: { orderId: string; productName: string; quantity: number; sentToBioherbs: boolean }): string => {
  const msg = params.sentToBioherbs
    ? 'Votre commande a été transmise à BioHerbs Tunisie.'
    : 'Votre commande est enregistrée. Nous la transmettons à BioHerbs.';
  return `
    <div style="text-align: center;">
      <h2 style="color: #5A5A5A;">Commande transmise à BioHerbs</h2>
      <p style="color: #5A5A5A;">${msg}</p>
      <div style="background-color: #f9f9f9; border: 2px dashed #A4D7E1; border-radius: 12px; padding: 24px; margin: 30px 0; text-align: left;">
        <p><strong>Référence :</strong> #${params.orderId}</p>
        <p><strong>Produit :</strong> ${params.productName}</p>
        <p><strong>Quantité :</strong> ${params.quantity}</p>
      </div>
    </div>
  `;
};
