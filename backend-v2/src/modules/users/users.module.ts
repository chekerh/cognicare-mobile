/**
 * Users Module
 */
import { Module, forwardRef } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { USER_REPOSITORY_TOKEN } from './domain/repositories/user.repository.interface';
import { UserMongoSchema, UserSchema } from './infrastructure/persistence/mongo/user.schema';
import { UserMongoRepository } from './infrastructure/persistence/mongo/user.mongo-repository';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: UserMongoSchema.name, schema: UserSchema },
    ]),
  ],
  providers: [
    {
      provide: USER_REPOSITORY_TOKEN,
      useClass: UserMongoRepository,
    },
  ],
  exports: [
    USER_REPOSITORY_TOKEN,
    MongooseModule,
  ],
})
export class UsersModule {}
