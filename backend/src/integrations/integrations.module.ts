import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import {
  ExternalWebsite,
  ExternalWebsiteSchema,
} from './schemas/external-website.schema';
import {
  ExternalProduct,
  ExternalProductSchema,
} from './schemas/external-product.schema';
import {
  IntegrationOrder,
  IntegrationOrderSchema,
} from './schemas/integration-order.schema';
import { IntegrationsService } from './integrations.service';
import { IntegrationsController } from './integrations.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ExternalWebsite.name, schema: ExternalWebsiteSchema },
      { name: ExternalProduct.name, schema: ExternalProductSchema },
      { name: IntegrationOrder.name, schema: IntegrationOrderSchema },
    ]),
  ],
  controllers: [IntegrationsController],
  providers: [IntegrationsService],
  exports: [IntegrationsService],
})
export class IntegrationsModule {}
