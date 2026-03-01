/**
 * Organization Module
 */
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ORGANIZATION_REPOSITORY_TOKEN } from './domain/repositories/organization.repository.interface';
import { OrganizationMongoSchema, OrganizationSchema } from './infrastructure/persistence/mongo/organization.schema';
import { OrganizationMongoRepository } from './infrastructure/persistence/mongo/organization.mongo-repository';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: OrganizationMongoSchema.name, schema: OrganizationSchema },
    ]),
  ],
  providers: [
    {
      provide: ORGANIZATION_REPOSITORY_TOKEN,
      useClass: OrganizationMongoRepository,
    },
  ],
  exports: [
    ORGANIZATION_REPOSITORY_TOKEN,
    MongooseModule,
  ],
})
export class OrganizationModule {}
