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

