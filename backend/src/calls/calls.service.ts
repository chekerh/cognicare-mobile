import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RtcTokenBuilder, RtcRole } from 'agora-token';

@Injectable()
export class CallsService {
  private readonly appId: string;
  private readonly appCertificate: string;

  constructor(private config: ConfigService) {
    this.appId = (this.config.get<string>('AGORA_APP_ID') ?? '').trim();
    this.appCertificate = (
      this.config.get<string>('AGORA_APP_CERTIFICATE') ?? ''
    ).trim();
  }

  getAppId(): string {
    return this.appId;
  }

  isConfigured(): boolean {
    return !!this.appId && !!this.appCertificate;
  }

  async generateToken(
    channelName: string,
    uid: string,
    _requestingUserId: string,
  ): Promise<string> {
    if (!this.isConfigured()) {
      throw new Error(
        'Agora is not configured. Set AGORA_APP_ID and AGORA_APP_CERTIFICATE.',
      );
    }
    const tokenExpire = 3600; // 1 hour
    const privilegeExpire = 0;
    return RtcTokenBuilder.buildTokenWithUserAccount(
      this.appId,
      this.appCertificate,
      channelName,
      uid,
      RtcRole.PUBLISHER,
      tokenExpire,
      privilegeExpire,
    );
  }
}
