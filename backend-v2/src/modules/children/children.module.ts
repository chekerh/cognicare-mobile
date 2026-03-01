/**
 * Children Module - Module Definition
 * 
 * This module wires together all the layers:
 * - Domain: Entities, Repository interfaces
 * - Application: Use cases, DTOs
 * - Infrastructure: Mongoose schemas, Repository implementations
 * - Interface: Controllers
 * 
 * Dependency injection binds interfaces to implementations.
 */
import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

// Domain
import { CHILD_REPOSITORY_TOKEN } from './domain/repositories/child.repository.interface';

// Application - Use Cases
import { CreateChildForFamilyUseCase } from './application/use-cases/create-child-for-family.use-case';
import { CreateChildForSpecialistUseCase } from './application/use-cases/create-child-for-specialist.use-case';
import { GetChildrenByFamilyUseCase } from './application/use-cases/get-children-by-family.use-case';
import { GetChildrenBySpecialistUseCase } from './application/use-cases/get-children-by-specialist.use-case';
import { UpdateChildUseCase } from './application/use-cases/update-child.use-case';

// Infrastructure
import { ChildMongoSchema, ChildSchema } from './infrastructure/persistence/mongo/child.schema';
import { ChildMongoRepository } from './infrastructure/persistence/mongo/child.mongo-repository';

// Interface
import { ChildrenController } from './interface/http/children.controller';

// Cross-module dependencies
import { UsersModule } from '../users/users.module';
import { OrganizationModule } from '../organization/organization.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ChildMongoSchema.name, schema: ChildSchema },
    ]),
    forwardRef(() => UsersModule),
    forwardRef(() => OrganizationModule),
  ],
  controllers: [ChildrenController],
  providers: [
    // Repository implementation bound to interface
    {
      provide: CHILD_REPOSITORY_TOKEN,
      useClass: ChildMongoRepository,
    },
    // Use cases
    CreateChildForFamilyUseCase,
    CreateChildForSpecialistUseCase,
    GetChildrenByFamilyUseCase,
    GetChildrenBySpecialistUseCase,
    UpdateChildUseCase,
  ],
  exports: [
    // Export repository for other modules to use
    CHILD_REPOSITORY_TOKEN,
  ],
})
export class ChildrenModule {}
