import { Module } from '@nestjs/common';
import { PaypalService } from './paypal.service';
import { PaypalController } from './interface/http/paypal.controller';

@Module({
  controllers: [PaypalController],
  providers: [PaypalService],
  exports: [PaypalService],
})
export class PaypalModule {}
