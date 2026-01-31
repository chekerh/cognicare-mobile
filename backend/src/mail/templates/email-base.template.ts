export const getEmailBaseTemplate = (content: string): string => {
  return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>CogniCare</title>
      <style>
        body {
          margin: 0;
          padding: 0;
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          background-color: #f6f6f6;
        }
        .email-container {
          max-width: 600px;
          margin: 0 auto;
          background-color: #ffffff;
        }
        .email-header {
          background: linear-gradient(135deg, #A4D7E1 0%, #8AC7D3 100%);
          padding: 40px 30px;
          text-align: center;
        }
        .logo {
          display: inline-flex;
          align-items: center;
          gap: 12px;
          margin-bottom: 10px;
        }
        .logo-icon {
          width: 50px;
          height: 50px;
          background-color: rgba(255, 255, 255, 0.2);
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 28px;
        }
        .logo-text {
          color: #ffffff;
          font-size: 28px;
          font-weight: bold;
          margin: 0;
        }
        .tagline {
          color: rgba(255, 255, 255, 0.9);
          font-size: 14px;
          margin: 0;
        }
        .email-body {
          padding: 40px 30px;
        }
        .email-footer {
          background-color: #5A5A5A;
          color: #ffffff;
          padding: 30px;
          text-align: center;
          font-size: 13px;
        }
        .footer-links {
          margin: 15px 0;
        }
        .footer-links a {
          color: #A4D7E1;
          text-decoration: none;
          margin: 0 10px;
        }
        .footer-links a:hover {
          text-decoration: underline;
        }
        .social-icons {
          margin: 20px 0 10px;
        }
        .social-icons a {
          display: inline-block;
          margin: 0 8px;
          color: #A4D7E1;
          text-decoration: none;
        }
        @media only screen and (max-width: 600px) {
          .email-body {
            padding: 30px 20px;
          }
          .email-header {
            padding: 30px 20px;
          }
        }
      </style>
    </head>
    <body>
      <div class="email-container">
        <!-- Header -->
        <div class="email-header">
          <div class="logo">
            <div class="logo-icon">🧠</div>
            <h1 class="logo-text">CogniCare</h1>
          </div>
          <p class="tagline">Your companion for better cognitive health</p>
        </div>

        <!-- Body Content -->
        <div class="email-body">
          ${content}
        </div>

        <!-- Footer -->
        <div class="email-footer">
          <div class="social-icons">
            <a href="#" title="Facebook">Facebook</a> •
            <a href="#" title="Twitter">Twitter</a> •
            <a href="#" title="LinkedIn">LinkedIn</a>
          </div>
          <div class="footer-links">
            <a href="#">Privacy Policy</a> •
            <a href="#">Terms of Service</a> •
            <a href="#">Help Center</a>
          </div>
          <p style="margin: 15px 0 5px; color: rgba(255, 255, 255, 0.7);">
            © ${new Date().getFullYear()} CogniCare. All rights reserved.
          </p>
          <p style="margin: 5px 0; font-size: 11px; color: rgba(255, 255, 255, 0.5);">
            This email was sent to you as part of your CogniCare account.
          </p>
        </div>
      </div>
    </body>
    </html>
  `;
};
