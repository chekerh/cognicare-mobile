import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MailService } from './mail.service';
import { MailMockService } from './mail-mock.service';

@Module({
  imports: [ConfigModule],
  providers: [
    MailMockService,
    {
      provide: MailService,
      useFactory: (configService: ConfigService) => {
        const useMock = configService.get<boolean>('USE_MOCK_EMAIL');
        const hasApiKey = !!configService.get<string>('SENDGRID_API_KEY');

        if (useMock || (!hasApiKey && process.env.NODE_ENV !== 'production')) {
          console.log('📬 MailModule: Using MailMockService');
          return new MailMockService();
        }

        console.log('🚀 MailModule: Using real MailService');
        return new MailService(configService);
      },
      inject: [ConfigService],
    },
  ],
  exports: [MailService],
})
export class MailModule {}
