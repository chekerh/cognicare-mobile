import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Reel, ReelSchema } from './reel.schema';
import { ReelsService } from './reels.service';
import { ReelsController } from './reels.controller';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Reel.name, schema: ReelSchema }]),
  ],
  controllers: [ReelsController],
  providers: [ReelsService],
  exports: [ReelsService],
})
export class ReelsModule {}
