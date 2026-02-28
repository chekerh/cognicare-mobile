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
import { IntegrationsService } from './integrations.service';
import { IntegrationsController } from './integrations.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ExternalWebsite.name, schema: ExternalWebsiteSchema },
      { name: ExternalProduct.name, schema: ExternalProductSchema },
    ]),
  ],
  controllers: [IntegrationsController],
  providers: [IntegrationsService],
  exports: [IntegrationsService],
})
export class IntegrationsModule {}
