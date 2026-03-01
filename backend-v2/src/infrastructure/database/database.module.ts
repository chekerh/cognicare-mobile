/**
 * Database Module - Infrastructure Layer
 */
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule, ConfigService } from '@nestjs/config';

@Module({
  imports: [
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        uri: configService.get<string>('MONGODB_URI') || 'mongodb://localhost:27017/cognicare',
        retryWrites: true,
        w: 'majority',
      }),
    }),
  ],
  exports: [MongooseModule],
})
export class DatabaseModule {}
