import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MailService } from './mail.service';
import { MailMockService } from './mail-mock.service';

@Module({
  imports: [ConfigModule],
  providers: [
    {
      provide: MailService,
      useClass:
        process.env.NODE_ENV === 'development' ? MailMockService : MailService,
    },
  ],
  exports: [MailService],
})
export class MailModule {}
